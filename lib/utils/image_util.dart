import 'package:flutter/material.dart';

class ImageAsset {
  static String getImagePath(String image,
          {ImageFormat imageFormat = ImageFormat.png}) =>
      'assets/data/$image.${imageFormat.value}';
}

enum ImageFormat { jpg, png, gif, webp }

extension ImageFormatExtension on ImageFormat {
  String get value => ['jpg', 'png', 'gif', 'webp'][index];
}

class LoadAssetsImage extends StatelessWidget {
  const LoadAssetsImage(this.image,
      {super.key,
      this.width,
      this.height,
      this.cacheWidth,
      this.cacheHeight,
      this.fit,
      this.format = ImageFormat.png,
      this.color,
      this.radius = 0.0,
      this.url});
  final String image;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BoxFit? fit;
  final ImageFormat format;
  final Color? color;
  final double radius;
  final String? url;
  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
              ImageAsset.getImagePath(image, imageFormat: format),
              height: height,
              width: width,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              fit: fit,
              color: color,
              gaplessPlayback: true),
        ));
  }
}
