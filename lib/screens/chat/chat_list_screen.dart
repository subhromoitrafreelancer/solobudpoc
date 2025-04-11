import 'package:flutter/material.dart';
import 'package:flutter_app/components/chat/conversation_list_item.dart';
import 'package:flutter_app/models/chat_models.dart';
import 'package:flutter_app/services/chat_service.dart';
import 'package:flutter_app/utils/constants.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChatService();
  }

  Future<void> _initChatService() async {
    setState(() {
      _isLoading = true;
    });
    
    await _chatService.initialize();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToChat(BuildContext context, ChatConversation conversation) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: conversation.id,
    );
  }

  void _showCreateChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateChatBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
              context.showSnackBar('Search functionality coming soon!');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ChatConversation>>(
              stream: _chatService.conversationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                final conversations = snapshot.data ?? [];
                
                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start chatting with other travelers',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showCreateChatDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Start a Conversation'),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _initChatService,
                  child: ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return ConversationListItem(
                        conversation: conversation,
                        onTap: () => _navigateToChat(context, conversation),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChatDialog,
        child: const Icon(Icons.chat),
      ),
    );
  }
}

class _CreateChatBottomSheet extends StatefulWidget {
  const _CreateChatBottomSheet();

  @override
  State<_CreateChatBottomSheet> createState() => _CreateChatBottomSheetState();
}

class _CreateChatBottomSheetState extends State<_CreateChatBottomSheet> {
  final ChatService _chatService = ChatService();
  final TextEditingController _titleController = TextEditingController();
  ConversationType _selectedType = ConversationType.direct;
  List<String> _selectedUserIds = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await supabase
          .from('user_info')
          .select('id, full_name, avatar_url')
          .neq('id', supabase.auth.currentUser!.id)
          .order('full_name');
      
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createConversation() async {
    if (_selectedType != ConversationType.direct && _titleController.text.trim().isEmpty) {
      context.showSnackBar('Please enter a title for the conversation', isError: true);
      return;
    }
    
    if (_selectedUserIds.isEmpty) {
      context.showSnackBar('Please select at least one user', isError: true);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      String conversationId;
      
      if (_selectedType == ConversationType.direct && _selectedUserIds.length == 1) {
        // For direct messages, find or create a conversation
        conversationId = await _chatService.findOrCreateDirectConversation(_selectedUserIds.first);
      } else {
        // For group or public chats, create a new conversation
        conversationId = await _chatService.createConversation(
          title: _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : _getDefaultTitle(),
          type: _selectedType,
          participantIds: _selectedUserIds,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: conversationId,
        );
      }
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      if (mounted) {
        context.showSnackBar('Error creating conversation', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getDefaultTitle() {
    if (_selectedUserIds.length == 1) {
      final user = _users.firstWhere(
        (user) => user['id'] == _selectedUserIds.first,
        orElse: () => {'full_name': 'User'},
      );
      return user['full_name'];
    } else {
      final selectedUsers = _users
          .where((user) => _selectedUserIds.contains(user['id']))
          .map((user) => user['full_name'])
          .toList();
      
      if (selectedUsers.length <= 3) {
        return selectedUsers.join(', ');
      } else {
        return '${selectedUsers.take(2).join(', ')} and ${selectedUsers.length - 2} others';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ConversationType>(
            segments: const [
              ButtonSegment(
                value: ConversationType.direct,
                label: Text('Direct'),
                icon: Icon(Icons.person),
              ),
              ButtonSegment(
                value: ConversationType.group,
                label: Text('Group'),
                icon: Icon(Icons.group),
              ),
              ButtonSegment(
                value: ConversationType.public,
                label: Text('Public'),
                icon: Icon(Icons.public),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<ConversationType> selection) {
              setState(() {
                _selectedType = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedType != ConversationType.direct || _selectedUserIds.length > 1)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Conversation Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
          if (_selectedType != ConversationType.direct || _selectedUserIds.length > 1)
            const SizedBox(height: 16),
          const Text(
            'Select Users',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 300,
                  child: _users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isSelected = _selectedUserIds.contains(user['id']);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    if (_selectedType == ConversationType.direct && _selectedUserIds.isNotEmpty) {
                                      // For direct messages, only allow one user
                                      _selectedUserIds = [user['id']];
                                    } else {
                                      _selectedUserIds.add(user['id']);
                                    }
                                  } else {
                                    _selectedUserIds.remove(user['id']);
                                  }
                                });
                              },
                              title: Text(user['full_name']),
                              secondary: CircleAvatar(
                                backgroundImage: user['avatar_url'] != null
                                    ? NetworkImage(user['avatar_url'])
                                    : null,
                                child: user['avatar_url'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _createConversation,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Create Conversation'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
