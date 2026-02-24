import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_chat_app/services/firebase_service.dart';
import 'package:ai_chat_app/l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final String characterId;
  final String characterName;

  const ChatScreen({
    super.key,
    required this.characterId,
    required this.characterName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  late String _chatId;
  int _tokenBalance = 100; // Placeholder token balance

  @override
  void initState() {
    super.initState();
    _chatId = '${_firebaseService.getCurrentUser()?.uid}_${widget.characterId}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _tokenBalance <= 0) {
      return;
    }

    final userMessage = _messageController.text;
    _messageController.clear();

    // Add user message to Firestore
    await _firebaseService.addMessage(_chatId, {
      'text': userMessage,
      'sender': 'user',
      'timestamp': FieldValue.serverTimestamp(),
      'reviewed': false,
    });

    // Simulate AI response (in production, this would call the AI API)
    await Future.delayed(const Duration(seconds: 1));

    // Add AI response to Firestore
    await _firebaseService.addMessage(_chatId, {
      'text': 'This is a simulated AI response.',
      'sender': 'ai',
      'timestamp': FieldValue.serverTimestamp(),
      'reviewed': false,
    });

    // Check whether this conversation requires review based on the user's plan.
    final uid = _firebaseService.getCurrentUser()?.uid;
    if (uid != null) {
      final plan = await _firebaseService.getUserPlan(uid);
      final reviewRequired = plan?['reviewRequired'] ?? false;
      if (reviewRequired == true) {
        // Fetch the latest AI message document to include its ID in the review task.
        final lastMessages = await FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        String? latestMessageId;
        if (lastMessages.docs.isNotEmpty) {
          final lastMessage = lastMessages.docs.first;
          latestMessageId = lastMessage.id;
        }
        // Create a review task referencing the conversation and AI message
        await _firebaseService.addReviewTask({
          'conversationId': _chatId,
          'messageId': latestMessageId,
          'userId': uid,
          'status': 'new',
          'priority': 0,
          'queueType': 'auto',
          'assignedReviewerId': null,
          'assignedBy': 'system',
          'reason': 'review_required',
        });
      }
    }

    // Deduct tokens
    setState(() {
      _tokenBalance--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.characterName),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${localizations?.tokenBalance ?? "Tokens"}: $_tokenBalance',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(localizations?.noData ?? 'No messages'),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final data = message.data() as Map<String, dynamic>;
                    final isSender = data['sender'] == 'user';

                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSender
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: localizations?.send ?? 'Send a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _tokenBalance > 0 ? _sendMessage : null,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
