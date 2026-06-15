import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Names a deck. With [deckId] null it creates a new deck ([DeckCreated]);
/// otherwise it renames an existing one ([DeckRenamed]).
class DeckNameSheet extends StatefulWidget {
  const DeckNameSheet({this.deckId, this.initialName = '', super.key});

  final String? deckId;
  final String initialName;

  static Future<void> show(
    BuildContext context, {
    String? deckId,
    String initialName = '',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DeckNameSheet(deckId: deckId, initialName: initialName),
      ),
    );
  }

  @override
  State<DeckNameSheet> createState() => _DeckNameSheetState();
}

class _DeckNameSheetState extends State<DeckNameSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final bloc = context.read<AppBloc>();
    if (widget.deckId == null) {
      bloc.add(DeckCreated(name));
    } else {
      bloc.add(DeckRenamed(widget.deckId!, name));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.deckId == null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? 'New deck' : 'Rename deck',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.ink,
                hintText: 'Deck name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
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
                    child: Text(isNew ? 'Create' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
