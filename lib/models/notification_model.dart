class UserNotificationModel {
  final int notificationId;
  final String title;
  final String message;
  final String type;
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;

  UserNotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      notificationId: json['notificationId'] is int ? json['notificationId'] as int : int.tryParse(json['notificationId'].toString()) ?? 0,
      title: json['title'] as String? ?? 'Thông báo',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'ApplicationStatus',
      referenceId: json['referenceId'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

