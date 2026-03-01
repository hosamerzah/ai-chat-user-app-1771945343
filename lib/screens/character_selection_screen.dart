import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_chat_user_app/services/firebase_service.dart';
import 'package:ai_chat_user_app/services/local_db_service.dart';
import 'package:ai_chat_user_app/screens/chat_screen.dart';
import 'package:ai_chat_user_app/l10n/app_localizations.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalDbService _localDbService = LocalDbService();
  bool _isCreatingSession = false;

  Future<void> _startChat(String characterId, String characterName) async {
    setState(() {
      _isCreatingSession = true;
    });

    try {
      final title = 'Chat with $characterName';
      final sessionId = await _localDbService.createSession(title, characterId);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              sessionId: sessionId,
              title: title,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error creating chat session: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Character'),
      ),
      body: _isCreatingSession
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _localDbService.getLocalCharacters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No characters found offline.'),
                  );
                }

                final characters = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final data = characters[index];
                    
                    final charId = data['id'] ?? 'unknown';
                    final name = data['name'] ?? 'Unknown Character';
                    final description = data['description'] ?? 'No description available.';
                    final isDefault = data['isDefault'] == 1;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withAlpha(isDefault ? 50 : 30),
                          child: Icon(
                            isDefault ? Icons.star_rounded : Icons.person_rounded, 
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chat_bubble_outline),
                        onTap: () => _startChat(charId, name),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
