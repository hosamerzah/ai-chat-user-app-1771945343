import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_chat_app/services/firebase_service.dart';
import 'package:ai_chat_app/l10n/app_localizations.dart';

class ReviewerScreen extends StatefulWidget {
  const ReviewerScreen({super.key});

  @override
  State<ReviewerScreen> createState() => _ReviewerScreenState();
}

class _ReviewerScreenState extends State<ReviewerScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  String? _currentReviewerId;

  @override
  void initState() {
    super.initState();
    // Cache the current reviewer's UID once to avoid repeated calls.
    _currentReviewerId = _firebaseService.getCurrentUser()?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.reviewer ?? 'Reviewer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              localizations?.reviews ?? 'Reviews',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Expanded(
            child: _currentReviewerId == null
                ? Center(child: Text(localizations?.noData ?? 'No pending reviews'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firebaseService.getReviewTasksForReviewer(_currentReviewerId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(localizations?.noData ?? 'No pending reviews'),
                        );
                      }

                      final tasks = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final data = task.data();
                          final conversationId = data['conversationId'] ?? '';
                          final messageId = data['messageId'] ?? '';
                          final userId = data['userId'] ?? '';
                          final reason = data['reason'] ?? '';

                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text(
                                  'Conversation: $conversationId' + (messageId != '' ? '\nMessage: $messageId' : '')),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (userId.isNotEmpty)
                                    Text('User: $userId'),
                                  if (reason.isNotEmpty)
                                    Text('Reason: $reason'),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'verify') {
                                    await _handleVerifyTask(task.id, data);
                                  } else if (value == 'modify') {
                                    await _handleModifyTask(task.id, data);
                                  } else if (value == 'reject') {
                                    await _handleRejectTask(task.id, data);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'verify',
                                    child: Text('Verify'),
                                  ),
                                  PopupMenuItem(
                                    value: 'modify',
                                    child: Text('Modify'),
                                  ),
                                  PopupMenuItem(
                                    value: 'reject',
                                    child: Text('Reject'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Handles verification of a review task. Marks the associated conversation
  /// or message as verified and records a review action.
  Future<void> _handleVerifyTask(String taskId, Map<String, dynamic> taskData) async {
    final localizations = AppLocalizations.of(context);
    final conversationId = taskData['conversationId'];
    final messageId = taskData['messageId'];

    try {
      // Update the chat or message document to reflect verification. If a
      // specific message is referenced, update its review status; otherwise
      // mark the entire conversation as reviewed.
      if (messageId != null && messageId.toString().isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(conversationId)
            .collection('messages')
            .doc(messageId)
            .update({
          'wasReviewed': true,
          'reviewStatus': 'verified',
          'reviewMetadata': {
            'reviewedByUid': _currentReviewerId,
            'reviewedByRole': 'reviewer',
            'reviewedAt': DateTime.now(),
            'modified': false,
            'reason': taskData['reason'],
          },
        });
      } else {
        await FirebaseFirestore.instance.collection('chats').doc(conversationId).update({
          'reviewed': true,
          'reviewedAt': DateTime.now(),
          'reviewedBy': _currentReviewerId,
        });
      }

      // Update the task status and record the action
      await _firebaseService.updateReviewTask(taskId, {
        'status': 'verified',
      });
      await _firebaseService.addReviewAction(taskId, {
        'actionType': 'verify',
        'performedByUid': _currentReviewerId,
        'performedByRole': 'reviewer',
        'note': 'Verified',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations?.reviewCompleted ?? 'Review completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying task: $e')),
        );
      }
    }
  }

  /// Handles modification of a review task. Prompts the reviewer for a new
  /// message text, updates the message, task status, and creates an action
  /// entry documenting the change.
  Future<void> _handleModifyTask(String taskId, Map<String, dynamic> taskData) async {
    final localizations = AppLocalizations.of(context);
    final conversationId = taskData['conversationId'];
    final messageId = taskData['messageId'];
    final oldTextController = TextEditingController();
    final newTextController = TextEditingController();

    // Load the original message text
    String? originalText;
    if (messageId != null && messageId.toString().isNotEmpty) {
      final messageDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .get();
      final messageData = messageDoc.data();
      originalText = messageData?['text'] as String?;
    }

    oldTextController.text = originalText ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations?.modify ?? 'Modify Response'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldTextController,
                decoration: InputDecoration(
                  labelText: localizations?.originalText ?? 'Original Text',
                ),
                readOnly: true,
                maxLines: null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newTextController,
                decoration: InputDecoration(
                  labelText: localizations?.newText ?? 'New Text',
                ),
                maxLines: null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newText = newTextController.text.trim();
                if (newText.isEmpty) return;

                Navigator.of(context).pop();
                try {
                  // Update the message text and review metadata
                  if (messageId != null && messageId.toString().isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(conversationId)
                        .collection('messages')
                        .doc(messageId)
                        .update({
                      'text': newText,
                      'wasReviewed': true,
                      'reviewStatus': 'corrected',
                      'reviewMetadata': {
                        'reviewedByUid': _currentReviewerId,
                        'reviewedByRole': 'reviewer',
                        'reviewedAt': DateTime.now(),
                        'modified': true,
                        'reason': taskData['reason'],
                      },
                    });
                  }

                  // Update task status and add action
                  await _firebaseService.updateReviewTask(taskId, {
                    'status': 'corrected',
                  });
                  await _firebaseService.addReviewAction(taskId, {
                    'actionType': 'modify',
                    'performedByUid': _currentReviewerId,
                    'performedByRole': 'reviewer',
                    'oldText': originalText,
                    'newText': newText,
                    'note': 'Modified response',
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations?.updateCompleted ?? 'Update completed')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error modifying task: $e')),
                    );
                  }
                }
              },
              child: Text(localizations?.save ?? 'Save'),
            ),
          ],
        );
      },
    );
  }

  /// Handles rejection of a review task. Updates the task status and
  /// optionally records a note. Rejected tasks may be escalated or closed
  /// depending on business logic.
  Future<void> _handleRejectTask(String taskId, Map<String, dynamic> taskData) async {
    final localizations = AppLocalizations.of(context);
    try {
      await _firebaseService.updateReviewTask(taskId, {
        'status': 'rejected',
      });
      await _firebaseService.addReviewAction(taskId, {
        'actionType': 'reject',
        'performedByUid': _currentReviewerId,
        'performedByRole': 'reviewer',
        'note': 'Rejected by reviewer',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations?.reviewRejected ?? 'Review rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting task: $e')),
        );
      }
    }
  }
}
