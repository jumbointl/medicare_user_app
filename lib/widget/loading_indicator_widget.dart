import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../utilities/colors_constant.dart';


class ILoadingIndicatorWithTextWidget extends StatelessWidget {
  const ILoadingIndicatorWithTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return  Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: ColorResources.primaryColor,
          size: 40,
        ));
  }
}

class ILoadingIndicatorWidget extends StatelessWidget {
  const ILoadingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return  Center(
        child: LoadingAnimationWidget.fourRotatingDots(
          color: ColorResources.primaryColor,
          size: 50,
        ));
  }
}
class IVerticalListLongLoadingWidget extends StatefulWidget {
  const IVerticalListLongLoadingWidget({super.key});

  @override
  State<IVerticalListLongLoadingWidget> createState() => _IVerticalListLongLoadingWidgetState();
}


class _IVerticalListLongLoadingWidgetState extends State<IVerticalListLongLoadingWidget>with SingleTickerProviderStateMixin {

  AnimationController? _controller;
  Animation<Color?>?_animationOne;
  Animation<Color?>?_animationTwo;

  @override
  void dispose() {
    // TODO: implement dispose
    _controller!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _controller = AnimationController(
        duration:const  Duration(milliseconds: 1500),
        vsync: this);

    _animationOne =
        ColorTween(begin: Colors.grey, end: Colors.white).animate(_controller!);
    _animationTwo =
        ColorTween(begin: Colors.white, end: Colors.grey).animate(_controller!);
    _controller!.forward();
    _controller!.addListener(() {
      if (_controller!.status == AnimationStatus.completed) {
        _controller!.reverse();
      } else if (_controller!.status == AnimationStatus.dismissed) {
        _controller!.forward();
      }
      setState(() {

      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
              colors: [_animationOne!.value!, _animationTwo!.value!])
              .createShader(rect);
        }, child:
      SingleChildScrollView(
        child: Column(
          children: [
            _verticalBox(),
            const SizedBox(height: 8),
            _verticalBox(),
            const SizedBox(height: 8),
            _verticalBox(),
            const SizedBox(height: 8),
            _verticalBox(),
            const SizedBox(height: 8),
            _verticalBox(),
            const SizedBox(height: 8),
            _verticalBox(),
            const SizedBox(height: 8),
            _verticalBox(),
            const SizedBox(height: 8),
            _verticalBox(),
            const SizedBox(height: 8),
            _verticalBox(),
          ],
        ),
      ),
      ),
    );
  }
  _verticalBox(){
    return  Row(
      children: [
        Container(
          height: 90,
          width: 110,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 15,
                width: 50,
                color: Colors.white,),
              const SizedBox(height:8),
              Container(
                height: 15,
                width: 100,
                color: Colors.white,),
              const SizedBox(height:8),
              Container(
                height: 15,
                width: 150,
                color: Colors.white,)

            ],
          ),
        ),

      ],
    );
  }
}
class ILoadingIndicatorWidgetWhite extends StatelessWidget {
  const ILoadingIndicatorWidgetWhite({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 20.0,
        width: 20.0,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}


