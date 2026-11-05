import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// The app's one search box: a glass stadium with a leading glyph, the
/// field, and a clear button once there is text.
///
/// Search and Library each built their own — one with Material's dense
/// prefix icon and a 4px inner padding, one with a hand-placed icon and a
/// 16px one — so the same control changed height and icon position between
/// two tabs. The desktop top bar's shortcut button uses the same shape.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Runs after the field is cleared by its own button.
  final VoidCallback? onClear;
  final bool autofocus;

  /// Outer height of the field at 1x text, glass edge included.
  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Focused — by click or by key — the field glows with a soft Aurora halo;
    // the 48 px stadium is the control, so that is what is haloed.
    return FocusDecoration(
      ring: false,
      keyboardOnly: false,
      borderRadius: BorderRadius.circular(OmnisonicRadius.full),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        padding: const EdgeInsets.only(
          left: OmnisonicSpacing.md,
          right: OmnisonicSpacing.xs,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height - 2),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  OmnisonicIcons.search,
                  size: OmnisonicIconSizes.smd,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: OmnisonicSpacing.sm),
              Expanded(
                // The field fills the stadium's whole inner height (46, plus
                // the glass's 1px edge each side = 48) and centres its text,
                // so the entire pill is the tap target.
                child: SizedBox(
                  height: height - 2,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    // Fill the 46 and centre the line in it.
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlignVertical: TextAlignVertical.center,
                    style: OmnisonicTypography.bodyMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                    // One line: `expands` would otherwise make Enter a newline.
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: hint,
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                  ),
                ),
              ),
              // Driven by the controller, not the parent's build: typing does
              // not rebuild the page, so reading `.text` here would go stale.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) => value.text.isEmpty
                    ? const SizedBox(
                        width: OmnisonicSpacing.sm,
                        height: OmnisonicTouchTargets.minimum,
                      )
                    : IconButton(
                        icon: const Icon(OmnisonicIcons.close),
                        iconSize: OmnisonicIconSizes.sm,
                        color: scheme.onSurfaceVariant,
                        tooltip: 'Clear search',
                        onPressed: () {
                          controller.clear();
                          onChanged?.call('');
                          onClear?.call();
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
