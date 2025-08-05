import 'dart:js_util' as js_util;

Future<void> playWordWeb(String word) async {
  final synth = js_util.getProperty(js_util.globalThis, 'speechSynthesis');
  js_util.callMethod(synth, 'cancel', []);
  final voices = js_util.callMethod(synth, 'getVoices', []);
  final voicesList = List.from(voices);
  final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(word);
  var selectedVoice;
  if (isChinese) {
    selectedVoice = voicesList.firstWhere(
      (v) => js_util.getProperty(v, 'lang').toString().startsWith('zh'),
      orElse: () => voicesList.isNotEmpty ? voicesList[0] : null,
    );
  } else {
    selectedVoice = voicesList.firstWhere(
      (v) => js_util.getProperty(v, 'lang').toString().startsWith('en'),
      orElse: () => voicesList.isNotEmpty ? voicesList[0] : null,
    );
  }
  final utter = js_util.callConstructor(
    js_util.getProperty(js_util.globalThis, 'SpeechSynthesisUtterance'),
    [word],
  );
  if (selectedVoice != null) {
    js_util.setProperty(utter, 'voice', selectedVoice);
    js_util.setProperty(utter, 'lang', js_util.getProperty(selectedVoice, 'lang'));
  }
  js_util.callMethod(synth, 'speak', [utter]);
}
