class ChatMessageModel {
  final String? messageId;
  final String sender; // "user" or "bot"
  final String message;
  final String createdAt;

  ChatMessageModel({
    this.messageId,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: json['messageId'] as String?,
      sender: json['sender'] as String? ?? 'bot',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}