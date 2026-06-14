import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/features/study/widgets/card_basic.dart';
import 'package:drill_deck/features/study/widgets/card_fib.dart';
import 'package:drill_deck/features/study/widgets/card_mc.dart';
import 'package:drill_deck/features/study/widgets/card_ms.dart';
import 'package:drill_deck/features/study/widgets/card_tf.dart';
import 'package:drill_deck/features/study/widgets/deck_footer.dart';
import 'package:drill_deck/features/study/widgets/deck_selector.dart';
import 'package:drill_deck/features/study/widgets/filter_chips.dart';
import 'package:drill_deck/features/study/widgets/flip_card.dart';
import 'package:drill_deck/features/study/widgets/study_controls.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/models/study_filter.dart';
import 'package:drill_deck/repositories/decks_repository.dart';
import 'package:drill_deck/repositories/progress_repository.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudyPage extends StatelessWidget {
  const StudyPage({this.deckId, super.key});
  final String? deckId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudyBloc(
        decksRepository: context.read<DecksRepository>(),
        progressRepository: context.read<ProgressRepository>(),
        storageRepository: context.read<StorageRepository>(),
        initialDeckId: deckId,
      )..add(const StudyStarted()),
      child: _StudyShell(deckId: deckId),
    );
  }
}

class _StudyShell extends StatefulWidget {
  const _StudyShell({this.deckId});
  final String? deckId;

  @override
  State<_StudyShell> createState() => _StudyShellState();
}

class _StudyShellState extends State<_StudyShell> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'study');
  }

  @override
  void didUpdateWidget(covariant _StudyShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deckId != widget.deckId && widget.deckId != null) {
      context.read<StudyBloc>().add(StudyDeckRequested(widget.deckId!));
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final bloc = context.read<StudyBloc>();
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      bloc.add(const StudyFlipped());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      bloc.add(const StudyNext());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      bloc.add(const StudyPrev());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      bloc.add(const StudyMarkReview());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      bloc.add(const StudyMarkGot());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: BlocBuilder<StudyBloc, StudyState>(
                  builder: (context, state) {
                    return switch (state.status) {
                      StudyStatus.initial ||
                      StudyStatus.loading =>
                        const _Loading(),
                      StudyStatus.failure => _Failure(
                          message: state.errorMessage ?? 'Unknown error',
                        ),
                      StudyStatus.empty => const _Empty(),
                      StudyStatus.ready => _Ready(state: state),
                    };
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ScenarioPalette>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load the library: $message',
          style: TextStyle(color: palette.danger),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return Center(
      child: Text(
        'No cards in this deck yet.',
        style: mono.hint,
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state});
  final StudyState state;

  @override
  Widget build(BuildContext context) {
    final deck = state.deck!;
    final mono = Theme.of(context).extension<MonoTypography>()!;
    final card = state.currentCard!;
    final scenario = _scenarioFor(deck, card);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressRail(progress: (state.idx + 1) / state.cards.length),
        const SizedBox(height: 14),
        _Header(deck: deck, idx: state.idx, total: state.cards.length),
        if (state.allDecks.length > 1) ...[
          const SizedBox(height: 12),
          const DeckSelector(),
        ],
        const SizedBox(height: 14),
        const FilterChips(),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 320,
                maxHeight: 480,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    context.read<StudyBloc>().add(const StudyFlipped()),
                child: FlipCard(
                  flipped: state.flipped,
                  front: _faceFront(context, card, scenario),
                  back: _faceBack(context, card, scenario),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const StudyControls(),
        const SizedBox(height: 14),
        Text(
          'space flip · ← → move · 1 review · 2 got it',
          textAlign: TextAlign.center,
          style: mono.hint,
        ),
        const SizedBox(height: 14),
        DeckFooter(deck: deck),
      ],
    );
  }

  Widget _faceFront(BuildContext context, Card card, Scenario scenario) {
    final answer = state.userAnswers[card.id];
    final bloc = context.read<StudyBloc>();
    return switch (card) {
      BasicCard() => BasicCardFront(card: card, scenario: scenario),
      MultipleChoiceCard() => MultipleChoiceCardFront(
          card: card,
          scenario: scenario,
          picked: answer is int ? answer : null,
          onPick: (i) => bloc.add(StudyAnswerPicked(i)),
        ),
      MultiSelectCard() => MultiSelectCardFront(
          card: card,
          scenario: scenario,
          picked: answer is List
              ? List<int>.from(answer.whereType<int>())
              : const <int>[],
          onToggle: (i) => bloc.add(StudyMultiSelectToggled(i)),
        ),
      TrueFalseCard() => TrueFalseCardFront(
          card: card,
          scenario: scenario,
          picked: answer is bool ? answer : null,
          onPick: (v) => bloc.add(StudyAnswerPicked(v)),
        ),
      FillInBlankCard() => FillInBlankCardFront(
          card: card,
          scenario: scenario,
          picked: answer is String ? answer : null,
          onChanged: (s) => bloc.add(StudyAnswerPicked(s)),
        ),
    };
  }

  Widget _faceBack(BuildContext context, Card card, Scenario scenario) {
    final answer = state.userAnswers[card.id];
    return switch (card) {
      BasicCard() => BasicCardBack(card: card, scenario: scenario),
      MultipleChoiceCard() => MultipleChoiceCardBack(
          card: card,
          scenario: scenario,
          picked: answer is int ? answer : null,
        ),
      MultiSelectCard() => MultiSelectCardBack(
          card: card,
          scenario: scenario,
          picked: answer is List
              ? List<int>.from(answer.whereType<int>())
              : const <int>[],
        ),
      TrueFalseCard() => TrueFalseCardBack(
          card: card,
          scenario: scenario,
          picked: answer is bool ? answer : null,
        ),
      FillInBlankCard() => FillInBlankCardBack(
          card: card,
          scenario: scenario,
          picked: answer is String ? answer : null,
        ),
    };
  }

  Scenario _scenarioFor(Deck deck, Card card) {
    final found = deck.scenarios[card.scn];
    if (found != null) return found;
    return Scenario(label: card.scn, color: '#7c83ff');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.deck, required this.idx, required this.total});
  final Deck deck;
  final int idx;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.extension<MonoTypography>()!;
    final palette = theme.extension<ScenarioPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: palette.got,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            'FLUTTER WEB · phase 2',
            style: mono.chip.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                deck.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text('${idx + 1} / $total', style: mono.counter),
          ],
        ),
      ],
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ScenarioPalette>()!;
    return SizedBox(
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.line)),
            FractionallySizedBox(
              widthFactor: progress.clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.action, palette.got],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

