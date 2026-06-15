import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit a card of any of the five types. A null [card] means "add new".
/// Saving dispatches [CardUpserted] (which forks a shared deck if needed).
class CardEditorSheet extends StatefulWidget {
  const CardEditorSheet({required this.deckId, this.card, super.key});

  final String deckId;
  final Card? card;

  static Future<void> show(
    BuildContext context, {
    required String deckId,
    Card? card,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CardEditorSheet(deckId: deckId, card: card),
      ),
    );
  }

  @override
  State<CardEditorSheet> createState() => _CardEditorSheetState();
}

class _CardEditorSheetState extends State<CardEditorSheet> {
  late CardType _type;
  late final TextEditingController _scn;
  late final TextEditingController _topic;
  late final TextEditingController _q;
  late final TextEditingController _why;
  late final TextEditingController _answer; // basic
  late final TextEditingController _explanation; // mc/ms/tf/fib
  List<TextEditingController> _choices = [];
  List<TextEditingController> _accepted = [];
  int? _mcCorrect;
  Set<int> _msCorrect = {};
  bool _tfCorrect = true;
  bool _miss = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _type = c?.type ?? CardType.basic;
    _scn = TextEditingController(text: c?.scn ?? '');
    _topic = TextEditingController(text: c?.topic ?? '');
    _q = TextEditingController(text: c?.q ?? '');
    _why = TextEditingController(text: c?.why ?? '');
    _miss = c?.miss ?? false;
    _answer = TextEditingController(text: c is BasicCard ? c.a : '');
    _explanation = TextEditingController(text: _explanationOf(c));

