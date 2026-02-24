import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_chat_user_app/services/firebase_service.dart';
import 'package:ai_chat_user_app/l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final String? characterId;
  final String? characterName;

  const ChatScreen({super.key, this.characterId, this.characterName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String? _currentUserId;
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _firebaseService.getCurrentUser()?.uid;
    if (_currentUserId != null && widget.characterId != null) {
      _chatId = _getChatId(_currentUserId!, widget.characterId!);
    }
  }

  String _getChatId(String userId, String characterId) {
    // Create a unique chat ID by combining user and character IDs
    // Ensure consistency regardless of order
    if (userId.compareTo(characterId) < 0) {
      return '${userId}_${characterId}';
    } else {
      return '${characterId}_${userId}';
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final messageData = {
      'senderId': _currentUserId,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firebaseService.addMessage(_chatId!, messageData);
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.characterName ?? localizations?.chat ?? 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null
                ? Center(child: Text(localizations?.selectACharacterToChat ?? 'Select a character to chat'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.getMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text(localizations?.sayHiToStartChat ?? 'Say hi to start the chat!'));
                      }

                      final messages = snapshot.data!.docs.reversed.toList();

                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final data = message.data() as Map<String, dynamic>;
                          final isMe = data['senderId'] == _currentUserId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[100] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(data['text'] ?? ''),
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
                      hintText: localizations?.enterYourMessage ?? 'Enter your message...', 
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
