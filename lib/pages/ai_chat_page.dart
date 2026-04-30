import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../controller/chat_controller.dart';
import '../helpers/route_helper.dart';
import '../model/doctor_chat_res_model.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../widget/loading_indicator_widget.dart';
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {

  final ChatController controller = Get.put(ChatController(),permanent: true);
  final TextEditingController input = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    // TODO: implement initState
    _speech = stt.SpeechToText();
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.bgColor, // WhatsApp bg
      appBar:
      AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, //change your color here
        ),
        elevation: 0,
        backgroundColor:ColorResources.appBarColor ,
        title: Text("ai_health_assistant".tr,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400
          ),
        ),
        actions: [
         Obx(()=>
             IconButton(
              onPressed: controller.isLoading.value?null: ()=>controller.clearChat(),
              icon: Icon(FontAwesomeIcons.arrowRotateRight,
              size: 18,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// CHAT LIST
          Expanded(
            child: Obx(
                  () => ListView.builder(
                    controller: controller.scrollController,
                    padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];
                  return Column(
                    crossAxisAlignment: msg.sender == 'user'
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      chatBubble(
                        message: msg.message ?? "",
                        isUser: msg.sender == 'user',
                      ),

                      /// DOCTOR SUGGESTION CARDS
                      if (msg.doctors != null)
                        Column(
                          children: msg.doctors!
                              .map((doc) => buildDoctorCard(doc))
                              .toList(),
                        ),

                      const SizedBox(height: 6),
                    ],
                  );
                },
              ),
            ),
          ),

          /// TYPING INDICATOR
          Obx(() =>controller.isLoading.value
              ?  Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "ai_typing".tr,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14, color: Colors.grey),
                ),
                ILoadingIndicatorWithTextWidget()
              ],
            ),
          )
              : const SizedBox()),

          /// INPUT BAR
    Obx(() =>  SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child:Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 10,
                      textInputAction: TextInputAction.newline,
                      enabled: !controller.isLoading.value,
                      decoration: InputDecoration(
                        hintText: "describe_health_issue".tr,
                        filled: true,
                        fillColor: ColorResources.textFiledBgColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? Colors.red
                                : ColorResources.primaryColor,
                          ),
                          onPressed: _listen,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  CircleAvatar(
                    backgroundColor: ColorResources.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        if (input.text.trim().isNotEmpty) {
                          controller.sendMessage(input.text.trim());
                          input.clear();
                          setState(() => _isListening = false);
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          ))
        ],
      ),
    );
  }

  /// DOCTOR CARD (CHAT STYLE)
  Widget buildDoctorCard(DoctorChatResModel doctor) {
    return InkWell(
      onTap: (){
        if(doctor.userId!=null){
          Get.toNamed(RouteHelper.getDoctorsDetailsPageRoute(doctId:doctor.id.toString() ));
        }

      },
      child: Container(
        margin: const EdgeInsets.only(top: 6, left: 8, right: 60),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: ColorResources.primaryColor.withOpacity(.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
              ColorResources.primaryColor.withOpacity(.1),
              backgroundImage: doctor.image != ""
                  ? NetworkImage(
                "${ApiContents.imageUrl}/${doctor.image}",
              )
                  : null,
              child: doctor.image == ""
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${doctor.name} • ${doctor.specialization}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.department,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        doctor.rating,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      const Icon(FontAwesomeIcons.briefcase,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${doctor.exYear} yrs",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children:[
                      const   Icon(FontAwesomeIcons.circleCheck,color: ColorResources.btnColorGreen,size: 15),
                      const SizedBox(width: 5),
                      Text(
                        'appointments_done'.trParams({
                          'count': '${doctor.totalAppointmentDone ?? 0}'
                        }),
                        style:const TextStyle(
                            color: ColorResources.secondaryFontColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12
                        ),)],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.clinicTitle,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "book_appointment".tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(width: 4),
                      Icon(FontAwesomeIcons.circleArrowRight,
                          size: 20, color: ColorResources.primaryColor),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }


  chatBubble( { required String message, required bool isUser}) {
    return Container(
      margin: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isUser ? 50 : 8,
        right: isUser ? 8 : 50,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
        isUser ? ColorResources.primaryColor : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
          )
        ],
      ),
      child: Text(
        message,
        style:  TextStyle(
            color:   isUser ? Colors.white : Colors.black,
            fontSize: 14),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          listenMode: stt.ListenMode.dictation,
          onResult: (result) {
            setState(() {
              input.text = result.recognizedWords;
              input.selection = TextSelection.fromPosition(
                TextPosition(offset: input.text.length),
              );
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

}


