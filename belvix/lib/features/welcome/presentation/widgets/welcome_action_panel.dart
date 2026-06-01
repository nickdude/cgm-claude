import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Bottom action surface for the Welcome screen.
///
/// Composes the primary CTA and the inline legal copy (with
/// tappable "Terms & Conditions" and "Privacy Policy" links).
class WelcomeActionPanel
    extends StatelessWidget {
  final VoidCallback onContinue;

  final TapGestureRecognizer
      termsRecognizer;

  final TapGestureRecognizer
      privacyRecognizer;

  const WelcomeActionPanel({
    super.key,
    required this.onContinue,
    required this.termsRecognizer,
    required this.privacyRecognizer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment
                .stretch,
        children: [
          const _HeroTitle(),
          const SizedBox(
            height: 22,
          ),
          _PrimaryCta(
            label:
                "Sign Up / Log In",
            onTap: onContinue,
          ),
          const SizedBox(
            height: 14,
          ),
          _LegalCopy(
            termsRecognizer:
                termsRecognizer,
            privacyRecognizer:
                privacyRecognizer,
          ),
        ],
      ),
    );
  }
}

/// Bold hero headline pinned above the CTA.
class _HeroTitle
    extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Decode\nMetabolic Heath",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontWeight:
            FontWeight.w800,
        height: 1.12,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// White pill CTA, matched to the figma.
class _PrimaryCta
    extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryCta({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          child: InkWell(
            borderRadius:
                BorderRadius
                    .circular(12),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style:
                    const TextStyle(
                  color: AppColors
                      .textPrimary,
                  fontSize: 15,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline legal text with two tappable links.
class _LegalCopy
    extends StatelessWidget {
  final TapGestureRecognizer
      termsRecognizer;

  final TapGestureRecognizer
      privacyRecognizer;

  const _LegalCopy({
    required this.termsRecognizer,
    required this.privacyRecognizer,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 11,
      color: Colors.white
          .withOpacity(0.82),
      height: 1.45,
    );

    final linkStyle = baseStyle
        .copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      decoration:
          TextDecoration.underline,
      decorationColor: Colors.white,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(
            text:
                "By continuing, you agree to YCGMS365 app's ",
          ),
          TextSpan(
            text:
                "Terms & Conditions",
            style: linkStyle,
            recognizer:
                termsRecognizer,
          ),
          const TextSpan(
            text: " and ",
          ),
          TextSpan(
            text:
                "Privacy Policy",
            style: linkStyle,
            recognizer:
                privacyRecognizer,
          ),
        ],
      ),
      textAlign:
          TextAlign.center,
    );
  }
}
