import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicare_user_app/model/chat_message_model.dart';
import 'package:medicare_user_app/model/doctor_chat_res_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_chat_service.dart';

class ChatController extends GetxController {

  /// CHAT MESSAGES
  RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;

  /// LOADING STATE
  RxBool isLoading = false.obs;

  /// SCROLL CONTROLLER
  final ScrollController scrollController = ScrollController();

  /// SESSION & CONTEXT
  String? sessionId;


  @override
  void onInit() {
    super.onInit();
      getAdnSetData();
    /// AUTO SCROLL WHEN MESSAGE LIST UPDATES
    ever(messages, (_) => _scrollToBottom());
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// AUTO SCROLL FUNCTION
  void _scrollToBottom() {
    if (!scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// SEND MESSAGE
  Future<void> sendMessage(String text) async {

    if (text.trim().isEmpty || isLoading.value) return;
    /// 1️⃣ USER MESSAGE
    messages.add(
      ChatMessageModel(
        sender: 'user',
        message: text.trim(),
      ),
    );

    isLoading.value = true;

    try {
      /// 2️⃣ AI API CALL
      final res = await AiChatService.sendMessage(
        message: text,
        sessionId: sessionId,
      );

      if (res == null) {
        throw Exception("Null AI response");
      }
      /// SAVE SESSION ID
      sessionId = res['session_id'];

      /// PARSE DOCTORS (IF ANY)
      List<DoctorChatResModel> doctors = [];
      if (
          res['doctors'] != null &&
          res['doctors'] is List) {
        doctors = (res['doctors'] as List)
            .map((d) => DoctorChatResModel.fromJson(d))
            .toList();
      }

      /// 3️⃣ AI MESSAGE
      messages.add(
        ChatMessageModel(
          sender: 'ai',
          message: res['reply'] ?? '',
          doctors: doctors.isEmpty ? null : doctors,
        ),
      );

      if(res['show_doctors']==true){
        if(doctors.isEmpty){
          /// ADDITIONAL MESSAGE IF DOCTORS ARE RECOMMENDED
          messages.add(
            ChatMessageModel(
              sender: 'ai',
              message: "no_doctors_found".tr,
            ),
          );
        }
      }


    } catch (e) {
      /// ERROR MESSAGE
      messages.add(
        ChatMessageModel(
          sender: 'ai',
          message: "something_went_wrong".tr,
        ),
      );
    } finally {

      isLoading.value = false;
    }
  }
  clearChat(){
    messages.clear();
    sessionId=null;
    getAdnSetData();
  }

  void getAdnSetData()async {

    isLoading.value = true;
    SharedPreferences sharedPreferences=await SharedPreferences.getInstance();
    final cityId=sharedPreferences.getString("city")??"";
    messages.add( ChatMessageModel(
      sender: 'ai',
      message: "into_chat_placeholder".tr,
    )
    );
    messages.add( ChatMessageModel(
      sender: 'ai',
      message: "into_chat_placeholder_2".trParams({"city":cityId}),
    )
    );
    isLoading.value = false;
  }
}
