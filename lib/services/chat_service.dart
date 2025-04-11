import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/models/chat_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/services/local_database_service.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final _uuid = const Uuid();
  
  bool _isInitialized = false;
  bool _isOnline = false;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _conversationSubscription;
  
  // Stream controllers
  final _conversationsController = StreamController<List<ChatConversation>>.broadcast();
  Stream<List<ChatConversation>> get conversationsStream => _conversationsController.stream;
  
  final _messagesControllers = <String, StreamController<List<ChatMessage>>>{};
  
  // Initialize the chat service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      // If we just came online, sync data
      if (!wasOnline && _isOnline) {
        _syncData();
      }
    });
    
    // Subscribe to real-time updates if online
    if (_isOnline) {
      _subscribeToRealtimeUpdates();
    }
    
    // Load initial conversations
    _loadConversations();
    
    _isInitialized = true;
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
    _messageSubscription?.cancel();
    _conversationSubscription?.cancel();
    _conversationsController.close();
    
    for (final controller in _messagesControllers.values) {
      controller.close();
    }
    _messagesControllers.clear();
  }
  
  // Load conversations from local database
  Future<void> _loadConversations() async {
    try {
      final conversations = await _localDb.getConversations();
      _conversationsController.add(conversations);
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }
  
  // Get stream for messages in a conversation
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    if (!_messagesControllers.containsKey(conversationId)) {
      _messagesControllers[conversationId] = StreamController<List<ChatMessage>>.broadcast();
      _loadMessages(conversationId);
    }
    return _messagesControllers[conversationId]!.stream;
  }
  
  // Load messages for a conversation from local database
  Future<void> _loadMessages(String conversationId) async {
    try {
      final messages = await _localDb.getMessages(conversationId);
      if (_messagesControllers.containsKey(conversationId)) {
        _messagesControllers[conversationId]!.add(messages);
      }
      
      // Mark messages as read
      await _localDb.markMessagesAsRead(conversationId);
      
      // Update conversation unread status
      final conversation = await _localDb.getConversation(conversationId);
      if (conversation != null && conversation.isUnread) {
        await _localDb.updateConversation(
          conversation.copyWith(isUnread: false)
        );
        _loadConversations(); // Refresh conversations list
      }
      
      // Sync read status with server if online
      if (_isOnline) {
        try {
          await supabase
              .from('chat_messages')
              .update({'is_read': true})
              .eq('conversation_id', conversationId)
              .eq('is_read', false)
              .neq('sender_id', supabase.auth.currentUser!.id);
        } catch (e) {
          debugPrint('Error syncing read status: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }
  
  // Subscribe to real-time updates
  void _subscribeToRealtimeUpdates() {
    // Subscribe to new messages
    _messageSubscription = supabase
        .channel('public:chat_messages')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'chat_messages',
          ),
          (payload, [ref]) {
            _handleNewMessage(payload);
          },
        )
        .subscribe();
    
    // Subscribe to conversation changes
    _conversationSubscription = supabase
        .channel('public:chat_conversations')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'chat_conversations',
          ),
          (payload, [ref]) {
            _handleConversationChange(payload);
          },
        )
        .subscribe();
  }
  
  // Handle new message from real-time subscription
  Future<void> _handleNewMessage(Map<String, dynamic> payload) async {
    try {
      final message = ChatMessage.fromJson(payload['new']);
      
      // Skip if this is our own message (we already added it locally)
      if (message.senderId == supabase.auth.currentUser!.id) {
        return;
      }
      
      // Save to local database
      await _localDb.insertMessage(message);
      
      // Update conversation last message
      final conversation = await _localDb.getConversation(message.conversationId);
      if (conversation != null) {
        await _localDb.updateConversation(
          conversation.copyWith(
            lastMessageText: message.content,
            lastMessageTime: message.createdAt,
            isUnread: true,
            updatedAt: DateTime.now(),
          ),
        );
      }
      
      // Update streams
      _loadConversations();
      if (_messagesControllers.containsKey(message.conversationId)) {
        _loadMessages(message.conversationId);
      }
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }
  
  // Handle conversation change from real-time subscription
  Future<void> _handleConversationChange(Map<String, dynamic> payload) async {
    try {
      if (payload['eventType'] == 'DELETE') {
        // Handle conversation deletion
        final id = payload['old']['id'];
        await _localDb.deleteConversation(id);
      } else {
        // Handle conversation insert/update
        final conversation = ChatConversation.fromJson(payload['new']);
        await _localDb.insertConversation(conversation);
      }
      
      // Update streams
      _loadConversations();
    } catch (e) {
      debugPrint('Error handling conversation change: $e');
    }
  }
  
  // Sync local data with server
  Future<void> _syncData() async {
    try {
      // Sync unsynced messages
      final unsyncedMessages = await _localDb.getUnsyncedMessages();
      for (final message in unsyncedMessages) {
        try {
          final response = await supabase
              .from('chat_messages')
              .insert(message.toJson())
              .select()
              .single();
          
          await _localDb.markAsSynced('messages', 'id', message.id);
        } catch (e) {
          debugPrint('Error syncing message: $e');
        }
      }
      
      // Sync unsynced participants
      final unsyncedParticipants = await _localDb.getUnsyncedParticipants();
      for (final participant in unsyncedParticipants) {
        try {
          await supabase
              .from('chat_participants')
              .insert(participant.toJson());
          
          await _localDb.markAsSynced(
            'participants', 
            'conversation_id', 
            participant.conversationId
          );
        } catch (e) {
          debugPrint('Error syncing participant: $e');
        }
      }
      
      // Sync unsynced conversations
      final unsyncedConversations = await _localDb.getUnsyncedConversations();
      for (final conversation in unsyncedConversations) {
        try {
          await supabase
              .from('chat_conversations')
              .insert(conversation.toJson());
          
          await _localDb.markAsSynced('conversations', 'id', conversation.id);
        } catch (e) {
          debugPrint('Error syncing conversation: $e');
        }
      }
      
      // Retry failed messages
      final pendingMessages = await _localDb.getPendingMessages();
      for (final message in pendingMessages) {
        try {
          final response = await supabase
              .from('chat_messages')
              .insert(message.toJson())
              .select()
              .single();
          
          await _localDb.updateMessage(
            message.copyWith(
              isPending: false,
              isSynced: true,
            ),
          );
        } catch (e) {
          debugPrint('Error retrying message: $e');
          await _localDb.markMessageAsFailed(message.id);
        }
      }
      
      // Fetch latest conversations from server
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('chat_conversations')
          .select('''
            *,
            chat_participants!inner(user_id)
          ''')
          .eq('chat_participants.user_id', userId)
          .order('updated_at', ascending: false);
      
      for (final item in response) {
        final conversation = ChatConversation.fromJson(item);
        await _localDb.insertConversation(conversation);
      }
      
      // Update streams
      _loadConversations();
      for (final conversationId in _messagesControllers.keys) {
        _loadMessages(conversationId);
      }
    } catch (e) {
      debugPrint('Error syncing data: $e');
    }
  }
  
  // Create a new conversation
  Future<String> createConversation({
    required String title,
    required ConversationType type,
    required List<String> participantIds,
    String? imageUrl,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    final conversationId = _uuid.v4();
    final now = DateTime.now();
    
    // Create conversation locally
    final conversation = ChatConversation(
      id: conversationId,
      title: title,
      type: type,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
    
    await _localDb.insertConversation(conversation);
    
    // Add participants
    final allParticipantIds = [...participantIds, userId];
    for (final participantId in allParticipantIds) {
      final participant = ChatParticipant(
        conversationId: conversationId,
        userId: participantId,
        role: participantId == userId ? 'admin' : 'member',
        joinedAt: now,
        isSynced: false,
      );
      
      await _localDb.insertParticipant(participant);
    }
    
    // Sync with server if online
    if (_isOnline) {
      try {
        // Create conversation
        await supabase
            .from('chat_conversations')
            .insert({
              'id': conversationId,
              'title': title,
              'type': _conversationTypeToString(type),
              'image_url': imageUrl,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            });
        
        await _localDb.markAsSynced('conversations', 'id', conversationId);
        
        // Add participants
        for (final participantId in allParticipantIds) {
          await supabase
              .from('chat_participants')
              .insert({
                'conversation_id': conversationId,
                'user_id': participantId,
                'role': participantId == userId ? 'admin' : 'member',
                'joined_at': now.toIso8601String(),
              });
        }
        
        await _localDb.markAsSynced('participants', 'conversation_id', conversationId);
      } catch (e) {
        debugPrint('Error creating conversation: $e');
      }
    }
    
    _loadConversations();
    return conversationId;
  }
  
  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    final messageId = _uuid.v4();
    final now = DateTime.now();
    
    // Create message locally
    final message = ChatMessage(
      id: messageId,
      conversationId: conversationId,
      senderId: userId,
      content: content,
      createdAt: now,
      replyToId: replyToId,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      isSynced: false,
      isPending: true,
    );
    
    await _localDb.insertMessage(message);
    
    // Update conversation last message
    final conversation = await _localDb.getConversation(conversationId);
    if (conversation != null) {
      await _localDb.updateConversation(
        conversation.copyWith(
          lastMessageText: content,
          lastMessageTime: now,
          updatedAt: now,
        ),
      );
    }
    
    // Update streams
    if (_messagesControllers.containsKey(conversationId)) {
      _loadMessages(conversationId);
    }
    _loadConversations();
    
    // Send to server if online
    if (_isOnline) {
      try {
        await supabase
            .from('chat_messages')
            .insert({
              'id': messageId,
              'conversation_id': conversationId,
              'sender_id': userId,
              'content': content,
              'created_at': now.toIso8601String(),
              'reply_to_id': replyToId,
              'attachment_url': attachmentUrl,
              'attachment_type': attachmentType,
            });
        
        // Update message status
        await _localDb.updateMessage(
          message.copyWith(
            isPending: false,
            isSynced: true,
          ),
        );
        
        // Update conversation on server
        await supabase
            .from('chat_conversations')
            .update({
              'last_message_text': content,
              'last_message_time': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .eq('id', conversationId);
        
        // Update streams
        if (_messagesControllers.containsKey(conversationId)) {
          _loadMessages(conversationId);
        }
      } catch (e) {
        debugPrint('Error sending message: $e');
        await _localDb.markMessageAsFailed(messageId);
        if (_messagesControllers.containsKey(conversationId)) {
          _loadMessages(conversationId);
        }
      }
    }
  }
  
  // Get conversation participants with profiles
  Future<List<ChatParticipantWithProfile>> getConversationParticipants(String conversationId) async {
    try {
      final participants = await _localDb.getParticipants(conversationId);
      final result = <ChatParticipantWithProfile>[];
      
      for (final participant in participants) {
        // Get user info from local cache or server
        Map<String, dynamic>? userInfo;
        
        if (_isOnline) {
          try {
            userInfo = await supabase
                .from('user_info')
                .select('full_name, avatar_url')
                .eq('id', participant.userId)
                .single();
          } catch (e) {
            debugPrint('Error fetching user info: $e');
          }
        }
        
        if (userInfo != null) {
          result.add(ChatParticipantWithProfile(
            participant: participant,
            fullName: userInfo['full_name'] ?? 'Unknown User',
            avatarUrl: userInfo['avatar_url'],
          ));
        } else {
          // Fallback if we can't get user info
          result.add(ChatParticipantWithProfile(
            participant: participant,
            fullName: 'User ${participant.userId.substring(0, 8)}',
            avatarUrl: null,
          ));
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting conversation participants: $e');
      return [];
    }
  }
  
  // Add participant to conversation
  Future<void> addParticipant(String conversationId, String userId) async {
    final now = DateTime.now();
    
    // Add participant locally
    final participant = ChatParticipant(
      conversationId: conversationId,
      userId: userId,
      role: 'member',
      joinedAt: now,
      isSynced: false,
    );
    
    await _localDb.insertParticipant(participant);
    
    // Sync with server if online
    if (_isOnline) {
      try {
        await supabase
            .from('chat_participants')
            .insert({
              'conversation_id': conversationId,
              'user_id': userId,
              'role': 'member',
              'joined_at': now.toIso8601String(),
            });
        
        await _localDb.markAsSynced('participants', 'conversation_id', conversationId);
      } catch (e) {
        debugPrint('Error adding participant: $e');
      }
    }
  }
  
  // Remove participant from conversation
  Future<void> removeParticipant(String conversationId, String userId) async {
    // Remove participant locally
    await _localDb.deleteParticipant(conversationId, userId);
    
    // Sync with server if online
    if (_isOnline) {
      try {
        await supabase
            .from('chat_participants')
            .delete()
            .eq('conversation_id', conversationId)
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('Error removing participant: $e');
      }
    }
  }
  
  // Leave conversation
  Future<void> leaveConversation(String conversationId) async {
    final userId = supabase.auth.currentUser!.id;
    await removeParticipant(conversationId, userId);
  }
  
  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    // Delete conversation locally
    await _localDb.deleteConversation(conversationId);
    
    // Update streams
    _loadConversations();
    if (_messagesControllers.containsKey(conversationId)) {
      _messagesControllers[conversationId]!.close();
      _messagesControllers.remove(conversationId);
    }
    
    // Sync with server if online
    if (_isOnline) {
      try {
        await supabase
            .from('chat_conversations')
            .delete()
            .eq('id', conversationId);
      } catch (e) {
        debugPrint('Error deleting conversation: $e');
      }
    }
  }
  
  // Retry failed message
  Future<void> retryMessage(String messageId) async {
    try {
      final db = await _localDb.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );
      
      if (maps.isNotEmpty) {
        final message = ChatMessage.fromMap(maps.first);
        
        // Mark as pending
        await _localDb.markMessageAsPending(messageId);
        
        // Update stream
        if (_messagesControllers.containsKey(message.conversationId)) {
          _loadMessages(message.conversationId);
        }
        
        // Send to server if online
        if (_isOnline) {
          try {
            await supabase
                .from('chat_messages')
                .insert(message.toJson());
            
            // Update message status
            await _localDb.updateMessage(
              message.copyWith(
                isPending: false,
                isFailed: false,
                isSynced: true,
              ),
            );
            
            // Update stream
            if (_messagesControllers.containsKey(message.conversationId)) {
              _loadMessages(message.conversationId);
            }
          } catch (e) {
            debugPrint('Error retrying message: $e');
            await _localDb.markMessageAsFailed(messageId);
            if (_messagesControllers.containsKey(message.conversationId)) {
              _loadMessages(message.conversationId);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error retrying message: $e');
    }
  }
  
  // Find or create direct conversation with user
  Future<String> findOrCreateDirectConversation(String otherUserId) async {
    final userId = supabase.auth.currentUser!.id;
    
    try {
      // Try to find existing direct conversation
      if (_isOnline) {
        final response = await supabase
            .from('chat_conversations')
            .select('''
              *,
              chat_participants!inner(user_id)
            ''')
            .eq('type', 'direct')
            .eq('chat_participants.user_id', userId);
        
        for (final item in response) {
          final conversationId = item['id'];
          
          // Check if other user is also in this conversation
          final participantsResponse = await supabase
              .from('chat_participants')
              .select()
              .eq('conversation_id', conversationId)
              .eq('user_id', otherUserId);
          
          if (participantsResponse.length > 0) {
            // Found existing conversation
            return conversationId;
          }
        }
      }
      
      // No existing conversation found, create new one
      String otherUserName = 'User';
      
      if (_isOnline) {
        try {
          final userInfo = await supabase
              .from('user_info')
              .select('full_name')
              .eq('id', otherUserId)
              .single();
          
          otherUserName = userInfo['full_name'];
        } catch (e) {
          debugPrint('Error fetching user info: $e');
        }
      }
      
      return await createConversation(
        title: otherUserName,
        type: ConversationType.direct,
        participantIds: [otherUserId],
      );
    } catch (e) {
      debugPrint('Error finding or creating direct conversation: $e');
      
      // Fallback: create new conversation
      return await createConversation(
        title: 'Chat',
        type: ConversationType.direct,
        participantIds: [otherUserId],
      );
    }
  }
  
  // Helper method to convert ConversationType to string
  String _conversationTypeToString(ConversationType type) {
    switch (type) {
      case ConversationType.direct:
        return 'direct';
      case ConversationType.group:
        return 'group';
      case ConversationType.public:
        return 'public';
    }
  }
}
