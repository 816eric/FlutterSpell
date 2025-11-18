# AI Service Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                            │
│                                                                  │
│  ┌────────────────────┐           ┌──────────────────────┐      │
│  │  Settings Page     │           │   My Words Page      │      │
│  │                    │           │                      │      │
│  │  ┌──────────────┐  │           │  ┌────────────────┐  │      │
│  │  │ AI Config    │  │           │  │ Pick Image     │  │      │
│  │  │ - Provider   │  │           │  │ Extract Words  │  │      │
│  │  │ - Model      │  │           │  │ Display Result │  │      │
│  │  │ - API Key    │  │           │  └────────┬───────┘  │      │
│  │  └──────┬───────┘  │           │           │          │      │
│  └─────────┼──────────┘           └───────────┼──────────┘      │
└────────────┼────────────────────────────────────┼────────────────┘
             │                                    │
             │ Configure                          │ Use
             ▼                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                         AI SERVICE                               │
│                     (Singleton Instance)                         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Configuration Manager                       │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │   │
│  │  │ Provider   │  │   Model    │  │  API Key   │         │   │
│  │  │  Storage   │  │  Storage   │  │  Storage   │         │   │
│  │  └────────────┘  └────────────┘  └────────────┘         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Image Processing Pipeline                   │   │
│  │                                                          │   │
│  │   Input → Check Size → Compress → Encode → API Call     │   │
│  │   (XFile/File)  (>512KB?)  (Resize)  (Base64)           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Provider Implementations                    │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │   │
│  │  │ Gemini   │ │ OpenAI   │ │DeepSeek  │ │ Qianwen  │    │   │
│  │  │ Handler  │ │ Handler  │ │ Handler  │ │ Handler  │    │   │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘    │   │
│  └───────┼────────────┼────────────┼─────────────┼──────────┘   │
└──────────┼────────────┼────────────┼─────────────┼──────────────┘
           │            │            │             │
           │ API Call   │ API Call   │ API Call    │ API Call
           ▼            ▼            ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL AI PROVIDERS                         │
│                                                                  │
│  ┌───────────────┐  ┌───────────────┐  ┌────────────────┐      │
│  │ Google Gemini │  │    OpenAI     │  │   DeepSeek     │      │
│  │ ai.google.dev │  │platform.openai│  │platform.deepseek│     │
│  └───────────────┘  └───────────────┘  └────────────────┘      │
│                                                                  │
│  ┌───────────────┐                                              │
│  │    Qianwen    │                                              │
│  │ Alibaba Cloud │                                              │
│  └───────────────┘                                              │
└─────────────────────────────────────────────────────────────────┘
           │            │            │             │
           │ Response   │ Response   │ Response    │ Response
           ▼            ▼            ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RESPONSE PROCESSING                           │
│                                                                  │
│  Parse JSON → Extract Words → Validate → Return List<String>    │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
User Action: Upload Image
        │
        ▼
┌────────────────┐
│ Pick Image     │ (ImagePicker)
└───────┬────────┘
        │
        ▼
┌────────────────────────────────┐
│ AIService.extractWordsFromImage│
└───────┬────────────────────────┘
        │
        ├─► Load Config (Provider, Model, API Key)
        │
        ├─► Check Image Size
        │   │
        │   ├─► If > 512KB → Compress
        │   │   └─► Resize → Encode JPEG
        │   │
        │   └─► Encode Base64
        │
        ├─► Select Provider Handler
        │   │
        │   ├─► Gemini  → Format Gemini Request
        │   ├─► OpenAI  → Format OpenAI Request
        │   ├─► DeepSeek→ Format DeepSeek Request
        │   └─► Qianwen → Format Qianwen Request
        │
        ├─► Send HTTP POST
        │   │
        │   └─► Include: Model, Image, Prompt, API Key
        │
        ├─► Receive Response
        │   │
        │   ├─► Parse JSON
        │   ├─► Extract Text
        │   ├─► Find JSON Array
        │   └─► Parse Word List
        │
        └─► Return List<String>
                │
                └─► Display in UI
```

## Settings Flow

```
User Opens Settings
        │
        ▼
┌─────────────────────┐
│ Load AI Settings    │ ← AIService.getAiProvider/Model/ApiKey
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Display UI          │
│ - Provider Dropdown │
│ - Model Dropdown    │
│ - API Key Input     │
└──────┬──────────────┘
       │
       │ User Changes Setting
       ▼
