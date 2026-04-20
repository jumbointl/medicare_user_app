class ChatMessageModel {
  final String? sender; // user | ai
  final String? message;
  final List<dynamic>? doctors;
  ChatMessageModel({
    required this.sender,
    required this.message,
    this.doctors,

  });
}
