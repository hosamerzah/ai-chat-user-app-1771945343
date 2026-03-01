import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_chat_user_app/services/local_db_service.dart';
import 'package:ai_chat_user_app/services/ai_api_service.dart';
import 'package:ai_chat_user_app/l10n/app_localizations.dart';
import 'package:ai_chat_user_app/widgets/glass_container.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;
  final String title;

  const ChatScreen({
    super.key,
    required this.sessionId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LocalDbService _localDbService = LocalDbService();
  final AiApiService _aiApiService = AiApiService();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _character;
  
  // Brain Selection State
  bool _allowUserToSelectBrain = false;
  String? _selectedBrainId;
  List<Map<String, dynamic>> _availableBrains = [];

  bool _isLoading = true;
  bool _isSending = false;
  int _tokenBalance = 0;
  
  Stream<QuerySnapshot>? _reviewStream;

  @override
  void initState() {
    super.initState();
    _loadData();
    _reviewStream = FirebaseFirestore.instance
        .collection('review_tasks')
        .where('localSessionId', isEqualTo: widget.sessionId)
        .snapshots();
  }

  Future<void> _loadData() async {
    // 1. Fetch Local Chat Data & Character
    final session = await _localDbService.getSession(widget.sessionId);
    if (session != null) {
      final charId = session['characterId'] as String?;
      if (charId != null && charId.isNotEmpty) {
        _character = await _localDbService.getCharacter(charId);
      } else {
        // Fallback to default
        _character = await _localDbService.getCharacter('default_ai_assistant');
      }
    }

    final msgs = await _localDbService.getMessagesForSession(widget.sessionId);
    final tokens = await _aiApiService.getUserTokenBalance();

    // 2. Fetch App Settings for Brain Configuration
    try {
      final settingsDoc = await FirebaseFirestore.instance.collection('app_config').doc('settings').get();
      if (settingsDoc.exists) {
        final data = settingsDoc.data()!;
        _allowUserToSelectBrain = data['allowUserToSelectBrain'] ?? false;
        _selectedBrainId = data['defaultBrainId'];
      }
      
      // 3. Fetch Available Brains if needed
      final modelsSnapshot = await FirebaseFirestore.instance.collection('ai_models').where('isActive', isEqualTo: true).get();
      _availableBrains = modelsSnapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      
      // Ensure selected brain is valid, or fallback to first available
      if (_availableBrains.isNotEmpty && !_availableBrains.any((b) => b['id'] == _selectedBrainId)) {
        _selectedBrainId = _availableBrains.first['id'];
      }

    } catch (e) {
      print("Failed to load brain config: $e");
    }

    if (mounted) {
      setState(() {
        _messages = msgs;
        _tokenBalance = tokens;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty || _isSending) return;
    if (_tokenBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have no tokens left. Please contact admin.')),
      );
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();

    await _localDbService.saveMessage(
      sessionId: widget.sessionId,
      role: 'user',
      content: userMessage,
    );
    // Show user message instantly
    final updatedMsgs = await _localDbService.getMessagesForSession(widget.sessionId);
    if (mounted) setState(() { _messages = updatedMsgs; });
    _scrollToBottom();

    final aiResponse = await _aiApiService.chatWithAI(
      _selectedBrainId ?? '', 
      _character?['systemPrompt'] ?? 'You are a helpful AI assistant.', 
      userMessage
    );

    final localMessageId = await _localDbService.saveMessage(
      sessionId: widget.sessionId,
      role: 'assistant',
      content: aiResponse,
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('review_tasks').add({
          'localMessageId': localMessageId,
          'localSessionId': widget.sessionId,
          'userId': user.uid,
          'userEmail': user.email,
          'characterName': _character?['name'] ?? 'Unknown',
          'prompt': userMessage,
          'aiResponse': aiResponse,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Failed to upload review task: $e');
    }

    final finalTokens = await _aiApiService.getUserTokenBalance();
    final finalMsgs = await _localDbService.getMessagesForSession(widget.sessionId);

    if (mounted) {
      setState(() {
        _messages = finalMsgs;
        _tokenBalance = finalTokens;
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Brain Dropdown
          if (_allowUserToSelectBrain && _availableBrains.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBrainId,
                  dropdownColor: theme.colorScheme.surface,
                  icon: Icon(Icons.psychology, color: theme.colorScheme.primary),
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBrainId = newValue;
                    });
                  },
                  items: _availableBrains.map<DropdownMenuItem<String>>((Map<String, dynamic> brain) {
                    return DropdownMenuItem<String>(
                      value: brain['id'],
                      child: Text(brain['name'] ?? 'Unknown Brain'),
                    );
                  }).toList(),
                ),
              ),
            ),
          
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _tokenBalance > 10
                  ? Colors.white.withAlpha(51)
                  : Colors.red.withAlpha(64),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '$_tokenBalance tokens',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 60, color: theme.colorScheme.primary.withAlpha(100)),
                            const SizedBox(height: 16),
                            Text('Start the conversation!', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Type a message below.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: _reviewStream,
                        builder: (context, snapshot) {
                          final Map<String, Map<String, dynamic>> reviewTasks = {};
                          if (snapshot.hasData) {
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final msgId = data['localMessageId'] as String?;
                              if (msgId != null) {
                                reviewTasks[msgId] = data;
                              }
                            }
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isUser = msg['role'] == 'user';
                              final msgId = msg['id'] as String?;
                              
                              String content = msg['content'] as String;
                              String? overrideStatus;
                              String? reviewerNote;

                              if (!isUser && msgId != null && reviewTasks.containsKey(msgId)) {
                                final task = reviewTasks[msgId]!;
                                final status = task['status'];
                                if (status == 'modified') {
                                  content = task['modifiedResponse'] ?? content;
                                  overrideStatus = 'Modified by Reviewer';
                                } else if (status == 'approved') {
                                  overrideStatus = 'Approved by Reviewer';
                                } else if (status == 'noted') {
                                  reviewerNote = task['reviewerNote'];
                                }
                              }

                              return _MessageBubble(
                                content: content, 
                                isUser: isUser,
                                overrideStatus: overrideStatus,
                                reviewerNote: reviewerNote,
                              );
                            },
                          );
                        }
                      ),
          ),

          // Typing indicator
          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withAlpha(26),
                    child: Icon(Icons.smart_toy_rounded, size: 18, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('AI is typing', style: TextStyle(fontStyle: FontStyle.italic)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          height: 16,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: GlassContainer(
              blur: 20,
              opacity: theme.brightness == Brightness.dark ? 0.2 : 0.8,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withAlpha(50), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: localizations?.send ?? 'Message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedScale(
                    scale: _isSending ? 0.9 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: (_tokenBalance > 0 && !_isSending) ? _sendMessage : null,
                      backgroundColor: (_tokenBalance > 0 && !_isSending)
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      child: _isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final String? overrideStatus;
  final String? reviewerNote;

  const _MessageBubble({
    required this.content, 
    required this.isUser,
    this.overrideStatus,
    this.reviewerNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withAlpha(26),
              child: Icon(Icons.smart_toy_rounded, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overrideStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          overrideStatus!.contains('Approved') ? Icons.check_circle : Icons.edit,
                          size: 12,
                          color: overrideStatus!.contains('Approved') ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          overrideStatus!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: overrideStatus!.contains('Approved') ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withAlpha(200)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : theme.colorScheme.surface,
                    border: isUser ? null : Border.all(color: theme.colorScheme.primary.withAlpha(30), width: 1),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      if (isUser)
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (reviewerNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withAlpha(100)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note_alt, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Reviewer Note: $reviewerNote',
                              style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.person_rounded, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
