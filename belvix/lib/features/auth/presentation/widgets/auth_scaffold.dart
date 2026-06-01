import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/constants/app_assets.dart';
import '../../../../app/theme/app_colors.dart';

/// Shared layout for auth screens.
///
/// Top half is a hero photo (with an optional back button); bottom half
/// is a white panel with the screen title, subtitle, and a slot for
/// arbitrary content (the form, footer, etc).
///
/// Designed to match `figma-screenshot/login/reference-login.png` while
/// staying responsive — the hero image height scales with screen size
/// and the content area becomes scrollable when the keyboard opens.
class AuthScaffold
    extends StatelessWidget {
  final String title;

  final String subtitle;

  final Widget child;

  /// When true, the panel renders an `<-` back button over the hero
  /// image. Wired to `Navigator.maybePop`.
  final bool showBackButton;

  /// Optional override of the default hero image.
  final String? heroImage;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = false,
    this.heroImage,
  });

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.of(context).size;

    // Tall hero photo that dissolves smoothly into the content; clamped
    // so small phones still leave room for the scrollable form.
    final heroHeight = (size.height *
            0.46)
        .clamp(320.0, 450.0);

    return Scaffold(
      backgroundColor: Colors.white,
      // resizeToAvoidBottomInset stays default-true so the bottom
      // panel slides when the keyboard appears; the inner
      // SingleChildScrollView handles overflow.
      body: Column(
        children: [
          _HeroImage(
            height: heroHeight,
            showBackButton:
                showBackButton,
            asset: heroImage ??
                AppAssets
                    .signInBackground,
            title: title,
          ),
          Expanded(
            child:
                _ContentPanel(
              subtitle: subtitle,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage
    extends StatelessWidget {
  final double height;

  final bool showBackButton;

  final String asset;

  final String title;

  const _HeroImage({
    required this.height,
    required this.showBackButton,
    required this.asset,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment:
                Alignment.center,
          ),
          // Progressive frosted blur: a blurred copy of the photo whose
          // visibility ramps in gradually toward the bottom (no hard
          // edge), so the lower part of the image softens smoothly.
          IgnorePointer(
            child: ShaderMask(
              shaderCallback:
                  (rect) =>
                      const LinearGradient(
                begin: Alignment
                    .topCenter,
                end: Alignment
                    .bottomCenter,
                stops: [
                  0.32,
                  0.55,
                  0.78,
                  1.0,
                ],
                colors: [
                  Colors
                      .transparent,
                  Colors.white10,
                  Colors.white,
                  Colors.white,
                ],
              ).createShader(
                        rect,
                      ),
              blendMode:
                  BlendMode.dstIn,
              child:
                  ImageFiltered(
                imageFilter:
                    ImageFilter
                        .blur(
                  sigmaX: 22,
                  sigmaY: 22,
                ),
                child:
                    Image.asset(
                  asset,
                  fit: BoxFit
                      .cover,
                  alignment:
                      Alignment
                          .center,
                ),
              ),
            ),
          ),
          // Smooth white wash that reaches SOLID white at the very bottom
          // edge, so the photo melts seamlessly into the white content
          // below — no visible seam or line.
          IgnorePointer(
            child: DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin: Alignment
                      .topCenter,
                  end: Alignment
                      .bottomCenter,
                  stops: const [
                    0.42,
                    0.66,
                    0.84,
                    1.0,
                  ],
                  colors: [
                    Colors
                        .transparent,
                    Colors.white
                        .withValues(
                      alpha: 0.18,
                    ),
                    Colors.white
                        .withValues(
                      alpha: 0.92,
                    ),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          // Title sitting on the dissolved (white) bottom of the hero.
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.w700,
                color: AppColors
                    .textPrimary,
                height: 1.2,
              ),
            ),
          ),
          if (showBackButton)
            Positioned(
              top:
                  MediaQuery.of(
                    context,
                  ).padding.top +
                      8,
              left: 12,
              child:
                  const _BackButton(),
            ),
        ],
      ),
    );
  }
}

class _BackButton
    extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white
          .withOpacity(0.95),
      shape:
          const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black
          .withOpacity(0.18),
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: () =>
            Navigator.maybePop(
          context,
        ),
        child: const SizedBox(
          height: 40,
          width: 40,
          child: Icon(
            Icons
                .arrow_back_rounded,
            color: AppColors
                .textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ContentPanel
    extends StatelessWidget {
  final String subtitle;

  final Widget child;

  const _ContentPanel({
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Plain white surface that butts straight up against the hero's
    // white-dissolved bottom edge — same colour, so there is no seam.
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets
                  .fromLTRB(
            24,
            6,
            24,
            24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                subtitle,
                style:
                    const TextStyle(
                  fontSize: 14,
                  color: AppColors
                      .textSecondary,
                  fontWeight:
                      FontWeight
                          .w500,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
