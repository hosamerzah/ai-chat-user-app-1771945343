import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _plans = [];
  int? _selectedPlanIndex; // Track the selected plan

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load Payment Methods
      final pmSnapshot = await FirebaseFirestore.instance
          .collection('payment_methods')
          .where('enabled', isEqualTo: true)
          .get();
      
      // Load Active Plans
      final plansSnapshot = await FirebaseFirestore.instance
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .get();

      if (mounted) {
        setState(() {
          // Sort payments locally to avoid index req
          _paymentMethods = pmSnapshot.docs.map((doc) => doc.data()).toList();
          _paymentMethods.sort((a, b) => (a['sortOrder'] ?? 0).compareTo(b['sortOrder'] ?? 0));
          
          // Sort plans locally by price
          _plans = plansSnapshot.docs.map((doc) => doc.data()).toList();
          _plans.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading data: $e");
    }
  }

  Future<void> _submitUpgradeRequest() async {
    if (_selectedPlanIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a premium plan first.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to upgrade.')),
      );
      return;
    }

    final selectedPlan = _plans[_selectedPlanIndex!];

    // Show Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment Submission'),
        content: Text(
          'Have you sent the \$${selectedPlan['price']} payment using one of the methods below?\n\n'
          'If yes, we will notify the Admin to verify your transaction and credit the ${selectedPlan['tokens']} tokens to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Close dialog
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Submit Request'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('upgrade_requests').add({
          'userId': user.uid,
          'userEmail': user.email,
          'planId': selectedPlan['planId'],
          'planTitle': selectedPlan['title'],
          'requestedTokens': selectedPlan['tokens'],
          'price': selectedPlan['price'],
          'status': 'pending', // pending, approved, rejected
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted successfully! The admin will review it shortly.')),
          );
          Navigator.pop(context); // Go back to Home
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting request: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Icon(Icons.diamond_outlined, size: 64, color: theme.colorScheme.secondary),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock Premium Power',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get more tokens to continue chatting with advanced AI models.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 40),

                      // Plans Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Available Packages',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_plans.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No subscription plans available right now. Please check back later.'),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _plans.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final plan = _plans[index];
                                  final isPop = plan['isPopular'] == true;
                                  return _buildPlanCard(
                                    theme: theme,
                                    index: index,
                                    title: '${plan['title']} ${isPop ? '(Popular)' : ''}',
                                    tokens: '${plan['tokens']} Tokens',
                                    price: '\$${plan['price'].toString()}',
                                    icon: isPop ? Icons.auto_awesome_rounded : Icons.flash_on_rounded,
                                    isPopular: isPop,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Payment Methods Section
                      if (_paymentMethods.isNotEmpty) ...[
                        Text(
                          'How to Pay',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ..._paymentMethods.map((method) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Text(method['title'] ?? 'Payment Method', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (method['accountNumber'] != null && method['accountNumber'].toString().isNotEmpty)
                                  SelectableText('Account: ${method['accountNumber']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (method['instructions'] != null && method['instructions'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(method['instructions'], style: TextStyle(color: Colors.grey[600])),
                                  ),
                                
                                // Render custom fields if they exist
                                if (method['fields'] != null && (method['fields'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: (method['fields'] as List).map<Widget>((field) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: SelectableText(
                                            '${field['label']}: ${field['value']}',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )).toList(),
                        const SizedBox(height: 24),
                      ] else ...[
                        const Text('No payment methods configured by admin yet.', style: TextStyle(fontStyle: FontStyle.italic)),
                        const SizedBox(height: 24),
                      ],

                      // CTA Button
                      ElevatedButton(
                        onPressed: _submitUpgradeRequest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _selectedPlanIndex != null ? theme.colorScheme.primary : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _selectedPlanIndex != null ? 'I Have Made The Payment' : 'Select a Plan',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required ThemeData theme,
    required int index,
    required String title,
    required String tokens,
    required String price,
    required IconData icon,
    bool isPopular = false,
  }) {
    final bool isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : (isPopular ? theme.colorScheme.secondary.withAlpha(150) : theme.colorScheme.outline.withAlpha(50)),
            width: isSelected ? 3 : (isPopular ? 2 : 1),
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
              ? theme.colorScheme.primary.withAlpha(20) 
              : (isPopular ? theme.colorScheme.secondary.withAlpha(10) : Colors.transparent),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : (isPopular ? theme.colorScheme.secondary : theme.colorScheme.primary.withAlpha(30)),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isSelected || isPopular ? Colors.white : theme.colorScheme.primary),
          ),
          title: Row(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? theme.colorScheme.primary : null)),
              if (isPopular && !isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ]
            ],
          ),
          subtitle: Text(tokens, style: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primary.withAlpha(200), fontWeight: FontWeight.w600)),
          trailing: Text(
            price,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}
