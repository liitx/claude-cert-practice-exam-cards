/// Per-user, per-card study marker. Persists in localStorage / SharedPreferences
/// under `progress[deckId][cardId]`.
enum ProgressState {
  review('review'),
  got('got');

  const ProgressState(this.id);
  final String id;

  static ProgressState? tryParse(Object? raw) {
    if (raw is String) {
      for (final v in values) {
        if (v.id == raw) return v;
      }
    }
    return null;
  }
}
