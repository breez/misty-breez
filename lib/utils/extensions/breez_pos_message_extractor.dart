String? extractPosMessage(String message) {
  message = message.replaceAll('\n', '').trim();
  if (message.isNotEmpty) {
    final RegExp breezPosRegex = RegExp(r'(?<=\|)(.*)(?=\|)');
    if (breezPosRegex.hasMatch(message)) {
      final String? extracted = breezPosRegex.stringMatch(message)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        return extracted;
      }
    }
  }
  return null;
}
