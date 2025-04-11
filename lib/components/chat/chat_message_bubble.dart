import 'package:flutter/material.dart';
import 'package:flutter_app/models/chat_models.dart';
import 'package:intl/intl.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ChatMessage? previousMessage;
  final bool showSenderInfo;
  final String senderName;
  final String? senderAvatar;
  final VoidCallback? onRetry;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.previousMessage,
    this.showSenderInfo = false,
    required this.senderName,
    this.senderAvatar,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.isCurrentUser;
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d');
    
    // Show date header if this is the first message or if the date is different from the previous message
    final showDateHeader = previousMessage == null || 
        !_isSameDay(previousMessage!.createdAt, message.createdAt);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDateHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dateFormat.format(message.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser && showSenderInfo)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: senderAvatar != null ? NetworkImage(senderAvatar!) : null,
                    child: senderAvatar == null ? const Icon(Icons.person, size: 16) : null,
                  ),
                ),
              Flexible(
                child: Column(
                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser && showSenderInfo)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                        child: Text(
                          senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: isCurrentUser 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.attachmentUrl != null && message.attachmentType == 'image')
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                message.attachmentUrl!,
                                width: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 200,
                                    height: 150,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 150,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(Icons.error),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (message.content.isNotEmpty)
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isCurrentUser ? Colors.white : Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeFormat.format(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 4),
                            if (message.isPending)
                              const Icon(Icons.access_time, size: 12, color: Colors.grey)
                            else if (message.isFailed)
                              GestureDetector(
                                onTap: onRetry,
                                child: const Icon(Icons.error_outline, size: 12, color: Colors.red),
                              )
                            else if (message.isRead)
                              const Icon(Icons.done_all, size: 12, color: Colors.blue)
                            else
                              const Icon(Icons.done, size: 12, color: Colors.grey),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}
