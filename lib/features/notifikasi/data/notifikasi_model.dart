class NotifikasiModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String? roleTarget;
  final int? referenceId;
  final String? url;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? readAt;
  final String? createdAt;
  final String timeAgo;

  NotifikasiModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.roleTarget,
    this.referenceId,
    this.url,
    this.data,
    required this.isRead,
    this.readAt,
    this.createdAt,
    required this.timeAgo,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Notifikasi ASKLIN',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      roleTarget: json['role_target'],
      referenceId: json['reference_id'] != null ? int.tryParse(json['reference_id'].toString()) : null,
      url: json['url'],
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      isRead: json['is_read'] == true,
      readAt: json['read_at'],
      createdAt: json['created_at'],
      timeAgo: json['time_ago'] ?? '',
    );
  }

  NotifikasiModel copyWith({bool? isRead}) {
    return NotifikasiModel(
      id: id,
      title: title,
      message: message,
      type: type,
      roleTarget: roleTarget,
      referenceId: referenceId,
      url: url,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt,
      createdAt: createdAt,
      timeAgo: timeAgo,
    );
  }
}
