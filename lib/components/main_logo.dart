import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainLogo extends StatelessWidget {
    final double width;

    const MainLogo({
        super.key,
        this.width = 240,
    });

    @override
    Widget build(BuildContext context) {
        return SvgPicture.asset(
            'assets/images/flock_uwb_main_logo.svg',
            width: width,
            semanticsLabel: 'Flock UWB Main Logo'
        );
    }
}