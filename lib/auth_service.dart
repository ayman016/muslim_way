import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 ضروري
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // 👈 زدنا هادي

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. عملية الدخول
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // ✅ صحيح (زدنا await)
final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      // 2. 👇 تسجيل معلومات المستخدم فـ Database (Firestore)
      if (user != null) {
        await _saveUserToFirestore(user);
      }

      return userCredential;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  // 👇 دالة جديدة كتسجل المعلومات
  Future<void> _saveUserToFirestore(User user) async {
    try {
      // كنسجلوه فالكوليكشن 'users' بالـ ID ديالو
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(), // فوقاش دخل آخر مرة
      }, SetOptions(merge: true)); // merge: true باش ما يمسحش الداتا القديمة إلا كانت
    } catch (e) {
      print("Error saving user to Firestore: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}