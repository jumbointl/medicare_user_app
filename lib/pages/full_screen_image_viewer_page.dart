import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../widget/app_bar_widget.dart';

import '../utilities/api_content.dart';

class FullScreenImageViewerPage extends StatefulWidget {
  final List images;
  final int initialIndex;
  final String? clinicName;
  const FullScreenImageViewerPage({super.key,this.clinicName,required this.images,required this.initialIndex});

  @override
  State<FullScreenImageViewerPage> createState() => _FullScreenImageViewerPageState();
}

class _FullScreenImageViewerPageState extends State<FullScreenImageViewerPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar:IAppBar.commonAppBar(title: widget.clinicName??""),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.images.length,
        builder: (context, index) {

          return PhotoViewGalleryPageOptions(
            imageProvider:  CachedNetworkImageProvider("${ApiContents.imageUrl}/${widget.images[index]['image']}",),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        scrollPhysics: BouncingScrollPhysics(),
        backgroundDecoration: BoxDecoration(color: Colors.black),
      ),
    );
  }
}