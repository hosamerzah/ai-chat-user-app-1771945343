import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReviewerDashboardScreen extends StatefulWidget {
  const ReviewerDashboardScreen({super.key});

  @override
  State<ReviewerDashboardScreen> createState() => _ReviewerDashboardScreenState();
}

class _ReviewerDashboardScreenState extends State<ReviewerDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _recordReviewMetric(String actionType, int lettersWritten) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final statRef = _firestore.collection('reviewer_stats').doc(user.uid);
    
    // Determine increments
    int approvedInc = actionType == 'approved' ? 1 : 0;
    int modifiedInc = actionType == 'modified' ? 1 : 0;
    int notedInc = actionType == 'noted' ? 1 : 0;

    await statRef.set({
      'email': user.email,
      'chatsApproved': FieldValue.increment(approvedInc),
      'chatsModified': FieldValue.increment(modifiedInc),
      'notesLeft': FieldValue.increment(notedInc),
      'lettersWritten': FieldValue.increment(lettersWritten),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _approveTask(DocumentSnapshot doc) async {
    final user = _auth.currentUser;
    await doc.reference.update({
      'status': 'approved',
      'reviewerId': user?.uid,
      'reviewerEmail': user?.email,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    await _recordReviewMetric('approved', 0);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat Approved!')));
  }

  Future<void> _showModifyDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final TextEditingController modifyController = TextEditingController(text: data['aiResponse'] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modify AI Response'),
        content: TextField(
          controller: modifyController,
          maxLines: 8,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newText = modifyController.text.trim();
              if (newText.isEmpty) {
                Navigator.pop(context);
                return;
              }
              final user = _auth.currentUser;
              await doc.reference.update({
                'status': 'modified',
                'modifiedResponse': newText,
                'reviewerId': user?.uid,
                'reviewerEmail': user?.email,
                'reviewedAt': FieldValue.serverTimestamp(),
              });
              await _recordReviewMetric('modified', newText.length);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat Modified!')));
              }
            },
            child: const Text('Save Modification'),
          ),
        ],
      )
    );
  }

  Future<void> _showNoteDialog(DocumentSnapshot doc) async {
    final TextEditingController noteController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave a Note'),
        content: TextField(
          controller: noteController,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Internal note for the user...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final note = noteController.text.trim();
              if (note.isEmpty) {
                Navigator.pop(context);
                return;
              }
              final user = _auth.currentUser;
              await doc.reference.update({
                'status': 'noted',
                'reviewerNote': note,
                'reviewerId': user?.uid,
                'reviewerEmail': user?.email,
                'reviewedAt': FieldValue.serverTimestamp(),
              });
              await _recordReviewMetric('noted', note.length);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note Added!')));
              }
            },
            child: const Text('Submit Note'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviewer Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('review_tasks')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Firestore composite index might be required here if we use where + orderby
            // The console will output an error link to create the index.
            if (snapshot.error.toString().contains('index')) {
               return const Center(child: Padding(
                 padding: EdgeInsets.all(16.0),
                 child: Text('Please create the Firestore Composite Index for review_tasks (status ASC, createdAt DESC).'),
               ));
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('All caught up! No pending reviews.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final doc = tasks[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final userEmail = data['userEmail'] ?? 'Unknown User';
              final characterName = data['characterName'] ?? 'Unknown Character';
              final prompt = data['prompt'] ?? '';
              final aiResponse = data['aiResponse'] ?? '';
              
              final timestamp = data['createdAt'] as Timestamp?;
              final timeStr = timestamp != null 
                  ? DateFormat('MMM d, yyyy HH:mm:ss').format(timestamp.toDate()) 
                  : 'N/A';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text(characterName), backgroundColor: Colors.purple.withAlpha(30)),
                          Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('User Prompt:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                        child: Text(prompt),
                      ),
                      const SizedBox(height: 16),
                      const Text('AI Response:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                        child: Text(aiResponse),
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Modify'),
                            onPressed: () => _showModifyDialog(doc),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.note_add, size: 18),
                            label: const Text('Note'),
                            onPressed: () => _showNoteDialog(doc),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => _approveTask(doc),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
