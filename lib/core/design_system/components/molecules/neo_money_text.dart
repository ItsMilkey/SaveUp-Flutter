import 'dart:ui' as ui;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../money/money.dart';
import '../../theme/saveup_colors.dart';
import '../../tokens/app_typography.dart';

enum NeoMoneySize { display, headline, title, body }

enum NeoMoneyTone { neutral, income, expense, savings }

/// Monto formateado en CLP con tipografía tabular y tono semántico.
///
/// El dinero entra como `Decimal`; nunca como `double`.
class NeoMoneyText extends StatelessWidget {
  const NeoMoneyText({
    super.key,
    required this.amount,
    this.size = NeoMoneySize.body,
    this.tone = NeoMoneyTone.neutral,
    this.signed = false,
  });

  final Decimal amount;
  final NeoMoneySize size;
  final NeoMoneyTone tone;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final Color color = switch (tone) {
      NeoMoneyTone.neutral => colors.ink,
      NeoMoneyTone.income => colors.positiveText,
      NeoMoneyTone.expense => colors.negativeText,
      NeoMoneyTone.savings => colors.savingsText,
    };
    final TextStyle style = switch (size) {
      NeoMoneySize.display => AppTypography.display(size: 32, color: color),
      NeoMoneySize.headline => AppTypography.text(
        size: 24,
        weight: FontWeight.w700,
        color: color,
      ),
      NeoMoneySize.title => AppTypography.text(
        size: 18,
        weight: FontWeight.w600,
        color: color,
      ),
      NeoMoneySize.body => AppTypography.text(
        size: 14,
        weight: FontWeight.w600,
        color: color,
      ),
    }.copyWith(
      fontFeatures: const <ui.FontFeature>[ui.FontFeature.tabularFigures()],
    );

    String text = Money.formatClp(amount);
    if (signed && amount > Decimal.zero) {
      text = '+$text';
    }

    return Semantics(
      label: text,
      child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.fade),
    );
  }
}
