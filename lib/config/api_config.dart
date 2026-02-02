/// Central configuration for API endpoints
/// Change the baseUrl here to switch between local, production, or network testing
class ApiConfig {
  // Uncomment the one you want to use:
  
  // For iPhone/network testing via hotspot (iPhone IP: 172.20.10.13, PC gateway IP)
  // Use the PC's IP on the hotspot network - check with: ipconfig | findstr "172.20"
  //static const String baseUrl = "http://172.20.10.13:8000/";
  
  // For PC-only local testing
  // static const String baseUrl = "http://127.0.0.1:8000/";
  
  // For production on Fly.io
  static const String baseUrl = "https://spellbackend.fly.dev/";
  
  // For production on Render
  // static const String baseUrl = "https://spellbackend.onrender.com/";
}
