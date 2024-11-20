class PodcastShareLink {
  final String feedURL;
  final String? episodeID;

  PodcastShareLink(this.feedURL, {this.episodeID});

  String toLinkQuery() {
    return 'feedURL=${Uri.encodeQueryComponent(feedURL)}${episodeID != null ? '&episodeID=${Uri.encodeQueryComponent(episodeID!)}' : ''}';
  }

  static PodcastShareLink fromLinkQuery(String queryStr) {
    final Map<String, String> query = Uri.splitQueryString(queryStr);
    return PodcastShareLink(
      Uri.decodeComponent(query['feedURL']!),
      episodeID: query['episodeID'] == null ? null : Uri.decodeComponent(query['episodeID']!),
    );
  }
}
