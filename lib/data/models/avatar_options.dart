import 'dart:math';
import 'package:flutter/material.dart';

class AvatarOptions {
  final String seed;
  final String backgroundColor;
  final String shapeColor;
  final String flip; // 'none', 'horizontal', 'vertical', 'both'
  final int rotate; // 0 to 360
  final int scale; // 50 to 200

  const AvatarOptions({
    required this.seed,
    this.backgroundColor = 'ffde00',
    this.shapeColor = '1976d2',
    this.flip = 'none',
    this.rotate = 0,
    this.scale = 100,
  });

  factory AvatarOptions.defaultForUser(String userId) {
    final cleanSeed = userId.isNotEmpty ? userId : 'h2o_user_${DateTime.now().millisecondsSinceEpoch}';
    return AvatarOptions(
      seed: cleanSeed,
      backgroundColor: 'ffde00',
      shapeColor: '1976d2',
      flip: 'none',
      rotate: 0,
      scale: 100,
    );
  }

  factory AvatarOptions.fromJson(Map<String, dynamic> json, String fallbackUserId) {
    return AvatarOptions(
      seed: (json['avatar_seed'] as String?) ?? fallbackUserId,
      backgroundColor: (json['avatar_background_color'] as String?)?.replaceAll('#', '').toLowerCase() ?? 'ffde00',
      shapeColor: (json['avatar_shape_color'] as String?)?.replaceAll('#', '').toLowerCase() ?? '1976d2',
      flip: (json['avatar_flip'] as String?) ?? 'none',
      rotate: (json['avatar_rotate'] as int?) ?? 0,
      scale: (json['avatar_scale'] as int?) ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar_seed': seed,
      'avatar_background_color': backgroundColor.replaceAll('#', '').toLowerCase(),
      'avatar_shape_color': shapeColor.replaceAll('#', '').toLowerCase(),
      'avatar_flip': flip,
      'avatar_rotate': rotate,
      'avatar_scale': scale,
    };
  }

  String toUrl() {
    final cleanBg = backgroundColor.replaceAll('#', '').toLowerCase();
    final cleanShape = shapeColor.replaceAll('#', '').toLowerCase();

    final params = <String, String>{
      'seed': seed.isEmpty ? 'h2o_user' : seed,
      if (cleanBg.isNotEmpty) 'backgroundColor': cleanBg,
      if (cleanShape.isNotEmpty) 'shapeColor': cleanShape,
      if (flip != 'none') 'flip': 'true',
      if (rotate != 0) 'rotate': rotate.toString(),
      if (scale != 100) 'scale': scale.toString(),
    };
    final query = Uri(queryParameters: params).query;
    return 'https://api.dicebear.com/10.x/thumbs/png?$query';
  }

  /// Builds high-performance Flutter widget using PNG network image
  Widget buildWidget({double size = 180}) {
    final cleanBg = backgroundColor.replaceAll('#', '').toLowerCase();
    final cleanShape = shapeColor.replaceAll('#', '').toLowerCase();
    final cleanSeed = seed.isEmpty ? 'h2o_user' : seed;

    final baseUrl = 'https://api.dicebear.com/10.x/thumbs/png?seed=${Uri.encodeComponent(cleanSeed)}&backgroundColor=$cleanBg&shapeColor=$cleanShape';

    double scaleX = (flip == 'horizontal' || flip == 'both') ? -1.0 : 1.0;
    double scaleY = (flip == 'vertical' || flip == 'both') ? -1.0 : 1.0;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
      child: Transform.rotate(
        angle: rotate * pi / 180.0,
        child: Transform.scale(
          scale: scale / 100.0,
          child: Image.network(
            baseUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.person, size: size * 0.5, color: Colors.grey);
            },
          ),
        ),
      ),
    );
  }

  AvatarOptions copyWith({
    String? seed,
    String? backgroundColor,
    String? shapeColor,
    String? flip,
    int? rotate,
    int? scale,
  }) {
    return AvatarOptions(
      seed: seed ?? this.seed,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      shapeColor: shapeColor ?? this.shapeColor,
      flip: flip ?? this.flip,
      rotate: rotate ?? this.rotate,
      scale: scale ?? this.scale,
    );
  }
}
