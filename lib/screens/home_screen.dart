import 'package:flutter/material.dart';
import 'package:provider/provider';
import 'package:ai_chat_user_app/l10n/app_localizations.dart';
import 'package:ai_chat_user_app/providers/theme_provider.dart';
import 'package:ai_chat_user_app/providers/locale_provider.dart';
import 'package:ai_chat_user_app/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.homeScreen ?? 'Home Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              if (localeProvider.locale.languageCode == 'en') {
                localeProvider.setLocale(const Locale('ar'));
              } else {
                localeProvider.setLocale(const Locale('en'));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _firebaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations?.welcomeToTheApp ?? 'Welcome to the AI Chat App!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/chat');
              },
              child: Text(localizations?.startChat ?? 'Start Chat'),
            ),
            const SizedBox(height: 20),
            // Display active ads
            StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getActiveAds(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text(localizations?.noActiveAds ?? 'No active advertisements.');
                }
                final ads = snapshot.data!.docs;
                return Column(
                  children: ads.map((ad) {
                    final data = ad.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(data['imageUrl'], height: 100),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            // Display payment methods
            StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getPaymentMethods(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text(localizations?.noPaymentMethodsAvailable ?? 'No payment methods available.');
                }
                final paymentMethods = snapshot.data!.docs;
                return Column(
                  children: paymentMethods.map((method) {
                    final data = method.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(data['title'] ?? 'N/A'),
                        subtitle: Text(data['accountNumber'] ?? 'N/A'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
