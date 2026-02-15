import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get isUserLoggedIn => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  // إنشاء ملف المستخدم (للحسابات الجديدة)
  Future<void> createUserIfNotExists() async {
    if (!isUserLoggedIn) return;
    try {
      final docRef = _db.collection('users').doc(currentUserId);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'wallet_balance': 0.0,
          'salary_amount': 0.0,
          'wallet_transactions': [],
          'user_tasks': [],
          'email': _auth.currentUser?.email,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error creating user: $e");
    }
  }

  // جلب البيانات
  Future<Map<String, dynamic>?> getUserData() async {
    if (isUserLoggedIn) {
      // ☁️ مسجل: جيب من Firebase
      try {
        final doc = await _db.collection('users').doc(currentUserId).get();
        return doc.data();
      } catch (e) {
        return null;
      }
    } else {
      // 📱 زائر: جيب من Local Storage
      // (بعد Logout ستكون هذه القيم 0.0 لأننا مسحناها)
      final prefs = await SharedPreferences.getInstance();
      return {
        'wallet_balance': prefs.getDouble('guest_balance') ?? 0.0,
        'salary_amount': prefs.getDouble('guest_salary') ?? 0.0,
        'wallet_transactions': prefs.getStringList('guest_transactions') ?? [],
        'user_tasks': prefs.getStringList('guest_tasks') ?? [],
      };
    }
  }

  // تحديث الراتب
  Future<void> updateSalary(double salary) async {
    if (isUserLoggedIn) {
      await _db.collection('users').doc(currentUserId).update({'salary_amount': salary});
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('guest_salary', salary);
    }
  }

  // تحديث المال
  Future<void> updateFinance(double balance, List<String> transactions) async {
    if (isUserLoggedIn) {
       await _db.collection('users').doc(currentUserId).update({
        'wallet_balance': balance,
        'wallet_transactions': transactions,
      });
    } else {
       final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('guest_balance', balance);
      await prefs.setStringList('guest_transactions', transactions);
    }
  }

  // تحديث المهام
  Future<void> updateTasks(List<String> tasks) async {
     if (isUserLoggedIn) {
      await _db.collection('users').doc(currentUserId).update({'user_tasks': tasks});
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('guest_tasks', tasks);
    }
  }
}