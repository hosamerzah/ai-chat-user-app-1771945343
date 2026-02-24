import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth Methods
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
      return null;
    }
  }

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.message}');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User Management
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).set(userData);
  }

  Future<DocumentSnapshot> getUser(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserTokenBalance(String uid, int amount) async {
    await _firestore.collection('users').doc(uid).update({
      'tokenBalance': FieldValue.increment(amount),
    });
  }

  // Chat Management
  Future<void> addMessage(String chatId, Map<String, dynamic> messageData) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add(messageData);
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Character Management (User-facing: read-only)
  Stream<QuerySnapshot> getCharacters() {
    return _firestore.collection('characters').snapshots();
  }

  // Ad Management (User-facing: read-only)
  Stream<QuerySnapshot> getActiveAds() {
    return _firestore
        .collection('ad_campaigns')
        .where('enabled', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: Timestamp.now())
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
        .snapshots();
  }

  // Payment Methods (User-facing: read-only)
  Stream<QuerySnapshot> getPaymentMethods() {
    return _firestore.collection('payment_methods').snapshots();
  }
}
