import 'package:drill_deck/features/ask_claude/prompt_builder.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';

class AskClaudeSheet extends StatefulWidget {
  const AskClaudeSheet({required this.currentDeck, super.key});
  final Deck currentDeck;

  static Future<void> show(BuildContext context, Deck currentDeck) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AskClaudeSheet(currentDeck: currentDeck),
      ),
    );
  }

  @override
  State<AskClaudeSheet> createState() => _AskClaudeSheetState();
}

class _AskClaudeSheetState extends State<AskClaudeSheet> {
  late final TextEditingController _topic;
  late final TextEditingController _count;
  PromptCardType _type = PromptCardType.mc;
  PromptTarget _target = PromptTarget.newDeck;
  String? _note;

  @override
  void initState() {
    super.initState();
    _topic = TextEditingController();
    _count = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _topic.dispose();
    _count.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final input = ClaudePromptInput(
      topic: _topic.text,
      count: int.tryParse(_count.text.trim()) ?? 10,
      type: _type,
      target: _target,
      deck: widget.currentDeck,
    );
    final prompt = ClaudePrompt.build(input);
    await Clipboard.setData(ClipboardData(text: prompt));
    setState(() => _note = 'Copied. Paste into Claude.');
  }

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask Claude to generate a deck',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Pick a topic, copy the prompt, paste into Claude. Paste Claude\'s JSON into the import sheet.',
                style: mono.hint,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topic,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'e.g. Kubernetes networking',
                  filled: true,
                  fillColor: AppColors.ink,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _count,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'How many',
                        filled: true,
                        fillColor: AppColors.ink,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<PromptCardType>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Default type',
                        filled: true,
                        fillColor: AppColors.ink,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                        ),
                      ),
                      dropdownColor: AppColors.surface2,
                      items: const [
                        DropdownMenuItem(
                          value: PromptCardType.mc,
                          child: Text('Multiple choice'),
                        ),
                        DropdownMenuItem(
                          value: PromptCardType.ms,
                          child: Text('Select all'),
                        ),
                        DropdownMenuItem(
                          value: PromptCardType.tf,
                          child: Text('True / False'),
                        ),
                        DropdownMenuItem(
                          value: PromptCardType.fib,
                          child: Text('Fill blank'),
                        ),
                        DropdownMenuItem(
                          value: PromptCardType.basic,
                          child: Text('Basic'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _type = v ?? PromptCardType.mc),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<PromptTarget>(
                segments: [
                  const ButtonSegment(
                    value: PromptTarget.newDeck,
                    label: Text('New deck'),
                  ),
                  ButtonSegment(
                    value: PromptTarget.currentDeck,
                    label: Text('Add to "${widget.currentDeck.name}"'),
                  ),
                ],
                selected: {_target},
                onSelectionChanged: (s) =>
                    setState(() => _target = s.first),
              ),
              const SizedBox(height: 14),
              if (_note != null)
                Text(_note!, style: mono.hint.copyWith(color: AppColors.got)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _copy,
                      child: const Text('Copy prompt'),
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
}
