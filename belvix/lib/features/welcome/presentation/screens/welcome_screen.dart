import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_assets.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/welcome_action_panel.dart';

/// Welcome / landing screen.
///
/// Full-bleed hero photo with a primary CTA + legal copy pinned to
/// the bottom. Matches `figma-screenshot/welcome/welcome.png`.
class WelcomeScreen
    extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() =>
      _WelcomeScreenState();
}

class _WelcomeScreenState
    extends State<WelcomeScreen> {
  late final TapGestureRecognizer
      _termsRecognizer;

  late final TapGestureRecognizer
      _privacyRecognizer;

  @override
  void initState() {
    super.initState();

    _termsRecognizer =
        TapGestureRecognizer()
          ..onTap = _onTerms;

    _privacyRecognizer =
        TapGestureRecognizer()
          ..onTap = _onPrivacy;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();

    _privacyRecognizer.dispose();

    super.dispose();
  }

  void _onContinue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
    );
  }

  void _onTerms() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Terms & Conditions",
        ),
      ),
    );
  }

  void _onPrivacy() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Privacy Policy",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Transparent status & nav bars so the hero photo runs edge-to-edge.
    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value:
          const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent,
        statusBarIconBrightness:
            Brightness.light,
        systemNavigationBarColor:
            Colors.transparent,
        systemNavigationBarIconBrightness:
            Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor:
            Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1) Hero photo – fills entire screen.
            Image.asset(
              AppAssets
                  .welcomeBackground,
              fit: BoxFit.cover,
              alignment:
                  Alignment.topCenter,
            ),

            // 2) Soft bottom shade so the legal copy stays readable
            //    on any photo crop without overpowering the photo.
            const _SoftLegibilityShade(),

            // 3) Action panel pinned to the bottom safe area.
            Align(
              alignment:
                  Alignment.bottomCenter,
              child: SafeArea(
                minimum:
                    const EdgeInsets
                        .only(
                  bottom: 18,
                ),
                child:
                    WelcomeActionPanel(
                  onContinue:
                      _onContinue,
                  termsRecognizer:
                      _termsRecognizer,
                  privacyRecognizer:
                      _privacyRecognizer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftLegibilityShade
    extends StatelessWidget {
  const _SoftLegibilityShade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:
                Alignment.topCenter,
            end: Alignment
                .bottomCenter,
            stops: const [
              0.40,
              0.72,
              1.0,
            ],
            colors: [
              Colors.transparent,
              Colors.black
                  .withOpacity(0.55),
              Colors.black
                  .withOpacity(0.95),
            ],
          ),
        ),
      ),
    );
  }
}
