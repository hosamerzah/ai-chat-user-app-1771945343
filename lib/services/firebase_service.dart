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

  // Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Authentication Methods
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore Methods
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      print('Create user error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Update user error: $e');
    }
  }

  // Chat Methods
  Future<void> createChat(String chatId, Map<String, dynamic> chatData) async {
    try {
      await _firestore.collection('chats').doc(chatId).set(chatData);
    } catch (e) {
      print('Create chat error: $e');
    }
  }

  Future<void> addMessage(String chatId, Map<String, dynamic> messageData) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);
    } catch (e) {
      print('Add message error: $e');
    }
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Character Methods
  Future<void> createCharacter(Map<String, dynamic> characterData) async {
    try {
      await _firestore.collection('characters').add(characterData);
    } catch (e) {
      print('Create character error: $e');
    }
  }

  Stream<QuerySnapshot> getCharacters() {
    return _firestore.collection('characters').snapshots();
  }

  // Storage Methods
  /// Uploads a file to Firebase Storage and returns its public download URL.
  ///
  /// [directory] specifies the top-level folder within your storage bucket
  /// (e.g. `ad_images` or `payment_assets`). [fileName] is the final name of
  /// the file in storage. [file] is the file to upload. Throws an error if
  /// the upload fails.
  Future<String?> uploadFile(
    String directory,
    String fileName,
    io.File file,
  ) async {
    try {
      final ref = _storage.ref().child(directory).child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Upload file error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Payment Method Management
  //
  // These methods encapsulate CRUD operations for payment methods. Payment
  // methods are stored in the `payment_methods` collection. Each document may
  // include fields such as `title`, `accountNumber`, `instructions`, `enabled`,
  // `sortOrder`, a list of custom `fields`, and timestamp metadata.

  /// Adds a new payment method. Expects [data] to contain at minimum a
  /// `title`, `accountNumber`, and `enabled` flag. Additional keys (e.g.
  /// `instructions`, `sortOrder`, `fields`) are optional.
  Future<void> addPaymentMethod(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('payment_methods').add(data);
    } catch (e) {
      print('Add payment method error: $e');
    }
  }

  /// Retrieves a stream of payment methods ordered by `sortOrder`. The result
  /// includes disabled methods as well; the UI may filter them as needed.
  Stream<QuerySnapshot<Map<String, dynamic>>> getPaymentMethods() {
    return _firestore
        .collection('payment_methods')
        .orderBy('sortOrder', descending: false)
        .snapshots();
  }

  /// Streams only enabled payment methods, ordered by `sortOrder` ascending.
  ///
  /// Use this method in user-facing contexts so that disabled payment methods
  /// are not displayed. If a payment method document lacks the `enabled` field
  /// it defaults to `true` via the `isEqualTo` comparison.
  Stream<QuerySnapshot<Map<String, dynamic>>> getEnabledPaymentMethods() {
    return _firestore
        .collection('payment_methods')
        .where('enabled', isEqualTo: true)
        .orderBy('sortOrder', descending: false)
        .snapshots();
  }

  /// Updates the document with the given [id] in the `payment_methods`
  /// collection with the provided [data].
  Future<void> updatePaymentMethod(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('payment_methods').doc(id).update(data);
    } catch (e) {
      print('Update payment method error: $e');
    }
  }

  /// Deletes a payment method document by its [id].
  Future<void> deletePaymentMethod(String id) async {
    try {
      await _firestore.collection('payment_methods').doc(id).delete();
    } catch (e) {
      print('Delete payment method error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Advertisement Management
  //
  // CRUD operations for ad campaigns. Ads are stored in the `ad_campaigns`
  // collection and may include `imageUrl`, `startDate`, `endDate`, `targetUrl`,
  // `enabled`, `slotId`, and `priority` fields. Only admin users should call
  // these methods; regular users can read active ads via [getActiveAds].

  Future<void> addAd(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('ad_campaigns').add(data);
    } catch (e) {
      print('Add advertisement error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAds() {
    return _firestore.collection('ad_campaigns').snapshots();
  }

  Future<void> updateAd(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('ad_campaigns').doc(id).update(data);
    } catch (e) {
      print('Update advertisement error: $e');
    }
  }

  Future<void> deleteAd(String id) async {
    try {
      await _firestore.collection('ad_campaigns').doc(id).delete();
    } catch (e) {
      print('Delete advertisement error: $e');
    }
  }

  /// Streams only active advertisements based on the current timestamp and
  /// enabled flag. Ads must have `enabled: true`, `startDate` <= now, and
  /// `endDate` >= now.
  Stream<QuerySnapshot<Map<String, dynamic>>> getActiveAds() {
    final now = Timestamp.now();
    return _firestore
        .collection('ad_campaigns')
        .where('enabled', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThanOrEqualTo: now)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Review Task & Action Management
  //
  // A review task represents a piece of content (e.g. an AI message or
  // conversation) that requires human review. Tasks live in the
  // `review_tasks` collection and include metadata such as the associated
  // conversation/message IDs, the user who created the content, the
  // reviewer assignment, and the current status. Each task has a
  // corresponding `actions` subcollection containing an audit trail of
  // reviewer/admin actions performed on the task.

  /// Creates a new review task. The [data] map should include
  /// `conversationId`, `messageId` (optional for conversation-level tasks),
  /// `userId`, `status`, `priority`, `queueType`, `assignedReviewerId`
  /// (nullable), `assignedBy`, `reason`, and any other custom metadata.
  ///
  /// Only admins or system code should call this method. Reviewers do not
  /// create tasks; they simply act on assigned tasks.
  Future<void> addReviewTask(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('review_tasks').add({
        ...data,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Add review task error: $e');
    }
  }

  /// Retrieves a stream of review tasks that are assigned to the given
  /// [reviewerId] and are still in an active state (e.g. `assigned` or
  /// `in_review`). Reviewers should subscribe to this stream to see their
  /// pending tasks.
  Stream<QuerySnapshot<Map<String, dynamic>>> getReviewTasksForReviewer(
      String reviewerId) {
    return _firestore
        .collection('review_tasks')
        .where('assignedReviewerId', isEqualTo: reviewerId)
        .where('status', whereIn: ['assigned', 'in_review'])
        .snapshots();
  }

  /// Retrieves a stream of unassigned review tasks. Admins can subscribe
  /// to this stream to triage and assign tasks to reviewers. Unassigned
  /// tasks have a null `assignedReviewerId` and a `status` of `new` or
  /// `unassigned`.
  Stream<QuerySnapshot<Map<String, dynamic>>> getUnassignedReviewTasks() {
    return _firestore
        .collection('review_tasks')
        .where('assignedReviewerId', isNull: true)
        .where('status', whereIn: ['new', 'unassigned'])
        .snapshots();
  }

  /// Updates a review task by its [taskId] with the provided [data]. When
  /// changing the `status` or `assignedReviewerId`, this method should be
  /// called to persist the new values. The `updatedAt` field is
  /// automatically updated.
  Future<void> updateReviewTask(String taskId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('review_tasks').doc(taskId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Update review task error: $e');
    }
  }

  /// Adds a review action to the `actions` subcollection of a given
  /// [taskId]. The [action] map should contain details such as
  /// `actionType`, `performedByUid`, `performedByRole`, `timestamp`,
  /// `note`, and any diff information (e.g. `oldText`, `newText`).
  ///
  /// This creates an immutable audit record for each review event. Both
  /// reviewers and admins should use this method when they perform an
  /// action on a review task.
  Future<void> addReviewAction(String taskId, Map<String, dynamic> action) async {
    try {
      await _firestore
          .collection('review_tasks')
          .doc(taskId)
          .collection('actions')
          .add({
        ...action,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Add review action error: $e');
    }
  }

  /// Retrieves a stream of review actions for the given [taskId], ordered by
  /// timestamp ascending. This is useful for displaying the audit trail of
  /// a review task.
  Stream<QuerySnapshot<Map<String, dynamic>>> getReviewActions(String taskId) {
    return _firestore
        .collection('review_tasks')
        .doc(taskId)
        .collection('actions')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Plan Management
  //
  // Plans determine subscription-level features such as storage mode
  // (e.g. local-only, cloud-only, hybrid) and whether conversations
  // require human review. Plans live in the `plans` collection. Users
  // reference a plan via their `planId` field.

  /// Creates or updates a plan document with the given [planId] using the
  /// provided [data]. If the document does not exist, it will be created.
  /// Expected fields include `name`, `storageMode`, `reviewRequired`,
  /// `adsEnabled`, and any other plan-level settings.
  Future<void> setPlan(String planId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('plans').doc(planId).set(data);
    } catch (e) {
      print('Set plan error: $e');
    }
  }

  /// Retrieves a plan document by its [planId]. Returns null if not found.
  Future<Map<String, dynamic>?> getPlan(String planId) async {
    try {
      final doc = await _firestore.collection('plans').doc(planId).get();
      return doc.data();
    } catch (e) {
      print('Get plan error: $e');
      return null;
    }
  }

  /// Retrieves the plan data for a given user [uid], assuming that the
  /// user's document contains a `planId` field. Returns null if the user
  /// or plan is not found.
  Future<Map<String, dynamic>?> getUserPlan(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();
      final planId = userData?['planId'];
      if (planId == null) return null;
      return await getPlan(planId);
    } catch (e) {
      print('Get user plan error: $e');
      return null;
    }
  }
}
