import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tin nhắn & Trao đổi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => context.read<ChatProvider>().fetchConversations(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ChatProvider>().fetchConversations(),
        child: chat.isLoading && chat.conversations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : chat.conversations.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có cuộc trò chuyện nào',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Sau khi bạn ứng tuyển hoặc được nhà tuyển dụng liên hệ, cuộc trò chuyện trực tiếp sẽ xuất hiện tại đây.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chat.conversations.length,
                    separatorBuilder: (ctx, index) => const Divider(height: 1, indent: 72, endIndent: 16, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final conv = chat.conversations[index];
                      return _buildConversationTile(context, conv);
                    },
                  ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ConversationModel conv) {
    final isEmployer = conv.otherPartyRole.toLowerCase() == 'employer';
    final roleLabel = isEmployer ? 'Nhà tuyển dụng' : 'Ứng viên';
    final roleBg = isEmployer ? const Color(0xFFE8F8EE) : const Color(0xFFEFF6FF);
    final roleFg = isEmployer ? AppColors.primary : const Color(0xFF2563EB);
    final initial = conv.otherPartyName.isNotEmpty ? conv.otherPartyName.trim()[0].toUpperCase() : 'U';

    return InkWell(
      onTap: () async {
        final chat = context.read<ChatProvider>();
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv.conversationId,
              otherPartyName: conv.otherPartyName,
              otherPartyRole: conv.otherPartyRole,
              projectTitle: conv.projectTitle,
            ),
          ),
        );
        if (mounted) {
          chat.fetchConversations();
        }
      },
      child: Container(
        color: conv.unreadCount > 0 ? const Color(0xFFF0FDF4) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: roleBg,
                  child: Text(
                    initial,
                    style: TextStyle(fontWeight: FontWeight.bold, color: roleFg, fontSize: 18),
                  ),
                ),
                if (conv.unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        conv.unreadCount > 9 ? '9+' : conv.unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherPartyName,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: conv.unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: roleBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleFg),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(conv.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: conv.unreadCount > 0 ? AppColors.primary : const Color(0xFF94A3B8),
                          fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (conv.projectTitle != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.work_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            conv.projectTitle!,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    conv.lastMessage ?? 'Bắt đầu cuộc trò chuyện...',
                    style: TextStyle(
                      fontSize: 13,
                      color: conv.unreadCount > 0 ? AppColors.textPrimary : const Color(0xFF64748B),
                      fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}
