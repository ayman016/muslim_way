import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _syncGuestDataToFirebase(user);
      }

      return userCredential;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }

  Future<void> _syncGuestDataToFirebase(User user) async {
    final prefs = await SharedPreferences.getInstance();

    double localSalary = prefs.getDouble('guest_salary') ?? 0.0;
    double localBalance = prefs.getDouble('guest_balance') ?? 0.0;
    List<String> localTransactions =
        prefs.getStringList('guest_transactions') ?? [];
    List<String> localTasks = prefs.getStringList('guest_tasks') ?? [];
    int localStreak = prefs.getInt('guest_streak') ?? 0;
    int localLevel = prefs.getInt('guest_level') ?? 0;
    String localLastStreak =
        prefs.getString('guest_last_streak') ?? 'null';

    final userDocRef = _firestore.collection('users').doc(user.uid);
    
    // ✅ نجيبو من السيرفر أولاً باش نشوفو واش doc موجود
    DocumentSnapshot userDoc;
    try {
      userDoc = await userDocRef.get(const GetOptions(source: Source.server));
    } catch (_) {
      userDoc = await userDocRef.get(const GetOptions(source: Source.cache));
    }

    if (!userDoc.exists) {
      // ✅ مستخدم جديد فعلاً — نخلقو doc بالبيانات الصحيحة
      debugPrint("🆕 New user — creating Firestore document");
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'salary_amount': localSalary,
        'wallet_balance': localBalance,
        'wallet_transactions': localTransactions,
        'user_tasks': localTasks,
        'streak_count': localStreak,
        'user_level': localLevel,
        'last_streak_date': localLastStreak,
        'created_at': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // ✅ مستخدم قديم — غير نحدثو lastLogin فقط
      // ما نلمسوش البيانات أبداً
      debugPrint("✅ Existing user — preserving all data");
      await userDocRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guest_balance');
      await prefs.remove('guest_salary');
      await prefs.remove('guest_transactions');
      await prefs.remove('guest_tasks');
      await prefs.remove('guest_streak');
      await prefs.remove('guest_level');
      await prefs.remove('guest_last_streak');
      await prefs.remove('seen_login');
      await prefs.remove('offline_pending_tasks');
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }
}