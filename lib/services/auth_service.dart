import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/core/enums/user_role.dart';
import 'package:attendance/core/constants/firestore_paths.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user == null) return null;

    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(credential.user!.uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Create a new employee account using a secondary FirebaseApp
  /// so the admin stays logged in
  Future<UserModel> createEmployeeAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String employeeId,
    required String department,
    required String role,
  }) async {
    // Create a secondary app to avoid signing out the admin
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = Firebase.app('SecondaryApp');
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final credential = await secondaryAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    // Sign out from secondary app immediately
    await secondaryAuth.signOut();

    final now = DateTime.now();
    final userModel = UserModel(
      uid: uid,
      name: name,
      email: email.trim(),
      phone: phone,
      employeeId: employeeId,
      department: department,
      role: UserRole.fromString(role),
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .set(userModel.toMap());

    return userModel;
  }

  /// Get user document from Firestore
  Future<UserModel?> getUserDoc(String uid) async {
    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
