// lib/model/chatbot_model.dart

class ChatbotSumberModel {
  final String id;
  final String judul;
  final String tipe;
  final String label;

  const ChatbotSumberModel({
    this.id = '',
    required this.judul,
    required this.tipe,
    required this.label,
  });

  factory ChatbotSumberModel.fromJson(Map<String, dynamic> json) {
    return ChatbotSumberModel(
      id: json['id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? (json['title']?.toString() ?? 'Dokumen Resmi'),
      tipe: json['tipe']?.toString() ?? 'panduan',
      label: json['label']?.toString() ?? (json['judul']?.toString() ?? 'Dokumen Resmi'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'tipe': tipe,
      'label': label,
    };
  }
}

class ChatbotPesanModel {
  final int id;
  final String role;
  final String pesan;
  final List<ChatbotSumberModel>? sumber;
  final bool isRefused;
  final int tokensUsed;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  const ChatbotPesanModel({
    required this.id,
    required this.role,
    required this.pesan,
    this.sumber,
    this.isRefused = false,
    this.tokensUsed = 0,
    this.metadata,
    this.createdAt,
  });

  // Alias getters for flexibility
  int get pesanId => id;
  int? get percakapanId => metadata?['percakapan_id'] is int
      ? metadata!['percakapan_id'] as int
      : int.tryParse(metadata?['percakapan_id']?.toString() ?? '');
  String get konten => pesan;
  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => role.toLowerCase() == 'assistant';
  bool get isRefusal => isRefused || metadata?['is_refusal'] == true;
  bool get isGrounded =>
      (metadata?['is_grounded'] == true) || (sumber != null && sumber!.isNotEmpty);
  bool get guardrailTriggered => metadata?['guardrail_triggered'] == true;

  factory ChatbotPesanModel.fromJson(Map<String, dynamic> json) {
    List<ChatbotSumberModel>? sources;
    if (json['sumber'] is List) {
      sources = (json['sumber'] as List)
          .map((item) => ChatbotSumberModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString());
    }

    final meta = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : <String, dynamic>{};
    if (json['percakapan_id'] != null) {
      meta['percakapan_id'] = json['percakapan_id'];
    }

    return ChatbotPesanModel(
      id: json['id'] is int
          ? json['id'] as int
          : (json['pesan_id'] is int
              ? json['pesan_id'] as int
              : int.tryParse(json['id']?.toString() ?? (json['pesan_id']?.toString() ?? '0')) ?? 0),
      role: json['role']?.toString() ?? 'assistant',
      pesan: json['pesan']?.toString() ?? (json['konten']?.toString() ?? ''),
      sumber: sources,
      isRefused: json['is_refused'] == true || json['is_refused'] == 1 || meta?['is_refusal'] == true,
      tokensUsed: json['tokens_used'] is int
          ? json['tokens_used'] as int
          : int.tryParse(json['tokens_used']?.toString() ?? '0') ?? 0,
      metadata: meta,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'pesan': pesan,
      'sumber': sumber?.map((s) => s.toJson()).toList(),
      'is_refused': isRefused,
      'tokens_used': tokensUsed,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ChatbotPercakapanModel {
  final int id;
  final int? userId;
  final String judul;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ChatbotPesanModel? pesanTerakhir;
  final List<ChatbotPesanModel> pesan;

  const ChatbotPercakapanModel({
    required this.id,
    this.userId,
    required this.judul,
    this.status = 'aktif',
    this.createdAt,
    this.updatedAt,
    this.pesanTerakhir,
    this.pesan = const [],
  });

  int get percakapanId => id;

  factory ChatbotPercakapanModel.fromJson(Map<String, dynamic> json) {
    ChatbotPesanModel? lastMsg;
    if (json['pesan_terakhir'] is Map) {
      lastMsg = ChatbotPesanModel.fromJson(Map<String, dynamic>.from(json['pesan_terakhir'] as Map));
    }

    List<ChatbotPesanModel> messages = [];
    if (json['pesan'] is List) {
      messages = (json['pesan'] as List)
          .map((item) => ChatbotPesanModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString());
    }

    DateTime? updated;
    if (json['updated_at'] != null) {
      updated = DateTime.tryParse(json['updated_at'].toString());
    }

    final convId = json['id'] is int
        ? json['id'] as int
        : (json['percakapan_id'] is int
            ? json['percakapan_id'] as int
            : int.tryParse(json['id']?.toString() ?? (json['percakapan_id']?.toString() ?? '0')) ?? 0);

    final uId = json['user_id'] is int
        ? json['user_id'] as int
        : int.tryParse(json['user_id']?.toString() ?? '');

    return ChatbotPercakapanModel(
      id: convId,
      userId: uId,
      judul: json['judul']?.toString() ?? 'Percakapan',
      status: json['status']?.toString() ?? 'aktif',
      createdAt: created,
      updatedAt: updated,
      pesanTerakhir: lastMsg,
      pesan: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'judul': judul,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'pesan_terakhir': pesanTerakhir?.toJson(),
      'pesan': pesan.map((m) => m.toJson()).toList(),
    };
  }
}
