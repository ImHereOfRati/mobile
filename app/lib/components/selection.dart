import 'package:flutter/material.dart';

import 'foundation.dart';
import 'icon.dart';

/// Pill that shows a value the user picks or enters. Selected chips invert to
/// the text color so they never depend on the brand color.
class ImHereChip extends StatelessWidget {
  const ImHereChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onChanged != null,
      label: label,
      excludeSemantics: true,
      onTap: onChanged == null ? null : () => onChanged!(!selected),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!selected),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: metrics.touchTarget),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: ImHereMotion.colorOf(context),
              curve: ImHereMotion.easing,
              padding: EdgeInsets.symmetric(
                horizontal: metrics.resolve(ImHereSpace.md),
                vertical: metrics.resolve(ImHereSpace.xs),
              ),
              decoration: BoxDecoration(
                color: selected ? colors.text : Colors.transparent,
                border: Border.all(
                  color: selected ? colors.text : colors.border,
                  width: metrics.resolve(1),
                ),
                borderRadius: BorderRadius.circular(
                  metrics.resolve(ImHereRadius.pill),
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? colors.background : colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({
    required this.label,
    required this.onTap,
    required this.semantics,
    required this.control,
    this.action,
    this.prefix,
  });
  final String label;
  final Widget? action;
  final Widget? prefix;
  final VoidCallback? onTap;
  final Semantics Function(Widget child) semantics;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    return semantics(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: metrics.touchTarget),
          child: Row(
            children: [
              if (prefix != null) ...[
                prefix!,
                SizedBox(width: metrics.resolve(ImHereSpace.xs)),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (action != null) ...[
                SizedBox(width: metrics.resolve(ImHereSpace.xs)),
                action!,
              ],
              SizedBox(width: metrics.resolve(ImHereSpace.md)),
              control,
            ],
          ),
        ),
      ),
    );
  }
}

/// On/off that applies immediately. Use [ImHereCheckbox] when the choice is
/// only applied on submit.
class ImHereSwitch extends StatelessWidget {
  const ImHereSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final enabled = onChanged != null;
    return _Labeled(
      label: label,
      onTap: enabled ? () => onChanged!(!value) : null,
      semantics: (child) => Semantics(
        toggled: value,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: child,
      ),
      control: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: AnimatedContainer(
          duration: ImHereMotion.colorOf(context),
          curve: ImHereMotion.easing,
          width: metrics.resolve(48),
          height: metrics.resolve(28),
          padding: EdgeInsets.all(metrics.resolve(3)),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? colors.action : colors.border,
            borderRadius: BorderRadius.circular(
              metrics.resolve(ImHereRadius.pill),
            ),
          ),
          child: Container(
            width: metrics.resolve(22),
            height: metrics.resolve(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class ImHereCheckbox extends StatelessWidget {
  const ImHereCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.action,
    this.prefix,
  });
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Secondary control shown beside the label (e.g. a "view" link). Taps on it
  /// do not toggle the checkbox.
  final Widget? action;

  /// Short marker shown before the label (e.g. a required/optional tag).
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final enabled = onChanged != null;
    return _Labeled(
      label: label,
      action: action,
      prefix: prefix,
      onTap: enabled ? () => onChanged!(!value) : null,
      semantics: (child) => Semantics(
        checked: value,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: child,
      ),
      control: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: AnimatedContainer(
          duration: ImHereMotion.colorOf(context),
          curve: ImHereMotion.easing,
          width: metrics.resolve(24),
          height: metrics.resolve(24),
          decoration: BoxDecoration(
            color: value ? colors.action : Colors.transparent,
            border: Border.all(
              color: value ? colors.action : colors.border,
              width: metrics.resolve(1.5),
            ),
            borderRadius: BorderRadius.circular(metrics.resolve(6)),
          ),
          child: value
              ? Center(
                  child: ImHereIcon(
                    glyph: ImHereGlyph.check,
                    size: 16,
                    color: colors.onAction,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// One option of a single-choice group. Group them in a Column and keep the
/// selected value in the parent.
class ImHereRadio<T> extends StatelessWidget {
  const ImHereRadio({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });
  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final selected = value == groupValue;
    final enabled = onChanged != null;
    return _Labeled(
      label: label,
      onTap: enabled ? () => onChanged!(value) : null,
      semantics: (child) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        onTap: enabled ? () => onChanged!(value) : null,
        child: child,
      ),
      control: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: AnimatedContainer(
          duration: ImHereMotion.colorOf(context),
          curve: ImHereMotion.easing,
          width: metrics.resolve(24),
          height: metrics.resolve(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.action : colors.border,
              width: metrics.resolve(selected ? 7 : 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Switches between peer views of the same content (2 to 4 options).
class ImHereSegmentedControl extends StatelessWidget {
  const ImHereSegmentedControl({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  }) : assert(labels.length >= 2 && labels.length <= 4);
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final inset = metrics.resolve(ImHereSpace.xxs);
    return Container(
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(metrics.resolve(ImHereRadius.md)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: labels[i],
                excludeSemantics: true,
                onTap: () => onChanged(i),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: ImHereMotion.colorOf(context),
                    curve: ImHereMotion.easing,
                    constraints: BoxConstraints(
                      minHeight: metrics.touchTarget - inset * 2,
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.resolve(ImHereSpace.xs),
                    ),
                    decoration: BoxDecoration(
                      color: i == index
                          ? colors.background
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        metrics.resolve(ImHereRadius.sm),
                      ),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: i == index ? colors.text : colors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
