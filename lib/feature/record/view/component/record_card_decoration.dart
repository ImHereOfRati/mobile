import 'package:flutter/material.dart';

BoxDecoration recordCardDecoration(ColorScheme cs) {
  return BoxDecoration(
    color: cs.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: cs.onSurface.withValues(alpha: 0.06),
        offset: const Offset(0, 2),
        blurRadius: 12,
      ),
    ],
  );
}
