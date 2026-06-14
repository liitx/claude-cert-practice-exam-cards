enum StudyFilter {
  miss('miss'),
  all('all'),
  review('review'),
  got('got');

  const StudyFilter(this.id);
  final String id;

  static StudyFilter tryParse(Object? raw, {StudyFilter fallback = StudyFilter.miss}) {
    if (raw is String) {
      for (final f in values) {
        if (f.id == raw) return f;
      }
    }
    return fallback;
  }
}
