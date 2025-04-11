import 'package:flutter/material.dart';
import 'package:flutter_app/components/chat/chat_input.dart';
import 'package:flutter_app/components/chat/chat_message_bubble.dart';
import 'package:flutter_app/models/chat_models.dart';
import 'package:flutter_app/services/chat_service.dart';
import 'package:flutter_app/utils/constants.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final _uuid = const Uuid();
  
  ChatConversation? _conversation;
  List<ChatParticipantWithProfile> _participants = [];
  Map<String, ChatParticipantWithProfile> _participantsMap = {};
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _chatService.initialize();
      
      // Load conversation details
      final conversation = await _localDb.getConversation(widget.conversationId);
      
      if (conversation != null) {
        setState(() {
          _conversation = conversation;
        });
      }
      
      // Load participants
      _participants = await _chatService.getConversationParticipants(widget.conversationId);
      
      // Create map for easy lookup
      _participantsMap = {
        for (var p in _participants) p.participant.userId: p
      };
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
      
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        context.showSnackBar('Failed to send message', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendImage(File imageFile) async {
    setState(() {
      _isSending = true;
    });
    
    try {
      final userId = supabase.auth.currentUser!.id;
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExt';
      final filePath = 'chat_attachments/$fileName';
      
      // Upload image to storage
      await supabase.storage.from('chat_attachments').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      // Get public URL
      final imageUrl = supabase.storage.from('chat_attachments').getPublicUrl(filePath);
      
      // Send message with attachment
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: '',
        attachmentUrl: imageUrl,
        attachmentType: 'image',
      );
    } catch (e) {
      debugPrint('Error sending image: $e');
      if (mounted) {
        context.showSnackBar('Failed to send image', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Participants (${_participants.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final participant = _participants[index];
                  final isCurrentUser = participant.participant.userId == supabase.auth.currentUser!.id;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: participant.avatarUrl != null
                          ? NetworkImage(participant.avatarUrl!)
                          : null,
                      child: participant.avatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      participant.fullName + (isCurrentUser ? ' (You)' : ''),
                    ),
                    subtitle: Text(
                      participant.participant.role == 'admin' ? 'Admin' : 'Member',
                    ),
                    trailing: isCurrentUser || participant.participant.role == 'admin'
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.message),
                            onPressed: () async {
                              Navigator.pop(context);
                              final conversationId = await _chatService.findOrCreateDirectConversation(
                                participant.participant.userId,
                              );
                              if (mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/chat',
                                  arguments: conversationId,
                                );
                              }
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _retryMessage(String messageId) {
    _chatService.retryMessage(messageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? const Text('Loading...')
            : Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: _conversation?.imageUrl != null
                        ? NetworkImage(_conversation!.imageUrl!)
                        : null,
                    child: _conversation?.imageUrl == null
                        ? Icon(
                            _conversation?.type == ConversationType.direct
                                ? Icons.person
                                : _conversation?.type == ConversationType.group
                                    ? Icons.group
                                    : Icons.public,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _conversation?.title ?? 'Chat',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _isLoading ? null : _showParticipants,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') {
                _chatService.leaveConversation(widget.conversationId);
                Navigator.pop(context);
              } else if (value == 'delete') {
                _chatService.deleteConversation(widget.conversationId);
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Text('Leave Conversation'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Conversation'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _chatService.getMessagesStream(widget.conversationId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      
                      final messages = snapshot.data ?? [];
                      
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text('No messages yet'),
                        );
                      }
                      
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final previousMessage = index < messages.length - 1 ? messages[index + 1] : null;
                          
                          // Determine if we should show sender info
                          final showSenderInfo = _conversation?.type != ConversationType.direct &&
                              (previousMessage == null || previousMessage.senderId != message.senderId);
                          
                          // Get sender info
                          String senderName = 'User';
                          String? senderAvatar;
                          
                          if (_participantsMap.containsKey(message.senderId)) {
                            final participant = _participantsMap[message.senderId]!;
                            senderName = participant.fullName;
                            senderAvatar = participant.avatarUrl;
                          }
                          
                          return ChatMessageBubble(
                            message: message,
                            previousMessage: previousMessage,
                            showSenderInfo: showSenderInfo,
                            senderName: senderName,
                            senderAvatar: senderAvatar,
                            onRetry: message.isFailed ? () => _retryMessage(message.id) : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                ChatInput(
                  onSendText: _sendMessage,
                  onSendImage: _sendImage,
                  isLoading: _isSending,
                ),
              ],
            ),
    );
  }
}
