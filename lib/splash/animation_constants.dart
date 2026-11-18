import 'package:flutter/material.dart';

class SplashAnimationConstants {
  // Colors
  static const Color backgroundColor = Colors.white;
  static const Color glowColor = Color(0xFF3BA7FF);
  static const Color rippleColor = Color(0xFF4FC3F7);
  static const Color textColor = Color(0xFF222222);
  static const Color subtitleColor = Color(0xFF666666);

  // Timings
  static const Duration phase1FadeDuration = Duration(milliseconds: 300);
  static const Duration phase2BreatheDuration = Duration(milliseconds: 600);
  static const Duration phase3DropletLiftDuration = Duration(milliseconds: 150);
  static const Duration phase3DropletPauseDuration = Duration(milliseconds: 100);
  static const Duration phase3DropletFallDuration = Duration(milliseconds: 150);
  static const Duration phase3RippleDuration = Duration(milliseconds: 450);
  static const Duration phase4GlowDuration = Duration(milliseconds: 600);
  static const Duration phase5TextFadeDuration = Duration(milliseconds: 450);
  static const Duration phase5SubtitleDelay = Duration(milliseconds: 150);
  static const Duration phase8TransitionDuration = Duration(milliseconds: 650);

  // Curves
  static const Curve opacityCurve = Curves.easeOut;
  static const Curve scaleCurve = Curves.easeInOut;
  static const Curve rippleCurve = Curves.fastOutSlowIn;
  static const Curve movementCurve = Curves.easeInOutCubic;
}
