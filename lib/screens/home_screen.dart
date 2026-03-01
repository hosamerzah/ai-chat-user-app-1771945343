import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_chat_user_app/l10n/app_localizations.dart';
import 'package:ai_chat_user_app/providers/theme_provider.dart';
import 'package:ai_chat_user_app/providers/locale_provider.dart';
import 'package:ai_chat_user_app/services/firebase_service.dart';
import 'package:ai_chat_user_app/services/local_db_service.dart';
import 'package:ai_chat_user_app/services/ai_api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_chat_user_app/screens/character_selection_screen.dart';
import 'package:ai_chat_user_app/screens/chat_screen.dart';
import 'package:ai_chat_user_app/screens/reviewer_dashboard_screen.dart';
import 'package:ai_chat_user_app/widgets/glass_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalDbService _localDbService = LocalDbService();
  final AiApiService _aiApiService = AiApiService();

  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoadingHistory = true;
  int _tokenBalance = 0;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _localDbService.getSessions();
    final tokens = await _aiApiService.getUserTokenBalance();
    
    // Fetch User Role
    String role = 'user';
    try {
      final user = _firebaseService.getCurrentUser();
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          role = doc.data()?['role'] ?? 'user';
        }
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
    
    // Fire off background character sync
    _syncCharacters();

    if (mounted) {
      setState(() {
        _chatHistory = sessions;
        _tokenBalance = tokens;
        _userRole = role;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _syncCharacters() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('characters').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Inject ID into map before saving
        await _localDbService.saveCharacter(data);
      }
    } catch (e) {
      print("Background character sync failed: $e");
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    await _localDbService.deleteSession(sessionId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.homeScreen ?? 'Home'),
        actions: [
          // Token balance chip
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/upgrade');
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '$_tokenBalance',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (_userRole == 'reviewer' || _userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.orangeAccent),
              tooltip: 'Reviewer Dashboard',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ReviewerDashboardScreen(),
                ));
              },
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(themeProvider.currentTheme.brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Toggle theme',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'Toggle language',
            onPressed: () {
              if (localeProvider.locale.languageCode == 'en') {
                localeProvider.setLocale(const Locale('ar'));
              } else {
                localeProvider.setLocale(const Locale('en'));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await _firebaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withAlpha(50),
                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withAlpha(50), blurRadius: 100)]
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withAlpha(40),
                boxShadow: [BoxShadow(color: theme.colorScheme.secondary.withAlpha(40), blurRadius: 100)]
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Hero Banner ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  borderRadius: BorderRadius.circular(24),
                  blur: 20,
                  opacity: theme.brightness == Brightness.dark ? 0.15 : 0.6,
                  border: Border.all(color: Colors.white.withAlpha(50), width: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations?.welcomeToTheApp ?? 'Welcome back! 👋',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: (theme.brightness == Brightness.dark) ? Colors.white : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start a new conversation with an AI character.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: (theme.brightness == Brightness.dark) ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_comment_rounded),
                        label: const Text('Start New Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 4,
                          shadowColor: theme.colorScheme.primary.withAlpha(100),
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const CharacterSelectionScreen()),
                          );
                          _loadData();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // --- Recent Chats Section ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Recent Chats', style: theme.textTheme.titleLarge),
                  ],
                ),
              ),

              if (_isLoadingHistory)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_chatHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassContainer(
                    blur: 15,
                    opacity: theme.brightness == Brightness.dark ? 0.05 : 0.5,
                    border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 40, color: theme.colorScheme.primary.withAlpha(128)),
                        const SizedBox(height: 12),
                        Text(
                          'No chats yet.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Start New Chat" to begin!',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _chatHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final session = _chatHistory[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GlassContainer(
                          blur: 15,
                          opacity: theme.brightness == Brightness.dark ? 0.05 : 0.5,
                          border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withAlpha(26),
                              child: Icon(Icons.smart_toy_rounded, color: theme.colorScheme.primary),
                            ),
                            title: Text(session['title'] as String, style: theme.textTheme.titleMedium),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _deleteSession(session['id'] as String),
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  sessionId: session['id'] as String,
                                  title: session['title'] as String,
                                ),
                              ));
                              _loadData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // --- Active Ads Section ---
              StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.getActiveAds(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                  final ads = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text('Featured', style: theme.textTheme.titleLarge),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: ads.map((ad) {
                            final data = ad.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  data['imageUrl'] as String,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // --- Payment Methods Section ---
              StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.getEnabledPaymentMethods(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                  final methods = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Icon(Icons.payment_rounded, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Payment Methods', style: theme.textTheme.titleLarge),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: methods.map((m) {
                            final data = m.data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(Icons.account_balance_rounded, color: theme.colorScheme.primary),
                                title: Text(data['title'] ?? '', style: theme.textTheme.titleMedium),
                                subtitle: Text(data['accountNumber'] ?? '', style: theme.textTheme.bodyMedium),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ],
  ),
);
}
}
