import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error }

class RemoteLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> log(
    LogLevel level, 
    String message, 
    {
      Map<String, dynamic>? details, 
      Object? error, 
      StackTrace? stackTrace
    }
  ) async {
    final userId = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email;

    try {
      if (kDebugMode) {
        print('[${level.name.toUpperCase()}] $message');
        if (error != null) print('Error: $error');
      }

      // TODO(Admin Feedback): Direct Firestore writes for telemetry disabled to save costs.
      // Doing this prevents high billing usage as we upscale users on the free tier.
      // 
      // Workarounds for production:
      // Option 1: Integrate Firebase Crashlytics (100% Free error logging)
      // Option 2: Queue logs in local SQLite and allow users to manually "Submit Bug Report"
      /*
      await _firestore.collection('debug_logs').add({
        'level': level.name,
        'message': message,
        'details': details,
        'errorMessage': error?.toString(),
        'stackTrace': stackTrace?.toString(),
        'userId': userId,
        'userEmail': email,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
      */
    } catch (e) {
      if (kDebugMode) {
        print('Failed to write local log: $e');
      }
    }
  }
}
