import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:salah/models/prayer.dart';
import 'package:salah/theme.dart';

/// A single pressed blossom.
class Blossom extends StatelessWidget {
  const Blossom({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/flowers/blossom.svg',
        width: size,
        height: size,
      );
}

/// A single pressed leaf.
class Leaf extends StatelessWidget {
  const Leaf({super.key, this.width = 20, this.angle = 0});
  final double width;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: SvgPicture.asset(
          'assets/flowers/leaf.svg',
          width: width,
          height: width * 0.4,
        ),
      );
}

/// The prayer marker: empty / done / missed.
class PrayerMarker extends StatelessWidget {
  const PrayerMarker({super.key, required this.status, this.size = 22});
  final PrayerStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = switch (status) {
      PrayerStatus.pending => 'assets/flowers/marker_empty.svg',
      PrayerStatus.done => 'assets/flowers/marker_done.svg',
      PrayerStatus.missed => 'assets/flowers/marker_missed.svg',
    };
    return SvgPicture.asset(asset, width: size, height: size);
  }
}

/// A small cluster of blossoms and leaves for the page header.
class Garland extends StatelessWidget {
  const Garland({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 40, top: 18, child: Leaf(width: 18, angle: 3.4)),
          Positioned(right: 40, top: 18, child: Leaf(width: 18, angle: -0.4)),
          const Positioned(left: 74, top: 12, child: Blossom(size: 15)),
          const Positioned(top: 2, child: Blossom(size: 24)),
          const Positioned(right: 74, top: 10, child: Blossom(size: 18)),
        ],
      ),
    );
  }
}

/// A centred pair of mirrored leaves, used between prayer groups.
class SprigDivider extends StatelessWidget {
  const SprigDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Leaf(width: 16, angle: 3.14),
          const SizedBox(width: 4),
          Leaf(width: 16),
        ],
      ),
    );
  }
}

/// The soft cream card used across the app for grouped content.
class GardenCard extends StatelessWidget {
  const GardenCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GardenColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E7CF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: child,
    );
  }
}

/// A section label ("PRAYERS") trailed by a dotted rule.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 10),
          const Expanded(child: _DottedRule()),
        ],
      ),
    );
  }
}

/// A thin dotted horizontal rule in the palette's line colour.
class _DottedRule extends StatelessWidget {
  const _DottedRule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 2, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GardenColors.line
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dash = 1.5;
    const gap = 5.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}
