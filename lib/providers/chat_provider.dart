import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ConversationModel> _conversations = [];
  List<ChatMessageModel> _messages = [];
  ConversationModel? _currentConversation;
  int _totalUnreadCount = 0;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  List<ConversationModel> get conversations => _conversations;
  List<ChatMessageModel> get messages => _messages;
  ConversationModel? get currentConversation => _currentConversation;
  int get totalUnreadCount => _totalUnreadCount;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<void> fetchConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _conversations = await ChatService.getConversations();
      await fetchUnreadCount();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int conversationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _messages = await ChatService.getMessages(conversationId);
      await fetchUnreadCount();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMessagesSilently(int conversationId) async {
    try {
      final updated = await ChatService.getMessages(conversationId);
      if (updated.length != _messages.length || (updated.isNotEmpty && _messages.isNotEmpty && updated.last.messageId != _messages.last.messageId)) {
        _messages = updated;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> sendMessage(int conversationId, String content) async {
    if (content.trim().isEmpty) return false;
    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newMsg = await ChatService.sendMessage(conversationId, content.trim());
      _messages.add(newMsg);

      // Update in conversation list
      final idx = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (idx != -1) {
        final old = _conversations[idx];
        _conversations[idx] = ConversationModel(
          conversationId: old.conversationId,
          projectId: old.projectId,
          projectTitle: old.projectTitle,
          freelancerId: old.freelancerId,
          freelancerName: old.freelancerName,
          employerId: old.employerId,
          employerName: old.employerName,
          employerCompanyName: old.employerCompanyName,
          otherPartyId: old.otherPartyId,
          otherPartyName: old.otherPartyName,
          otherPartyRole: old.otherPartyRole,
          lastMessage: newMsg.content,
          lastMessageAt: newMsg.sentAt,
          unreadCount: old.unreadCount,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<ConversationModel?> startConversation({
    int? projectId,
    int? employerId,
    int? freelancerId,
    String? initialMessage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final conv = await ChatService.startConversation(
        projectId: projectId,
        employerId: employerId,
        freelancerId: freelancerId,
        initialMessage: initialMessage,
      );
      _currentConversation = conv;
      await fetchConversations();
      return conv;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      _totalUnreadCount = await ChatService.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }
}

