class DocumentModel {
  final int documentId;
  final String originalFileName;
  final String contentType;
  final int fileSize;
  final bool isDefault;
  final DateTime uploadedAt;

  DocumentModel({
    required this.documentId,
    required this.originalFileName,
    required this.contentType,
    required this.fileSize,
    required this.isDefault,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      documentId: json['documentId'] ?? 0,
      originalFileName: json['originalFileName'] ?? '',
      contentType: json['contentType'] ?? 'application/pdf',
      fileSize: json['fileSize'] ?? 0,
      isDefault: json['isDefault'] == true,
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class CreditTransactionModel {
  final int transactionId;
  final int amount;
  final String transactionType;
  final String referenceType;
  final String? referenceId;
  final String description;
  final DateTime createdAt;

  CreditTransactionModel({
    required this.transactionId,
    required this.amount,
    required this.transactionType,
    required this.referenceType,
    this.referenceId,
    required this.description,
    required this.createdAt,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return CreditTransactionModel(
      transactionId: json['transactionId'] ?? 0,
      amount: json['amount'] ?? 0,
      transactionType: json['transactionType'] ?? '',
      referenceType: json['referenceType'] ?? '',
      referenceId: json['referenceId']?.toString(),
      description: json['description'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get isDeduction => amount < 0;
}

class CreditPackageModel {
  final int creditPackageId;
  final String name;
  final int creditAmount;
  final double priceAmount;
  final String currencyCode;
  final int displayOrder;

  CreditPackageModel({
    required this.creditPackageId,
    required this.name,
    required this.creditAmount,
    required this.priceAmount,
    required this.currencyCode,
    required this.displayOrder,
  });

  factory CreditPackageModel.fromJson(Map<String, dynamic> json) {
    return CreditPackageModel(
      creditPackageId: json['creditPackageId'] ?? 0,
      name: json['name'] ?? '',
      creditAmount: json['creditAmount'] ?? 0,
      priceAmount: json['priceAmount'] != null ? (json['priceAmount'] as num).toDouble() : 0.0,
      currencyCode: json['currencyCode'] ?? 'VND',
      displayOrder: json['displayOrder'] ?? 0,
    );
  }
}

class EmployerContactModel {
  final int employerId;
  final String? companyName;
  final String? publicDisplayName;
  final String? contactEmail;
  final String? contactPhone;
  final bool isUnlocked;

  EmployerContactModel({
    required this.employerId,
    this.companyName,
    this.publicDisplayName,
    this.contactEmail,
    this.contactPhone,
    required this.isUnlocked,
  });

  factory EmployerContactModel.fromJson(Map<String, dynamic> json) {
    return EmployerContactModel(
      employerId: json['employerId'] ?? 0,
      companyName: json['companyName'],
      publicDisplayName: json['publicDisplayName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      isUnlocked: json['isUnlocked'] == true,
    );
  }
}

class ReportModel {
  final int reportId;
  final int reporterUserId;
  final String reporterName;
  final String targetType;
  final int targetId;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedByUserName;

  ReportModel({
    required this.reportId,
    required this.reporterUserId,
    required this.reporterName,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedByUserName,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['reportId'] ?? 0,
      reporterUserId: json['reporterUserId'] ?? 0,
      reporterName: json['reporterName'] ?? '',
      targetType: json['targetType'] ?? '',
      targetId: json['targetId'] ?? 0,
      reason: json['reason'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'].toString()) : null,
      resolvedByUserName: json['resolvedByUserName'],
    );
  }
}

class AuditLogModel {
  final int auditLogId;
  final int? actorUserId;
  final String? actorUserName;
  final String action;
  final String entityType;
  final String? entityId;
  final String? details;
  final DateTime createdAt;

  AuditLogModel({
    required this.auditLogId,
    this.actorUserId,
    this.actorUserName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      auditLogId: json['auditLogId'] ?? 0,
      actorUserId: json['actorUserId'],
      actorUserName: json['actorUserName'],
      action: json['action'] ?? '',
      entityType: json['entityType'] ?? '',
      entityId: json['entityId']?.toString(),
      details: json['details'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CreditPurchaseModel {
  final int creditPurchaseId;
  final int creditPackageId;
  final String packageName;
  final int creditsPurchased;
  final double priceAmount;
  final String currencyCode;
  final String paymentProvider;
  final String? providerReference;
  final String? orderCode;
  final String? bankBrandName;
  final String? accountNumber;
  final String? accountHolder;
  final String? qrImageUrl;
  final String? deeplink;
  final String? momoPhoneNumber;
  final String status;
  final String? paymentUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int remainingSeconds;
  final DateTime? paidAt;

  CreditPurchaseModel({
    required this.creditPurchaseId,
    required this.creditPackageId,
    required this.packageName,
    required this.creditsPurchased,
    required this.priceAmount,
    required this.currencyCode,
    required this.paymentProvider,
    this.providerReference,
    this.orderCode,
    this.bankBrandName,
    this.accountNumber,
    this.accountHolder,
    this.qrImageUrl,
    this.deeplink,
    this.momoPhoneNumber,
    required this.status,
    this.paymentUrl,
    required this.createdAt,
    this.expiresAt,
    this.remainingSeconds = 120,
    this.paidAt,
  });

  factory CreditPurchaseModel.fromJson(Map<String, dynamic> json) {
    return CreditPurchaseModel(
      creditPurchaseId: json['creditPurchaseId'] ?? 0,
      creditPackageId: json['creditPackageId'] ?? 0,
      packageName: json['packageName'] ?? '',
      creditsPurchased: json['creditsPurchased'] ?? 0,
      priceAmount: json['priceAmount'] != null ? (json['priceAmount'] as num).toDouble() : 0.0,
      currencyCode: json['currencyCode'] ?? 'VND',
      paymentProvider: json['paymentProvider'] ?? 'SepPay',
      providerReference: json['providerReference'],
      orderCode: json['orderCode'] ?? json['providerReference'],
      bankBrandName: json['bankBrandName'] ?? 'ACB',
      accountNumber: json['accountNumber'] ?? '27655931',
      accountHolder: json['accountHolder'] ?? 'HA TRUNG THANH',
      qrImageUrl: json['qrImageUrl'] ?? json['paymentUrl'],
      deeplink: json['deeplink'],
      momoPhoneNumber: json['moMoPhoneNumber'] ?? json['momoPhoneNumber'],
      status: json['status'] ?? 'Pending',
      paymentUrl: json['paymentUrl'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      remainingSeconds: json['remainingSeconds'] ?? 120,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
    );
  }

  bool get isMoMo => paymentProvider.toLowerCase() == 'momo';
}

class SepPayCheckResultModel {
  final bool success;
  final String status;
  final int? creditsAdded;
  final int? newBalance;
  final String message;
  final int remainingSeconds;

  SepPayCheckResultModel({
    required this.success,
    required this.status,
    this.creditsAdded,
    this.newBalance,
    required this.message,
    required this.remainingSeconds,
  });

  factory SepPayCheckResultModel.fromJson(Map<String, dynamic> json) {
    return SepPayCheckResultModel(
      success: json['success'] == true,
      status: json['status'] ?? 'Pending',
      creditsAdded: json['creditsAdded'],
      newBalance: json['newBalance'],
      message: json['message'] ?? '',
      remainingSeconds: json['remainingSeconds'] ?? 0,
    );
  }
}

