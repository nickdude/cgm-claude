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

    // 40% of screen height for the hero photo on standard devices,
    // clamped so small phones still leave room for the form.
    final heroHeight = (size.height *
            0.4)
        .clamp(220.0, 360.0);

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
          ),
          Expanded(
            child:
                _ContentPanel(
              title: title,
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

  const _HeroImage({
    required this.height,
    required this.showBackButton,
    required this.asset,
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
          // Subtle bottom fade into the white panel.
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
                    0.75,
                    1.0,
                  ],
                  colors: [
                    Colors
                        .transparent,
                    Colors.white
                        .withOpacity(
                      0.9,
                    ),
                  ],
                ),
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
  final String title;

  final String subtitle;

  final Widget child;

  const _ContentPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Negative top margin lifts the panel slightly into the hero so
      // the rounded corners overlap the photo edge — the figma look.
      transform:
          Matrix4.translationValues(
        0,
        -24,
        0,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets
                  .fromLTRB(
            24,
            28,
            24,
            24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight
                          .w700,
                  color: AppColors
                      .textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
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
