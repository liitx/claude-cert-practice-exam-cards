/// Ordering applied to the filtered card list. Sorting runs *after* filtering,
/// so shuffle randomizes only the cards currently in view.
enum StudySort {
  /// Deck's natural order.
  original('original'),

  /// Random permutation (re-rolled each shuffle).
  shuffle('shuffle'),

  /// Cards marked "review" floated to the top, original order otherwise.
  reviewFirst('reviewFirst'),

  /// Cards marked "got it" floated to the top, original order otherwise.
  gotFirst('gotFirst');

  const StudySort(this.id);
  final String id;
}
