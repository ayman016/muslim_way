import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // واش المستخدم مسجل الدخول؟
  bool get isUserLoggedIn => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  // 1. إنشاء ملف المستخدم (فقط للمسجلين)
  Future<void> createUserIfNotExists() async {
    if (!isUserLoggedIn) return; // الزائر ما محتاجش ملف فالسحاب
    
    try {
      final docRef = _db.collection('users').doc(currentUserId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'wallet_balance': 0.0,
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

  // 2. جلب البيانات (كيفرق بين الزائر والمسجل)
  Future<Map<String, dynamic>?> getUserData() async {
    if (isUserLoggedIn) {
      // ☁️ مسجل: جيب من Firestore
      try {
        final doc = await _db.collection('users').doc(currentUserId).get();
        return doc.data();
      } catch (e) {
        debugPrint("Error fetching cloud data: $e");
        return null;
      }
    } else {
      // 📱 زائر: جيب من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      double balance = prefs.getDouble('guest_balance') ?? 0.0;
      List<String> transactions = prefs.getStringList('guest_transactions') ?? [];
      List<String> tasks = prefs.getStringList('guest_tasks') ?? [];

      return {
        'wallet_balance': balance,
        'wallet_transactions': transactions,
        'user_tasks': tasks,
      };
    }
  }

  // 3. تحديث المال
  Future<void> updateFinance(double balance, List<String> transactions) async {
    if (isUserLoggedIn) {
      // ☁️ مسجل: سجل فـ Firestore
      await _db.collection('users').doc(currentUserId).update({
        'wallet_balance': balance,
        'wallet_transactions': transactions,
      });
    } else {
      // 📱 زائر: سجل فـ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('guest_balance', balance);
      await prefs.setStringList('guest_transactions', transactions);
    }
  }

  // 4. تحديث المهام
  Future<void> updateTasks(List<String> tasks) async {
    if (isUserLoggedIn) {
      // ☁️ مسجل: سجل فـ Firestore
      await _db.collection('users').doc(currentUserId).update({
        'user_tasks': tasks,
      });
    } else {
      // 📱 زائر: سجل فـ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('guest_tasks', tasks);
    }
  }
  
  // 5. دالة إضافية: مسح بيانات الزائر عند تسجيل الدخول (اختياري)
  Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_balance');
    await prefs.remove('guest_transactions');
    await prefs.remove('guest_tasks');
  }
}