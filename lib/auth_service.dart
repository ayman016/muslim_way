import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ 1. تسجيل الدخول مع دمج البيانات (Guest -> Firebase)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 🔥 اللحظة الحاسمة: نقل بيانات الزائر (إذا وجدت) إلى حساب جوجل الجديد
        await _syncGuestDataToFirebase(user);
      }

      return userCredential;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  // 👇 دالة الدمج: تأخذ ما في الهاتف وترفعه للسحابة
  Future<void> _syncGuestDataToFirebase(User user) async {
    final prefs = await SharedPreferences.getInstance();
    
    double localSalary = prefs.getDouble('guest_salary') ?? 0.0;
    double localBalance = prefs.getDouble('guest_balance') ?? 0.0;
    List<String> localTransactions = prefs.getStringList('guest_transactions') ?? [];
    List<String> localTasks = prefs.getStringList('guest_tasks') ?? [];

    // إذا كان الهاتف فارغاً، لا نفعل شيئاً سوى تسجيل المستخدم
    if (localSalary == 0 && localBalance == 0 && localTransactions.isEmpty && localTasks.isEmpty) {
      await _saveUserToFirestore(user);
      return;
    }

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      // ✅ مستخدم جديد في Firebase: ننسخ له بيانات الزائر
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'salary_amount': localSalary,      // ✅ الراتب انتقل
        'wallet_balance': localBalance,    // ✅ الرصيد انتقل
        'wallet_transactions': localTransactions,
        'user_tasks': localTasks,
        'created_at': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // مستخدم قديم: نحدث فقط وقت الدخول (لا نمسح بياناته القديمة)
      await userDocRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ✅ 2. تسجيل الخروج مع "تصفير" الهاتف (Reset)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // 🔥 هنا نمسح ذاكرة الزائر ليعود التطبيق جديداً لمن يستخدمه بعدك
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); 
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}