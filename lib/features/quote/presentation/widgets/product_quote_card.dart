import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../logic/quote_plan.dart';

/// One product with its Price (৳) and Qty boxes.
class ProductQuoteCard extends StatefulWidget {
  const ProductQuoteCard({
    super.key,
    required this.line,
    required this.showErrors,
    required this.onChanged,
  });

  final LineView line;
  final bool showErrors;
  final void Function(String price, String qty) onChanged;

  @override
  State<ProductQuoteCard> createState() => _ProductQuoteCardState();
}

class _ProductQuoteCardState extends State<ProductQuoteCard> {
  late final TextEditingController _price;
  late final TextEditingController _qty;

  /// Price: digits with up to 2 decimals.
  static final _priceFormatter = TextInputFormatter.withFunction(
    (old, next) =>
        RegExp(r'^\d{0,9}(\.\d{0,2})?$').hasMatch(next.text) ? next : old,
  );

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: widget.line.priceText);
    _qty = TextEditingController(text: widget.line.qtyText);
  }

  @override
  void didUpdateWidget(ProductQuoteCard old) {
    super.didUpdateWidget(old);
    // Server data changed (e.g. after Send): show the new values.
    _sync(_price, widget.line.priceText);
    _sync(_qty, widget.line.qtyText);
  }

  void _sync(TextEditingController c, String value) {
    if (c.text != value) {
      c.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _changed() => widget.onChanged(_price.text, _qty.text);

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final p = line.product;
    final theme = Theme.of(context).textTheme;

    final price = num.tryParse(line.priceText) ?? 0;
    final qty = num.tryParse(line.qtyText) ?? 0;
    final hasTotal = p.editable && price > 0 && qty > 0;

    // One short grey line: brand · Needed: 40 · request note
    final subline = [
      if (p.brand != null && p.brand!.isNotEmpty) p.brand!,
      if (p.neededQty != null) 'Needed: ${Fmt.number(p.neededQty!)}',
      if (p.requestNote != null && p.requestNote!.isNotEmpty) p.requestNote!,
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      borderColor: line.isDirty ? AppColors.primary : AppColors.border,
      color: p.editable ? AppColors.surface : const Color(0xFFFAFBFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: [thumb] name + subline, badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.imageUrl != null && p.imageUrl!.isNotEmpty) ...[
                _Thumb(url: p.imageUrl!),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _ExpandableTitle(
                  name: p.name,
                  subline: subline,
                  nameStyle: theme.titleMedium?.copyWith(
                    fontSize: 16,
                    height: 1.25,
                  ),
                  sublineStyle: theme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              line.isDirty
                  ? const StatusBadge(
                      label: 'Not sent',
                      tone: BadgeTone.info,
                      compact: true,
                    )
                  : StatusBadge.forStatus(p.status, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: price & qty boxes (+ line total)
          if (p.editable)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _NumberField(
                    prefix: '৳',
                    controller: _price,
                    hint: 'Price',
                    decimal: true,
                    formatter: _priceFormatter,
                    error: widget.showErrors && line.missingPrice
                        ? 'Enter price'
                        : null,
                    onChanged: (_) => _changed(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _NumberField(
                    prefix: 'Qty',
                    controller: _qty,
                    hint: p.neededQty != null ? Fmt.plain(p.neededQty) : '0',
                    decimal: false,
                    formatter: FilteringTextInputFormatter.digitsOnly,
                    error: widget.showErrors && line.missingQty
                        ? 'Enter qty'
                        : null,
                    onChanged: (_) => _changed(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 74,
                  height: 42,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hasTotal ? Fmt.money(price * qty) : '৳—',
                        style: theme.labelLarge?.copyWith(
                          color: hasTotal ? AppColors.text : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              p.isQuoted
                  ? '${Fmt.money(p.myPrice)} × ${Fmt.number(p.myQty!)}'
                        ' = ${Fmt.money(p.myPrice! * p.myQty!)}'
                  : 'Not quoted',
              style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

/// Compact number box with a fixed label inside it ("৳" / "Qty").
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.prefix,
    required this.controller,
    required this.hint,
    required this.decimal,
    required this.formatter,
    required this.onChanged,
    this.error,
  });

  final String prefix;
  final TextEditingController controller;
  final String hint;
  final bool decimal;
  final TextInputFormatter formatter;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textInputAction: TextInputAction.next,
      inputFormatters: [formatter],
      style: theme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        errorText: error,
        errorStyle: const TextStyle(fontSize: 12, height: 1),
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(0, 11, 10, 11),
        // Always visible (unlike prefixText, which hides when empty).
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 6),
          child: Text(
            prefix,
            style: theme.labelLarge?.copyWith(color: AppColors.textMuted),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      onChanged: onChanged,
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => const ColoredBox(
      color: AppColors.neutralBg,
      child: Icon(
        Icons.medication_outlined,
        size: 18,
        color: AppColors.textMuted,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 36,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, _) => fallback(),
          errorWidget: (_, _, _) => fallback(),
        ),
      ),
    );
  }
}

/// Product name (up to 2 lines) + grey details line (1 line).
/// When anything is cut off, a "More" arrow appears and tapping the
/// title shows the full text; tapping again folds it back.
class _ExpandableTitle extends StatefulWidget {
  const _ExpandableTitle({
    required this.name,
    required this.subline,
    required this.nameStyle,
    required this.sublineStyle,
  });

  final String name;
  final String subline;
  final TextStyle? nameStyle;
  final TextStyle? sublineStyle;

  static const int nameLines = 2;
  static const int sublineLines = 1;

  @override
  State<_ExpandableTitle> createState() => _ExpandableTitleState();
}

class _ExpandableTitleState extends State<_ExpandableTitle> {
  bool _expanded = false;

  bool _overflows(
    String text,
    TextStyle? style,
    int maxLines,
    double maxWidth,
    TextScaler scaler,
    TextDirection dir,
  ) {
    if (text.isEmpty) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: dir,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth);
    final result = painter.didExceedMaxLines;
    painter.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final canExpand =
            _overflows(
              widget.name,
              widget.nameStyle,
              _ExpandableTitle.nameLines,
              w,
              scaler,
              dir,
            ) ||
            _overflows(
              widget.subline,
              widget.sublineStyle,
              _ExpandableTitle.sublineLines,
              w - 22, // room for the arrow
              scaler,
              dir,
            );

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              maxLines: _expanded ? null : _ExpandableTitle.nameLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: widget.nameStyle,
            ),
            if (widget.subline.isNotEmpty || canExpand)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.subline,
                      maxLines: _expanded
                          ? null
                          : _ExpandableTitle.sublineLines,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: widget.sublineStyle,
                    ),
                  ),
                  if (canExpand || _expanded)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                ],
              ),
          ],
        );

        if (!canExpand && !_expanded) return content;

        return Semantics(
          button: true,
          label: _expanded ? 'Show less' : 'Show full name',
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _expanded = !_expanded),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topLeft,
              child: content,
            ),
          ),
        );
      },
    );
  }
}
