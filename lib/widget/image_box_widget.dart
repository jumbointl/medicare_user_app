import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageBoxFillWidget extends StatelessWidget {
   final String? imageUrl;
   final BoxFit? boxFit;
  const ImageBoxFillWidget({super.key, this.imageUrl,this.boxFit});
  @override
  Widget build(BuildContext context) {
    return  CachedNetworkImage(
      fit:boxFit?? BoxFit.fill,
      height: double.infinity,
      width: double.infinity,
      imageUrl: imageUrl??"",
      imageBuilder: (context, imageProvider) =>
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit:boxFit?? BoxFit.fill,
                //colorFilter: ColorFilter.mode(Colors.red, BlendMode.colorBurn)
              ),
            ),
          ),
      placeholder: (context, url) => const Center(child: Icon(Icons.image)),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}
