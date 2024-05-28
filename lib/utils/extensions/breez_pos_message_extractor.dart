String? extractPosMessage(String message) {
  message = message.replaceAll("\n", "").trim();
  if (message.isNotEmpty) {
    final breezPosRegex = RegExp(r'(?<=\|)(.*)(?=\|)');
    if (breezPosRegex.hasMatch(message)) {
      final extracted = breezPosRegex.stringMatch(message)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        return extracted;
      }
    }
  }
  return null;
}
