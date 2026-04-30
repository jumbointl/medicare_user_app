import 'dart:async';
import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../../controller/user_controller.dart';
import '../../helpers/route_helper.dart';
import '../../services/user_service.dart';
import '../../controller/timer_controller.dart';
import '../../helpers/theme_helper.dart';
import '../../services/login_screen_service.dart';
import '../../services/user_subscription.dart';
import '../../utilities/api_content.dart';
import '../../utilities/app_constans.dart';
import '../../utilities/colors_constant.dart';
import '../../utilities/image_constants.dart';
import '../../utilities/sharedpreference_constants.dart';
import '../../widget/button_widget.dart';
import '../../widget/input_label_widget.dart';
import '../../widget/loading_Indicator_widget.dart';
import '../../widget/toast_message.dart';

class LoginPage extends StatefulWidget {
  final Function? onSuccessLogin;
  final bool openCredentialsOnStart;

  const LoginPage({super.key, required this.onSuccessLogin,
    this.openCredentialsOnStart = false,
  });
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final List _images=[];
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  bool obscureText=true;
  String phoneCode="+";
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();


  Timer? _timer;
  int _start = 60;
  bool otpSendFailed=false;
  String _verificationId = "";
  String phoneNumberWithCode="";
  bool _codeSent=false;

  final TimerController _timerController=TimerController();
  @override
  void dispose() {
    _timer?.cancel();
    _mobileController.dispose();
    _otpController.dispose();
    _fNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    phoneCode=AppConstants.defaultCountyCode;
    // _mobileController.text="1234567890";
    // _otpController.text="123456";
    _initGoogleSignIn();
    getAndSetData();

    if (widget.openCredentialsOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openBottomSheetLogin();
      });
    }
  }
  Future<void> _initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      debugPrint("GoogleSignIn initialize error: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:   _buildSlidingBody()
    );
  }
  _buildSlidingBody(){
    return  Stack(
      children: [
        _images.isEmpty?Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: ColorResources.bgColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(ImageConstants.logoImage,
                  height: 200,
                  width: 200,
                ),
                const SizedBox(height: 20),
                const Text(
                    '${AppConstants.appName} ',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 25
                    )),
              ],
            ),
          ),

        ) :  CarouselSlider.builder(
          itemCount:_images.length,
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height,
            viewportFraction: 1,
            autoPlay: _images.length==1?false:true,
            enlargeCenterPage: false,
            onPageChanged: _callbackFunction,
          ),
          itemBuilder: (ctx, index, realIdx) {
            return
              CachedNetworkImage(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.fill,
                imageUrl: _images[index],
                placeholder: (context, url) => const Center(child: Icon(Icons.image)),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
          },
        ),
        Positioned(
          bottom: 50,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                width: double.infinity,
                child: _isLoading
                    ? const ILoadingIndicatorWidget()
                    : SmallButtonsWidget(
                  title: "Continue with Google",
                  onPressed: _handleGoogleLogin,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  if (_codeSent) {
                    _openBottomSheetForOTP();
                  } else {
                    _openBottomSheetLogin();
                  }
                },
                child: Text("continue_with_phone".tr),
              ),
            ],
          ),
        )
      ],
    );
  }
  _callbackFunction(int index, CarouselPageChangedReason reason) {
    // setState(() {
    //   _currentIndex = index;
    // });
  }



  void getAndSetData() async {
    setState(() {
      _isLoading = true;
    });
    final resImage=await LoginScreenService.getData();
    if(resImage!=null){
      for(int i=0;i<resImage.length;i++){
        _images.add("${ApiContents.imageUrl}/${resImage[i].image??""}");
      }
    }

    setState(() {
      _isLoading=false;
    });
  }
  _openBottomSheetLogin(){
    return
      showModalBottomSheet(
        backgroundColor:  ColorResources.bgColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Padding(
                  padding: MediaQuery
                      .of(context)
                      .viewInsets,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SingleChildScrollView(
                      child:
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                            SizedBox(
                              width:double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLogo(),
                                  const SizedBox(height: 20),
                                  const Text(
                                      '${AppConstants.appName} ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 25
                                      )),
                                  const SizedBox(height: 10),
                                     Text('enter_credential_to_login'.tr,
                                      style:const TextStyle(
                                        color: ColorResources.secondaryFontColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            InputLabel.buildLabelBox("enter_phone_number".tr),
                            const SizedBox(height: 10),
                            Container(
                              decoration: ThemeHelper().inputBoxDecorationShaddow(),
                              child:
                              TextFormField(
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                  ],
                                  keyboardType:Platform.isIOS? const TextInputType.numberWithOptions(decimal: true, signed: true)
                                      : TextInputType.number,
                                  validator: (item) {
                                    return item!.length > 5 ? null : "enter_valid_number".tr;
                                  },
                                  controller: _mobileController,
                                  decoration: InputDecoration(
                                    prefixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 9),
                                        GestureDetector(child: Padding(
                                          padding: const EdgeInsets.only(right:8.0),
                                          child:  Text(phoneCode,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black
                                            ),),
                                        ),
                                          onTap: (){
                                            showCountryPicker(
                                              context: context,
                                              showPhoneCode: true, // optional. Shows phone code before the country name.
                                              onSelect: (Country country) {
                                                phoneCode="+${country.phoneCode}";
                                              //  print('Select country: ${country.phoneCode}');
                                                setState((){});
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    hintText: "1234567890",
                                    fillColor: Colors.white,
                                    filled: true,
                                    contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.grey)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade400)),
                                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide:const BorderSide(color: Colors.red, width: 2.0)),
                                  )
                              ),
                            ),
                            const SizedBox(height: 20),
                            SmallButtonsWidget(title: "submit".tr, onPressed:
                                (){
                              if(_formKey.currentState!.validate()){
                                Get.back();
                                phoneNumberWithCode="$phoneCode${_mobileController.text}";
                                _verifyPhone(phoneNumberWithCode);
                              }

                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
          );
        },

      ).whenComplete(() {

      });
  }
  _openBottomSheetForOTP(){
    return
      showModalBottomSheet(
        backgroundColor:  ColorResources.bgColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Padding(
                  padding: MediaQuery
                      .of(context)
                      .viewInsets,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SingleChildScrollView(
                      child:
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                            SizedBox(
                              width:double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                      'otp_sent_to'.trParams({
                                        'number': phoneNumberWithCode,
                                      }),
                                      style: const TextStyle(
                                        color: ColorResources.secondaryFontColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: ThemeHelper().inputBoxDecorationShaddow(),
                              child:
                              TextFormField(
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                  ],
                                  keyboardType:Platform.isIOS? const TextInputType.numberWithOptions(decimal: true, signed: true)
                                      : TextInputType.number,
                                  validator: (item) {
                                    return item!.length > 5 ? null : "enter_valid_otp".tr;
                                  },
                                  controller: _otpController,
                                  decoration: InputDecoration(
                                    hintText: "otp".tr,
                                    fillColor: Colors.white,
                                    filled: true,
                                    contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.grey)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade400)),
                                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide:const BorderSide(color: Colors.red, width: 2.0)),
                                  )
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(onPressed: (){
                                  Get.back();
                                  _handeCancelBtn();
                                }, child:   Text("cancel".tr,
                                style:const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15
                                ),
                                )),
                                  const SizedBox(width: 10),
                                Obx((){
                                  return  TextButton(onPressed: _timerController.timeSecond.value!=0?null:(){
                                    Get.back();
                                    _handelResendBtn();
                                  }, child:   Text(
                                    'resend_text'.trParams({
                                      'seconds': _timerController.timeSecond.toString(),
                                    }),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15
                                    ),
                                  ));
                                }

                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            SmallButtonsWidget(title: "submit".tr, onPressed:
                                (){
                              if(_formKey.currentState!.validate()){
                                Get.back();
                                _handleAuth();
                              }

                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
          );
        },

      ).whenComplete(() {

      });
  }
  _openBottomSheetForRegisterUser(){
    return
      showModalBottomSheet(
        backgroundColor:  ColorResources.bgColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Padding(
                  padding: MediaQuery
                      .of(context)
                      .viewInsets,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SingleChildScrollView(
                      child:
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                             SizedBox(
                              width:double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const  SizedBox(height: 10),
                                  Text(
                                      'register_text'.trParams({
                                        'phoneNumber': phoneNumberWithCode,
                                      }),
                                      style:const  TextStyle(
                                        color: ColorResources.secondaryFontColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: ThemeHelper().inputBoxDecorationShaddow(),
                              child: TextFormField(
                                keyboardType: TextInputType.name,
                                validator: ( item){
                                  return item!.length>=2?null:"enter_first_name".tr;
                                },
                                controller: _fNameController,
                                decoration: ThemeHelper().textInputDecoration('first_name_label'.tr),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: ThemeHelper().inputBoxDecorationShaddow(),
                              child: TextFormField(
                                keyboardType: TextInputType.name,
                                validator: ( item){
                                  return item!.length>=2?null:"enter_last_name".tr;
                                },
                                controller: _lastNameController,
                                decoration: ThemeHelper().textInputDecoration('last_name_label'.tr),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SmallButtonsWidget(title: "submit".tr, onPressed:
                                (){
                              if(_formKey.currentState!.validate()){
                                Get.back();
                                _handleRegister();
                             //   _handleAuth();
                              }

                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
          );
        },

      ).whenComplete(() {

      });
  }
  _buildLogo() {
    return SizedBox(
      height: 130,
      child: Image.asset(ImageConstants.logoImage),
    );
  }
  Future<void> _verifyPhone(phoneNo) async {

    setState(() {
      _isLoading = true;
    });
    verified(AuthCredential authResult) async {
      //AuthService()
      bool verified = await signIn(authResult).catchError((onError) {
        return false;
      });
      if (verified) {
        _timer!.cancel();
        setState(() {
          _start = 60;
          _timerController.setValue(60);
           _codeSent = false;
          _isLoading = false;
        });
        IToastMsg.showMessage("verified".tr);
      //  Signed In
        _handeCancelBtn();
        _handleLogin();
      }
    }

    verificationFailed(FirebaseAuthException authException) {

      IToastMsg.showMessage("something_went_wrong".tr);
      setState(() {
        _isLoading = false;
        otpSendFailed=true;
      });
    }

    smsSent(String? verId, [int? forceResend]) {
      _verificationId = verId!;
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
      // _otpController.clear();
      _fNameController.clear();
      _lastNameController.clear();
      _openBottomSheetForOTP();
      startTimer();
    }

    autoTimeout(String verId) {
      _verificationId = verId;
    }

    await FirebaseAuth.instance
        .verifyPhoneNumber(
        phoneNumber: phoneNo, //country code with phone number
        timeout: const Duration(seconds: 60),
        verificationCompleted: verified,
        verificationFailed: verificationFailed, //error handling function
        codeSent: smsSent,
        codeAutoRetrievalTimeout: autoTimeout)
        .catchError((e) {

    });
  }

  Future<bool> signIn(AuthCredential authCreds) async {
    bool isVerified = false;
    await FirebaseAuth.instance.signInWithCredential(authCreds).then((auth) {
      //Successfully otp verified
      isVerified = true;
    }).catchError((e) {
      isVerified = false;
    });
    return isVerified;
  }

  void startTimer() {
    const oneSec =  Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
            _timerController.setValue(_start);
          });
        }
      },
    );
  }
  _handelResendBtn(){
    if(_timer!=null){  _timer!.cancel();}
    _verifyPhone(phoneNumberWithCode);
    _timerController.setValue(60);
    _start=60;
    _codeSent=false;
  }
  _handeCancelBtn(){
    if(_timer!=null){  _timer!.cancel();}
    _timerController.setValue(60);
    _start=60;
    _codeSent=false;
  }
  _handleAuth() async {
    setState(() {
      _isLoading=true;
    });
    bool verified = await signInWithOTP(_otpController.text, _verificationId)
        .catchError((onError) {
      return false;
    });
    if (verified) {
      IToastMsg.showMessage("verified".tr);
      //  Signed In
      _handeCancelBtn();
      _handleLogin();
     // Get.to(()=>LoginPage(onSuccessLogin:widget.onSuccessLogin));
    } else {
      IToastMsg.showMessage("enter_valid_otp".tr);
      setState(() {
        _isLoading=false;
      });
      _openBottomSheetForOTP();
    }

  }
  Future<bool> signInWithOTP(smsCode, verId) async {
    AuthCredential authCreds =
    PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    bool verified = await signIn(authCreds).catchError((e) {
      return false;
    });
    return verified;
  }

  void _handleRegister() async{
    setState(() {
      _isLoading=true;
    });
      final res=await UserService.addUser(fName: _fNameController.text,
          lName: _lastNameController.text,
          isdCode: phoneCode,
          phone: _mobileController.text);
    if(res!=null){
      IToastMsg.showMessage("successfully_registered".tr);
      _handleLogin();
    }else{
      setState(() {
        _isLoading=false;
      });
      _openBottomSheetForRegisterUser();
    }

  }
  Future<void> _handleGoogleLogin() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint("Google login error: idToken is null or empty");
        IToastMsg.showMessage("something_went_wrong".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        debugPrint("Google login error: Firebase user is null");
        IToastMsg.showMessage("something_went_wrong".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final String email = (user.email ?? '').trim().toLowerCase();
      if (email.isEmpty) {
        debugPrint("Google login error: email is null or empty");
        IToastMsg.showMessage("something_went_wrong".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final res = await UserService.loginWithGoogle(
        idToken: idToken,
        email: email,
      );

      debugPrint("User Google login response: $res");

      if (res != null && res['status'] == true) {
        IToastMsg.showMessage("logged_in".tr);
        await _handleSuccessLogin(res);
        return;
      }

      IToastMsg.showMessage(
        res?['message']?.toString() ?? "google_login_failed".tr,
      );
    } catch (e) {
      debugPrint("Google login error: $e");
      IToastMsg.showMessage("something_went_wrong".tr);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLogin() async{
    setState(() {
      _isLoading=true;
    });
    final res=await UserService.loginUser(phone: _mobileController.text);
    if(res!=null){
      //    'message' => "Not Exists",
      if(res['message']=="Not Exists"){
        setState(() {
          _isLoading=false;
        });
        _openBottomSheetForRegisterUser();
      }
     else if(res['message']=="Successfully"){
      IToastMsg.showMessage("logged_in".tr);
      _handleSuccessLogin(res);
      }
    }else{
      IToastMsg.showMessage("something_went_wrong".tr);
      setState(() {
        _isLoading=false;
      });
    }

  }
  Future<void> _handleSuccessLogin(var res) async {
    setState(() {
      _isLoading = true;
    });

    final userData = res;
    final data = userData['data'] ?? {};

    SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      SharedPreferencesConstants.token,
      userData['token']?.toString() ?? '',
    );

    await preferences.setString(
      SharedPreferencesConstants.uid,
      (data['id'] ?? '').toString(),
    );

    // Backend may return patient_id either populated (this user is also a
    // patient) or null (admin/doctor accounts). Persist whatever we get so
    // downstream screens can decide what to display.
    await preferences.setString(
      SharedPreferencesConstants.patientId,
      (data['patient_id'] ?? '').toString(),
    );

    await preferences.setString(
      SharedPreferencesConstants.name,
      "${data['f_name'] ?? ''} ${data['l_name'] ?? ''}".trim(),
    );

    await preferences.setString(
      SharedPreferencesConstants.phone,
      data['phone']?.toString() ?? '',
    );

    await preferences.setBool(
      SharedPreferencesConstants.login,
      true,
    );

    debugPrint(
      'LOGIN SAVED uid="${preferences.getString(SharedPreferencesConstants.uid)}" '
      'patient_id="${preferences.getString(SharedPreferencesConstants.patientId)}"',
    );

    UserController userController = Get.find(tag: "user");
    await userController.getData();
    await UserService.updateFCM();
    await UserSubscribe.toTopi(topicName: "PATIENT_APP");

    if (widget.onSuccessLogin != null) {
      widget.onSuccessLogin!();
    } else {
      Get.back();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


}
