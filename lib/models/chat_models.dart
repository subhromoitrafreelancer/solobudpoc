// Models for chat functionality based on Supabase tables
import 'package:flutter_app/utils/constants.dart';

enum ConversationType { direct, group, public }

class ChatConversation {
  final String id;
  final String title;
  final String? lastMessageText;
  final DateTime? lastMessageTime;
  final ConversationType type;
  final String? imageUrl;
  final bool isUnread;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  ChatConversation({
    required this.id,
    required this.title,
    this.lastMessageText,
    this.lastMessageTime,
    required this.type,
    this.imageUrl,
    this.isUnread = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      title: json['title'] ?? 'Unnamed Conversation',
      lastMessageText: json['last_message_text'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      type: _parseConversationType(json['type'] ?? 'direct'),
      imageUrl: json['image_url'],
      isUnread: json['is_unread'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'last_message_text': lastMessageText,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'type': _conversationTypeToString(type),
      'image_url': imageUrl,
      'is_unread': isUnread,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  // For local database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'last_message_text': lastMessageText,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'type': _conversationTypeToString(type),
      'image_url': imageUrl,
      'is_unread': isUnread ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'],
      title: map['title'],
      lastMessageText: map['last_message_text'],
      lastMessageTime: map['last_message_time'] != null
          ? DateTime.parse(map['last_message_time'])
          : null,
      type: _parseConversationType(map['type']),
      imageUrl: map['image_url'],
      isUnread: map['is_unread'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
    );
  }

  static ConversationType _parseConversationType(String type) {
    switch (type.toLowerCase()) {
      case 'group':
        return ConversationType.group;
      case 'public':
        return ConversationType.public;
      case 'direct':
      default:
        return ConversationType.direct;
    }
  }

  static String _conversationTypeToString(ConversationType type) {
    switch (type) {
      case ConversationType.group:
        return 'group';
      case ConversationType.public:
        return 'public';
      case ConversationType.direct:
        return 'direct';
    }
  }

  ChatConversation copyWith({
    String? id,
    String? title,
    String? lastMessageText,
    DateTime? lastMessageTime,
    ConversationType? type,
    String? imageUrl,
    bool? isUnread,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isUnread: isUnread ?? this.isUnread,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class ChatParticipant {
  final String conversationId;
  final String userId;
  final String role; // 'admin', 'member'
  final DateTime joinedAt;
  final bool isSynced;

  ChatParticipant({
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.isSynced = true,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  // For local database
  Map<String, dynamic> toMap() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      conversationId: map['conversation_id'],
      userId: map['user_id'],
      role: map['role'],
      joinedAt: DateTime.parse(map['joined_at']),
      isSynced: map['is_synced'] == 1,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? replyToId;
  final String? attachmentUrl;
  final String? attachmentType;
  final bool isSynced;
  final bool isPending;
  final bool isFailed;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.replyToId,
    this.attachmentUrl,
    this.attachmentType,
    this.isSynced = true,
    this.isPending = false,
    this.isFailed = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      replyToId: json['reply_to_id'],
      attachmentUrl: json['attachment_url'],
      attachmentType: json['attachment_type'],
      isSynced: json['is_synced'] ?? true,
      isPending: json['is_pending'] ?? false,
      isFailed: json['is_failed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'reply_to_id': replyToId,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
      'is_synced': isSynced,
      'is_pending': isPending,
      'is_failed': isFailed,
    };
  }

  // For local database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'reply_to_id': replyToId,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
      'is_synced': isSynced ? 1 : 0,
      'is_pending': isPending ? 1 : 0,
      'is_failed': isFailed ? 1 : 0,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      conversationId: map['conversation_id'],
      senderId: map['sender_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      isRead: map['is_read'] == 1,
      replyToId: map['reply_to_id'],
      attachmentUrl: map['attachment_url'],
      attachmentType: map['attachment_type'],
      isSynced: map['is_synced'] == 1,
      isPending: map['is_pending'] == 1,
      isFailed: map['is_failed'] == 1,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    String? replyToId,
    String? attachmentUrl,
    String? attachmentType,
    bool? isSynced,
    bool? isPending,
    bool? isFailed,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      replyToId: replyToId ?? this.replyToId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      isSynced: isSynced ?? this.isSynced,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  bool get isCurrentUser => senderId == supabase.auth.currentUser?.id;
}

class ChatParticipantWithProfile {
  final ChatParticipant participant;
  final String fullName;
  final String? avatarUrl;

  ChatParticipantWithProfile({
    required this.participant,
    required this.fullName,
    this.avatarUrl,
  });
}
