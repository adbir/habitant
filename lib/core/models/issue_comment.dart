/// A comment left by staff on an [Issue].
///
/// [isPrivate] true restricts visibility to admin and maintenance staff;
/// false makes the comment visible to the tenant as well.
class IssueComment {
  final String id;
  final String authorId;

  /// Display name supplied by the server; null on older records.
  final String? authorName;
  final String body;
  final bool isPrivate;
  final DateTime createdAt;

  const IssueComment({
    required this.id,
    required this.authorId,
    this.authorName,
    required this.body,
    required this.isPrivate,
    required this.createdAt,
  });

  IssueComment copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? body,
    bool? isPrivate,
    DateTime? createdAt,
  }) {
    return IssueComment(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      body: body ?? this.body,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory IssueComment.fromJson(Map<String, dynamic> json) {
    return IssueComment(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String?,
      body: json['body'] as String,
      isPrivate: json['isPrivate'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        if (authorName != null) 'authorName': authorName,
        'body': body,
        'isPrivate': isPrivate,
        'createdAt': createdAt.toIso8601String(),
      };
}
