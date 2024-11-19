class SessionLink {
  final String sessionID;
  final String sessionSecret;
  final String initiatorPubKey;

  SessionLink(this.sessionID, this.sessionSecret, this.initiatorPubKey);

  String toLinkQuery() {
    return 'sessionID=$sessionID&sessionSecret=$sessionSecret&pubKey=$initiatorPubKey';
  }

  static SessionLink fromLinkQuery(String queryStr) {
    final Map<String, String> query = Uri.splitQueryString(queryStr);
    return SessionLink(query['sessionID']!, query['sessionSecret']!, query['pubKey']!);
  }
}
