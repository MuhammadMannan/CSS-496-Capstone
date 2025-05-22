import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CrowOrb extends StatelessWidget {
  final String crowAsset;   // SVG file name like 'crow_reg.svg'
  final double size;        // Overall size of the orb

  const CrowOrb({
    this.crowAsset = 'crow_reg.svg',
    this.size = 120,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Crow icon (goes underneath)
        SvgPicture.asset(
          'assets/images/$crowAsset',
          width: size * 0.6, // Crow is 60% of total size
        ),
        // "O" ring overlay (always on top)
        SvgPicture.asset(
          'assets/images/O_blank.svg',
          width: size,
        ),
      ],
    );
  }
}
