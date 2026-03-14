import 'package:flutter/material.dart';

import '../bootstrap/manual_location_preset.dart';

class WorldTimeZoneBand {
  const WorldTimeZoneBand({
    required this.utcOffsetHours,
    required this.label,
    required this.presets,
  });

  final double utcOffsetHours;
  final String label;
  final List<ManualLocationPreset> presets;
}

class WorldTimeZonePicker extends StatelessWidget {
  const WorldTimeZonePicker({
    super.key,
    required this.bands,
    required this.selectedPreset,
    required this.onPresetSelected,
  });

  final List<WorldTimeZoneBand> bands;
  final ManualLocationPreset selectedPreset;
  final ValueChanged<ManualLocationPreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final int selectedBandIndex = _selectedBandIndex();
    final WorldTimeZoneBand selectedBand = bands[selectedBandIndex];
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.public,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'World map',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the map to jump to a time zone band, then choose a nearby city inside that band.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GestureDetector(
                onTapDown: (TapDownDetails details) {
                  final double width = constraints.maxWidth;
                  final int rawIndex =
                      (details.localPosition.dx / width * bands.length).floor();
                  final int safeIndex = rawIndex.clamp(0, bands.length - 1);
                  onPresetSelected(bands[safeIndex].presets.first);
                },
                child: AspectRatio(
                  aspectRatio: 1.75,
                  child: CustomPaint(
                    painter: _WorldMapBandsPainter(
                      selectedBandIndex: selectedBandIndex,
                      bandCount: bands.length,
                      colorScheme: colorScheme,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                Icons.schedule,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                selectedBand.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedBand.presets.map((ManualLocationPreset preset) {
              final bool selected = preset.id == selectedPreset.id;
              return ChoiceChip(
                label: Text(preset.city),
                selected: selected,
                onSelected: (_) => onPresetSelected(preset),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  int _selectedBandIndex() {
    final int index = bands.indexWhere(
      (WorldTimeZoneBand band) => band.presets
          .any((ManualLocationPreset preset) => preset.id == selectedPreset.id),
    );
    return index == -1 ? 0 : index;
  }
}

class _WorldMapBandsPainter extends CustomPainter {
  const _WorldMapBandsPainter({
    required this.selectedBandIndex,
    required this.bandCount,
    required this.colorScheme,
  });

  final int selectedBandIndex;
  final int bandCount;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stripePaint = Paint()..style = PaintingStyle.fill;
    final double stripeWidth = size.width / bandCount;
    final List<Color> palette = <Color>[
      const Color(0xFFE7D7B8),
      const Color(0xFFBFE3D4),
      const Color(0xFFD9EAD0),
      const Color(0xFFF4D2B7),
      const Color(0xFFC7DCF6),
      const Color(0xFFF1E4BE),
    ];

    for (int index = 0; index < bandCount; index += 1) {
      stripePaint.color = palette[index % palette.length];
      canvas.drawRect(
        Rect.fromLTWH(index * stripeWidth, 0, stripeWidth, size.height),
        stripePaint,
      );
    }

    stripePaint.color = colorScheme.primary.withValues(alpha: 0.82);
    canvas.drawRect(
      Rect.fromLTWH(
        selectedBandIndex * stripeWidth,
        0,
        stripeWidth,
        size.height,
      ),
      stripePaint,
    );

    final Paint continentPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.54)
      ..style = PaintingStyle.fill;
    final Paint outlinePaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Path americas = Path()
      ..moveTo(size.width * 0.08, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.08,
        size.width * 0.22,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.26,
        size.width * 0.24,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.42,
        size.width * 0.2,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.72,
        size.width * 0.18,
        size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.76,
        size.width * 0.1,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.05,
        size.height * 0.34,
        size.width * 0.08,
        size.height * 0.16,
      )
      ..close();

    final Path euroAfrica = Path()
      ..moveTo(size.width * 0.42, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.1,
        size.width * 0.57,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        size.width * 0.61,
        size.height * 0.3,
        size.width * 0.55,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.48,
        size.width * 0.53,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.84,
        size.width * 0.44,
        size.height * 0.64,
      )
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.46,
        size.width * 0.42,
        size.height * 0.2,
      )
      ..close();

    final Path asia = Path()
      ..moveTo(size.width * 0.56, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.04,
        size.width * 0.86,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.28,
        size.width * 0.88,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.52,
        size.width * 0.7,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.42,
        size.width * 0.56,
        size.height * 0.18,
      )
      ..close();

    final Path australia = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.82, size.height * 0.73),
          width: size.width * 0.12,
          height: size.height * 0.1,
        ),
      );

    for (final Path path in <Path>[americas, euroAfrica, asia, australia]) {
      canvas.drawPath(path, continentPaint);
      canvas.drawPath(path, outlinePaint);
    }

    final Paint gridPaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (int index = 1; index < bandCount; index += 1) {
      final double x = index * stripeWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapBandsPainter oldDelegate) {
    return oldDelegate.selectedBandIndex != selectedBandIndex ||
        oldDelegate.bandCount != bandCount ||
        oldDelegate.colorScheme != colorScheme;
  }
}
