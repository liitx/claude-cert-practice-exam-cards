import 'package:drill_deck/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Visual treatment for a set of modify actions. Drives layout/style only —
/// which actions appear is decided by the caller from the entity's
/// capabilities, so availability is never tied to how the entity was created.
enum EntityActionStyle {
  /// Compact inline row of small labelled buttons (used on cards).
  card,

  /// A single overflow (⋮) button opening a menu (used in list/dropdown rows).
  menu,
}

/// One modify action: a label, optional icon, tap handler, and danger flag.
class EntityAction {
  const EntityAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool danger;
}

/// Generic, capability-driven action affordance shared by cards and deck rows.
/// Renders nothing when [actions] is empty.
class EntityActions extends StatelessWidget {
  const EntityActions({
    required this.actions,
    required this.style,
    this.iconColor,
    super.key,
  });

  final List<EntityAction> actions;
  final EntityActionStyle style;

  /// Tint for the trigger icon (menu style). Defaults to a muted text color.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return switch (style) {
      EntityActionStyle.card => _CardRow(actions: actions),
      EntityActionStyle.menu => _Menu(actions: actions, iconColor: iconColor),
    };
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.actions});
  final List<EntityAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final a in actions)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _IconButton(action: a),
          ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.action});
  final EntityAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.danger ? AppColors.danger : AppColors.muted;
    return Tooltip(
      message: action.label,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: action.danger ? AppColors.danger : AppColors.line,
              width: 0.8,
            ),
          ),
          child: Icon(action.icon ?? Icons.more_horiz, size: 16, color: color),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.actions, this.iconColor});
  final List<EntityAction> actions;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      color: AppColors.surface2,
      tooltip: 'Actions',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      icon: Icon(Icons.more_vert, size: 20, color: iconColor ?? AppColors.text),
      onSelected: (i) => actions[i].onTap(),
      itemBuilder: (context) => [
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                if (actions[i].icon != null) ...[
                  Icon(
                    actions[i].icon,
                    size: 16,
                    color: actions[i].danger ? AppColors.danger : AppColors.text,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  actions[i].label,
                  style: TextStyle(
                    color:
                        actions[i].danger ? AppColors.danger : AppColors.text,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