    switch (c) {
      case MultipleChoiceCard():
        _choices = c.choices.map((s) => TextEditingController(text: s)).toList();
        _mcCorrect = c.correct >= 0 ? c.correct : null;
      case MultiSelectCard():
        _choices = c.choices.map((s) => TextEditingController(text: s)).toList();
        _msCorrect = c.correct.toSet();
      case TrueFalseCard():
        _tfCorrect = c.correct;
      case FillInBlankCard():
        _accepted =
            c.accepted.map((s) => TextEditingController(text: s)).toList();
      case BasicCard():
      case null:
        break;
    }
    if (_choices.isEmpty) {
      _choices = [TextEditingController(), TextEditingController()];
    }
    if (_accepted.isEmpty) _accepted = [TextEditingController()];
  }

  static String _explanationOf(Card? c) => switch (c) {
        MultipleChoiceCard() => c.explanation ?? '',
        MultiSelectCard() => c.explanation ?? '',
        TrueFalseCard() => c.explanation ?? '',
        FillInBlankCard() => c.explanation ?? '',
        _ => '',
      };

  @override
  void dispose() {
    for (final c in [_scn, _topic, _q, _why, _answer, _explanation]) {
      c.dispose();
    }
    for (final c in [..._choices, ..._accepted]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final q = _q.text.trim();
    if (q.isEmpty) {
      setState(() => _error = 'Question is required.');
      return;
    }
    final id = widget.card?.id ??
        'card-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    final scn = _scn.text.trim();
    final topic = _topic.text.trim();
    final why = _why.text.trim();
    final explanation = _explanation.text.trim();

    Card built;
    switch (_type) {
      case CardType.basic:
        final a = _answer.text.trim();
        if (a.isEmpty) {
          setState(() => _error = 'Answer is required.');
          return;
        }
        built = BasicCard(
          id: id, scn: scn, topic: topic, q: q, a: a, why: why,
          miss: _miss, userOwned: true,
        );
      case CardType.mc:
        final choices = _nonEmptyChoices();
        if (choices.length < 2 || _mcCorrect == null) {
          setState(() => _error = 'Add 2+ choices and mark the correct one.');
          return;
        }
        built = MultipleChoiceCard(
          id: id, scn: scn, topic: topic, q: q, choices: choices,
          correct: _mcCorrect!, explanation: explanation, why: why,
          miss: _miss, userOwned: true,
        );
      case CardType.ms:
        final choices = _nonEmptyChoices();
        if (choices.length < 2 || _msCorrect.isEmpty) {
          setState(() => _error = 'Add 2+ choices and mark the correct ones.');
          return;
        }
        built = MultiSelectCard(
          id: id, scn: scn, topic: topic, q: q, choices: choices,
          correct: (_msCorrect.toList()..sort()), explanation: explanation,
          why: why, miss: _miss, userOwned: true,
        );
      case CardType.tf:
        built = TrueFalseCard(
          id: id, scn: scn, topic: topic, q: q, correct: _tfCorrect,
          explanation: explanation, why: why, miss: _miss, userOwned: true,
        );
      case CardType.fib:
        final accepted = _accepted
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (accepted.isEmpty) {
          setState(() => _error = 'Add at least one accepted answer.');
          return;
        }
        built = FillInBlankCard(
          id: id, scn: scn, topic: topic, q: q, accepted: accepted,
          explanation: explanation, why: why, miss: _miss, userOwned: true,
        );
    }

    context.read<AppBloc>().add(CardUpserted(widget.deckId, built));
    Navigator.of(context).pop();
  }

  List<String> _nonEmptyChoices() => _choices
      .map((c) => c.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.card == null ? 'Add card' : 'Edit card',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _label('Type'),
              DropdownButtonFormField<CardType>(
                value: _type,
                decoration: _dec(),
                dropdownColor: AppColors.surface2,
                items: const [
                  DropdownMenuItem(value: CardType.basic, child: Text('Basic')),
                  DropdownMenuItem(
                      value: CardType.mc, child: Text('Multiple choice')),
                  DropdownMenuItem(
                      value: CardType.ms, child: Text('Multi-select')),
                  DropdownMenuItem(value: CardType.tf, child: Text('True / false')),
                  DropdownMenuItem(
                      value: CardType.fib, child: Text('Fill in the blank')),
                ],
                onChanged: (t) => setState(() => _type = t ?? _type),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('Scenario key', _scn)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Topic', _topic)),
                ],
              ),
              const SizedBox(height: 12),
              _field('Question', _q, maxLines: 3),
              const SizedBox(height: 12),
              ..._typeSection(),
              const SizedBox(height: 12),
              _field('Why it matters (optional)', _why, maxLines: 2),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Flagged as missed', style: mono.hint),
                value: _miss,
                onChanged: (v) => setState(() => _miss = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: mono.hint.copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _typeSection() {
    return switch (_type) {
      CardType.basic => [_field('Answer', _answer, maxLines: 3)],
      CardType.mc || CardType.ms => [
          _label(_type == CardType.mc
              ? 'Choices (tap to mark correct)'
              : 'Choices (tap to mark correct ones)'),
          ..._choiceRows(),
          _addButton('Add choice', () {
            setState(() => _choices.add(TextEditingController()));
          }),
          const SizedBox(height: 12),
          _field('Explanation (optional)', _explanation, maxLines: 2),
        ],
      CardType.tf => [
          _label('Correct answer'),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('True')),
              ButtonSegment(value: false, label: Text('False')),
            ],
            selected: {_tfCorrect},
            onSelectionChanged: (s) => setState(() => _tfCorrect = s.first),
          ),
          const SizedBox(height: 12),
          _field('Explanation (optional)', _explanation, maxLines: 2),
        ],
      CardType.fib => [
          _label('Accepted answers'),
          ..._acceptedRows(),
          _addButton('Add accepted answer', () {
            setState(() => _accepted.add(TextEditingController()));
          }),
          const SizedBox(height: 12),
          _field('Explanation (optional)', _explanation, maxLines: 2),
        ],
    };
  }

  List<Widget> _choiceRows() {
    final isMulti = _type == CardType.ms;
    return [
      for (var i = 0; i < _choices.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isMulti
                      ? (_msCorrect.contains(i)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                      : (_mcCorrect == i
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off),
                  color: AppColors.action,
                ),
                onPressed: () => setState(() {
                  if (isMulti) {
                    _msCorrect.contains(i)
                        ? _msCorrect.remove(i)
                        : _msCorrect.add(i);
                  } else {
                    _mcCorrect = i;
                  }
                }),
              ),
              Expanded(
                child: TextField(
                  controller: _choices[i],
                  style: _inputStyle(),
                  decoration: _dec(hint: 'Choice ${i + 1}'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                onPressed: _choices.length <= 2
                    ? null
                    : () => setState(() {
                          _choices.removeAt(i).dispose();
                          _mcCorrect = null;
                          _msCorrect = {};
                        }),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _acceptedRows() {
    return [
      for (var i = 0; i < _accepted.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _accepted[i],
                  style: _inputStyle(),
                  decoration: _dec(hint: 'Accepted answer ${i + 1}'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                onPressed: _accepted.length <= 1
                    ? null
                    : () => setState(() => _accepted.removeAt(i).dispose()),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _addButton(String label, VoidCallback onTap) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 16),
          label: Text(label),
        ),
      );

  Widget _label(String text) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(),
          style: mono.chip.copyWith(letterSpacing: 1)),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: c,
          maxLines: maxLines,
          style: _inputStyle(),
          decoration: _dec(),
        ),
      ],
    );
  }

  TextStyle _inputStyle() => const TextStyle(
        fontSize: 13,
        color: AppColors.text,
      );

  InputDecoration _dec({String? hint}) => InputDecoration(
        filled: true,
        fillColor: AppColors.ink,
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      );
}
