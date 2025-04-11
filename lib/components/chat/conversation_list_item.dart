import 'package:flutter/material.dart';
import 'package:flutter_app/models/chat_models.dart';
import 'package:intl/intl.dart';

class ConversationListItem extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MM/dd/yy');
    
    String formattedTime = '';
    if (conversation.lastMessageTime != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(
        conversation.lastMessageTime!.year,
        conversation.lastMessageTime!.month,
        conversation.lastMessageTime!.day,
      );
      
      if (messageDate == today) {
        formattedTime = timeFormat.format(conversation.lastMessageTime!);
      } else {
        formattedTime = dateFormat.format(conversation.lastMessageTime!);
      }
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: conversation.imageUrl != null
            ? NetworkImage(conversation.imageUrl!)
            : null,
        child: conversation.imageUrl == null
            ? Icon(
                conversation.type == ConversationType.direct
                    ? Icons.person
                    : conversation.type == ConversationType.group
                        ? Icons.group
                        : Icons.public,
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.title,
              style: TextStyle(
                fontWeight: conversation.isUnread ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (formattedTime.isNotEmpty)
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 12,
                color: conversation.isUnread
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight: conversation.isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (conversation.type != ConversationType.direct)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: conversation.type == ConversationType.group
                    ? Colors.blue.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                conversation.type == ConversationType.group ? 'Group' : 'Public',
                style: TextStyle(
                  fontSize: 10,
                  color: conversation.type == ConversationType.group
                      ? Colors.blue.shade800
                      : Colors.green.shade800,
                ),
              ),
            ),
          Expanded(
            child: Text(
              conversation.lastMessageText ?? 'No messages yet',
              style: TextStyle(
                color: conversation.isUnread ? Colors.black : Colors.grey.shade600,
                fontWeight: conversation.isUnread ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.isUnread)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
