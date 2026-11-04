import '../core/constants/api_constants.dart';
import '../models/chat_model.dart';
import 'api_service.dart';

class ChatService {
  static Future<List<ConversationModel>> getConversations() async {
    final res = await ApiService.get(ApiConstants.chatConversations);
    if (res is List) {
      return res.map((c) => ConversationModel.fromJson(c as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<ConversationModel> getConversation(int id) async {
    final res = await ApiService.get(ApiConstants.chatConversation(id));
    return ConversationModel.fromJson(res as Map<String, dynamic>);
  }

  static Future<List<ChatMessageModel>> getMessages(int conversationId) async {
    final res = await ApiService.get(ApiConstants.chatMessages(conversationId));
    if (res is List) {
      return res.map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<ChatMessageModel> sendMessage(int conversationId, String content) async {
    final res = await ApiService.post(
      ApiConstants.chatMessages(conversationId),
      body: {'content': content},
    );
    return ChatMessageModel.fromJson(res as Map<String, dynamic>);
  }

  static Future<ConversationModel> startConversation({
    int? projectId,
    int? employerId,
    int? freelancerId,
    String? initialMessage,
  }) async {
    final body = <String, dynamic>{};
    if (projectId != null && projectId > 0) body['projectId'] = projectId;
    if (employerId != null && employerId > 0) body['employerId'] = employerId;
    if (freelancerId != null && freelancerId > 0) body['freelancerId'] = freelancerId;
    if (initialMessage != null && initialMessage.isNotEmpty) body['initialMessage'] = initialMessage;

    final res = await ApiService.post(ApiConstants.chatStart, body: body);
    return ConversationModel.fromJson(res as Map<String, dynamic>);
  }

  static Future<int> getUnreadCount() async {
    final res = await ApiService.get(ApiConstants.chatUnreadCount);
    if (res is Map<String, dynamic>) {
      return res['unreadCount'] ?? 0;
    }
    return 0;
  }
}

