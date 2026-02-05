import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Branding element with logo and app name.
/// Used at the top of auth form panels (login, register).
class AuthBranding extends StatelessWidget {
  const AuthBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/logo-icon-light.svg',
          width: 56,
          height: 56,
        ),
        const SizedBox(width: 16),
        Text(
          'Papyrus',
          style: TextStyle(
            fontFamily: 'MadimiOne',
            fontSize: 36,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
