import 'package:drill_deck/features/study/view/study_page.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const StudyPage(),
      ),
      GoRoute(
        path: '/deck/:deckId',
        builder: (context, state) =>
            StudyPage(deckId: state.pathParameters['deckId']),
      ),
    ],
  );
}
