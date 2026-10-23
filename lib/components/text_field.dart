import 'package:flutter/material.dart';

import 'foundation.dart';

/// Field = header (label, optional mark) + input + footer (helper or error,
/// character count). The label stays above the input so it is visible while
/// typing; an error replaces the helper instead of stacking with it. Mark the
/// optional fields with text, not the required ones with a symbol, and do not
/// mix the two on one screen.
class ImHereTextField extends StatefulWidget {
  const ImHereTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.optional = false,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool optional;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final int maxLines;

  @override
  State<ImHereTextField> createState() => _ImHereTextFieldState();
}

class _ImHereTextFieldState extends State<ImHereTextField> {
  late int _length = widget.controller?.text.length ?? 0;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hasError = widget.errorText != null;
    final note = widget.errorText ?? widget.helper;
    final gap = SizedBox(height: metrics.resolve(ImHereSpace.xs));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label,
            children: [
              if (widget.optional)
                TextSpan(
                  text: ' (선택)',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          style: textTheme.titleSmall?.copyWith(
            color: hasError ? colors.error : colors.text,
          ),
        ),
        gap,
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          onChanged: (value) {
            setState(() => _length = value.length);
            widget.onChanged?.call(value);
          },
          onSubmitted: widget.onSubmitted,
          style: textTheme.bodyLarge,
          cursorColor: colors.action,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            errorStyle: const TextStyle(fontSize: 0, height: 0),
            contentPadding: EdgeInsets.symmetric(
              horizontal: metrics.resolve(ImHereSpace.md),
              vertical: metrics.resolve(ImHereSpace.sm),
            ),
          ),
        ),
        if (note != null || widget.maxLength != null) ...[
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: note == null
                    ? const SizedBox.shrink()
                    : Semantics(
                        liveRegion: hasError,
                        child: Text(
                          note,
                          style: textTheme.bodySmall?.copyWith(
                            color: hasError ? colors.error : colors.textMuted,
                          ),
                        ),
                      ),
              ),
              if (widget.maxLength != null)
                Padding(
                  padding: EdgeInsets.only(
                    left: metrics.resolve(ImHereSpace.xs),
                  ),
                  child: Text(
                    '$_length/${widget.maxLength}',
                    style: textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
