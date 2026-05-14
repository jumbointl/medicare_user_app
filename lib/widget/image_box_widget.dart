import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageBoxFillWidget extends StatelessWidget {
   final String? imageUrl;
   final BoxFit? boxFit;
  const ImageBoxFillWidget({super.key, this.imageUrl,this.boxFit});

  static final RegExp _invalidSegment = RegExp(r'/(null|undefined)(/|$)');

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final fit = boxFit ?? BoxFit.fill;
    final isInvalid = url.isEmpty || url.endsWith('/') || _invalidSegment.hasMatch(url);
    if (isInvalid) {
      return Image.asset('assets/icons/no-available.png', fit: fit);
    }
    return  CachedNetworkImage(
      fit: fit,
      height: double.infinity,
      width: double.infinity,
      imageUrl: url,
      imageBuilder: (context, imageProvider) =>
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: fit,
                //colorFilter: ColorFilter.mode(Colors.red, BlendMode.colorBurn)
              ),
            ),
          ),
      placeholder: (context, url) => const Center(child: Icon(Icons.image)),
      errorWidget: (context, url, error) => Image.asset(
        'assets/icons/no-available.png',
        fit: fit,
      ),
    );
  }
}