┌─────────────────────┐
│ Update State        │ ← setState()
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Save to Storage     │ ← AIService.setAiProvider/Model/ApiKey
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ SharedPreferences   │ ← Persistent Storage
└─────────────────────┘
```

## Provider Selection Logic

```
                    ┌────────────────┐
                    │ User Selects   │
                    │ AI Provider    │
                    └───────┬────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ▼               ▼               ▼
      ┌─────────┐     ┌─────────┐    ┌──────────┐
      │ Gemini  │     │ OpenAI  │    │ DeepSeek │
      └────┬────┘     └────┬────┘    └─────┬────┘
           │               │               │
           │ Default       │ Default       │ Default
           │ Model         │ Model         │ Model
           ▼               ▼               ▼
    gemini-2.0-      gpt-4o-mini    deepseek-chat
    flash-exp
           │               │               │
           ▼               ▼               ▼
    ┌──────────────────────────────────────────┐
    │    Update Model Dropdown Options         │
    └──────────────┬───────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────┐
    │  Save to SharedPreferences   │
    └──────────────────────────────┘
```

## Image Compression Algorithm

```
┌────────────────┐
│ Input Image    │
└───────┬────────┘
        │
        ▼
   ┌─────────┐
   │Size > 512KB?│
   └────┬────┘
        │
        ├─── No ──→ Return Original
        │
        └─── Yes ──┐
                   ▼
        ┌──────────────────┐
        │ Calculate Ratio  │
        │ ratio = 512/size │
        └─────────┬────────┘
                  │
                  ▼
        ┌──────────────────┐
        │ Scale Dimensions │
        │ w' = w × √ratio  │
        │ h' = h × √ratio  │
        └─────────┬────────┘
                  │
                  ▼
        ┌──────────────────┐
        │ Resize Image     │
        └─────────┬────────┘
                  │
                  ▼
        ┌──────────────────┐
        │ Encode JPEG      │
        │ Quality = 85     │
        └─────────┬────────┘
                  │
                  ▼
           ┌──────────┐
           │Size > 512KB?│
           └─────┬────┘
                 │
                 ├─── No ──→ Return Compressed
                 │
                 └─── Yes ──┐
                            │
                            ▼
                  ┌──────────────────┐
                  │ Reduce Quality   │
                  │ quality -= 10    │
                  └─────────┬────────┘
                            │
                            └──→ Retry (min quality 30)
```

## Error Handling Flow

```
┌────────────────────┐
│ API Call           │
└─────────┬──────────┘
          │
          ├─── Success ──→ Parse Response ──→ Return Words
          │
          └─── Error ────┐
                         ▼
                  ┌──────────────┐
                  │ Error Type?  │
                  └──────┬───────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
    ┌─────────┐   ┌──────────┐   ┌──────────┐
    │Network  │   │Parse     │   │API Key   │
    │Error    │   │Error     │   │Missing   │
    └────┬────┘   └─────┬────┘   └─────┬────┘
         │              │              │
         ▼              ▼              ▼
    Show Error    Show Error    Show Settings
    Message       Message       Dialog
```

## Component Relationships

```
┌─────────────────────────────────────────┐
│          Settings Page                  │
│                                         │
│  Uses: AIService (configuration)        │
│  Updates: Provider, Model, API Key      │
│  Displays: Configuration UI             │
└─────────────────┬───────────────────────┘
                  │
                  │ Configures
                  ▼
┌─────────────────────────────────────────┐
│          AI Service                     │
│                                         │
│  Manages: Settings, Providers           │
│  Handles: Image Processing, API Calls   │
│  Returns: List<String> (words)          │
└─────────────────┬───────────────────────┘
                  │
                  │ Used by
                  ▼
┌─────────────────────────────────────────┐
│          My Words Page                  │
│                                         │
│  Uses: AIService (extraction)           │
│  Provides: Image input                  │
│  Displays: Extracted words              │
└─────────────────────────────────────────┘
```

## Storage Architecture

```
SharedPreferences
├── ai_provider: String
│   ├── "gemini" (default)
│   ├── "openai"
│   ├── "deepseek"
│   └── "qianwen"
│
├── ai_model: String
│   ├── "gemini-2.0-flash-exp"
│   ├── "gpt-4o-mini"
│   ├── "deepseek-chat"
│   └── "qwen-turbo"
│
└── ai_api_key: String
    └── User's API key (stored as plain text)

Note: Consider encryption for production
```
