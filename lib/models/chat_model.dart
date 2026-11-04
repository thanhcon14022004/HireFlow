class ConversationModel {
  final int conversationId;
  final int? projectId;
  final String? projectTitle;
  final int freelancerId;
  final String freelancerName;
  final int employerId;
  final String employerName;
  final String? employerCompanyName;
  final int otherPartyId;
  final String otherPartyName;
  final String otherPartyRole;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.conversationId,
    this.projectId,
    this.projectTitle,
    required this.freelancerId,
    required this.freelancerName,
    required this.employerId,
    required this.employerName,
    this.employerCompanyName,
    required this.otherPartyId,
    required this.otherPartyName,
    required this.otherPartyRole,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: json['conversationId'] ?? 0,
      projectId: json['projectId'],
      projectTitle: json['projectTitle'],
      freelancerId: json['freelancerId'] ?? 0,
      freelancerName: json['freelancerName'] ?? '',
      employerId: json['employerId'] ?? 0,
      employerName: json['employerName'] ?? '',
      employerCompanyName: json['employerCompanyName'],
      otherPartyId: json['otherPartyId'] ?? 0,
      otherPartyName: json['otherPartyName'] ?? '',
      otherPartyRole: json['otherPartyRole'] ?? '',
      lastMessage: json['lastMessage'],
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? '') ?? DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class ChatMessageModel {
  final int messageId;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String content;
  final bool isRead;
  final DateTime sentAt;
  final bool isMe;

  ChatMessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.isRead,
    required this.sentAt,
    required this.isMe,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: json['messageId'] ?? 0,
      conversationId: json['conversationId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      isRead: json['isRead'] == true,
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
      isMe: json['isMe'] == true,
    );
  }
}

