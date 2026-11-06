import 'package:flutter/material.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../l10n/l10n.dart';

/// Quick swatches users pick from most of the time.
const _swatches = [
  Color(0xFF7C4DFF), Color(0xFF448AFF), Color(0xFF00B0FF), Color(0xFF00E5FF),
  Color(0xFF1DE9B6), Color(0xFF00C853), Color(0xFFAEEA00), Color(0xFFFFD600),
  Color(0xFFFF9100), Color(0xFFFF3D00), Color(0xFFFF1744), Color(0xFFF50057),
  Color(0xFFD500F9), Color(0xFF8D6E63), Color(0xFF78909C), Color(0xFFECEFF1),
];

/// Expandable tile: swatches + hue/saturation/lightness sliders. No package
/// needed and works with mouse and touch.
class ColorPickerTile extends StatefulWidget {
  const ColorPickerTile({super.key, required this.title, required this.color, required this.onChanged});

  final String title;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<ColorPickerTile> createState() => _ColorPickerTileState();
}

class _ColorPickerTileState extends State<ColorPickerTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(widget.color);
    final hex = '#${(widget.color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return Column(
      children: [
        ListTile(
          title: Text(widget.title),
          subtitle: Text(hex),
          trailing: AnimatedContainer(
            duration: context.motion.d(PrismMotion.medium),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
          ),
          onTap: () => setState(() => _open = !_open),
        ),
        AnimatedSize(
          duration: context.motion.d(PrismMotion.medium),
          curve: Curves.easeOutCubic,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in _swatches)
                            SpringButton(
                              onTap: () => widget.onChanged(c),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: c.toARGB32() == widget.color.toARGB32()
                                      ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _GradientSlider(
                        label: l10n.hue,
                        value: hsl.hue / 360,
                        colors: [for (var h = 0; h <= 360; h += 60) HSLColor.fromAHSL(1, h.toDouble(), 1, 0.5).toColor()],
                        onChanged: (v) => widget.onChanged(hsl.withHue(v * 360).toColor()),
                      ),
                      _GradientSlider(
                        label: l10n.saturation,
                        value: hsl.saturation,
                        colors: [hsl.withSaturation(0).toColor(), hsl.withSaturation(1).toColor()],
                        onChanged: (v) => widget.onChanged(hsl.withSaturation(v).toColor()),
                      ),
                      _GradientSlider(
                        label: l10n.lightness,
                        value: hsl.lightness,
                        colors: [Colors.black, hsl.withLightness(0.5).toColor(), Colors.white],
                        onChanged: (v) => widget.onChanged(hsl.withLightness(v).toColor()),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({required this.label, required this.value, required this.colors, required this.onChanged});

  final String label;
  final double value;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 84, child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(colors: colors),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                ),
                child: Slider(value: value.clamp(0.0, 1.0), onChanged: onChanged),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
