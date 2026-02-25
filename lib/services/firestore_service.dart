import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get isUserLoggedIn => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  // المفاتيح المحلية
  static const _kBalance      = 'local_balance';
  static const _kSalary       = 'local_salary';
  static const _kTransactions = 'local_transactions';
  static const _kTasks        = 'local_tasks';
  static const _kStreak       = 'local_streak';
  static const _kLevel        = 'local_level';
  static const _kLastStreak   = 'local_last_streak';
  static const _kPendingSync  = 'pending_sync';

  // حفظ البيانات محلياً للرجوع إليها Offline
  Future<void> _saveLocally({
    double? balance,
    double? salary,
    List<String>? transactions,
    List<String>? tasks,
    int? streak,
    int? level,
    String? lastStreak,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (balance      != null) await prefs.setDouble(_kBalance, balance);
    if (salary       != null) await prefs.setDouble(_kSalary, salary);
    if (transactions != null) await prefs.setStringList(_kTransactions, transactions);
    if (tasks        != null) await prefs.setStringList(_kTasks, tasks);
    if (streak       != null) await prefs.setInt(_kStreak, streak);
    if (level        != null) await prefs.setInt(_kLevel, level);
    if (lastStreak   != null) await prefs.setString(_kLastStreak, lastStreak);
  }

  // قراءة البيانات من الذاكرة المحلية
  Future<Map<String, dynamic>?> _getLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kBalance) && !prefs.containsKey('guest_balance')) return null;

    return {
      'wallet_balance':      prefs.getDouble(_kBalance)       ?? prefs.getDouble('guest_balance')             ?? 0.0,
      'salary_amount':       prefs.getDouble(_kSalary)        ?? prefs.getDouble('guest_salary')              ?? 0.0,
      'wallet_transactions': prefs.getStringList(_kTransactions) ?? prefs.getStringList('guest_transactions') ?? [],
      'user_tasks':          prefs.getStringList(_kTasks)        ?? prefs.getStringList('guest_tasks')        ?? [],
      'streak_count':        prefs.getInt(_kStreak)           ?? prefs.getInt('guest_streak')                 ?? 0,
      'user_level':          prefs.getInt(_kLevel)            ?? prefs.getInt('guest_level')                  ?? 0,
      'last_streak_date':    prefs.getString(_kLastStreak)   ?? prefs.getString('guest_last_streak')         ?? 'null',
    };
  }

  Future<void> createUserIfNotExists() async {
    if (!isUserLoggedIn) return;
    try {
      final docRef = _db.collection('users').doc(currentUserId);
      // إزالة الإجبار لتفادي تعليق التطبيق
      final doc = await docRef.get();
      
      if (!doc.exists) {
        final localData = await _getLocalData();
        await docRef.set({
          'wallet_balance':      localData?['wallet_balance']      ?? 0.0,
          'salary_amount':       localData?['salary_amount']       ?? 0.0,
          'wallet_transactions': localData?['wallet_transactions'] ?? [],
          'user_tasks':          localData?['user_tasks']          ?? [],
          'streak_count':        localData?['streak_count']        ?? 0,
          'user_level':          localData?['user_level']          ?? 0,
          'last_streak_date':    localData?['last_streak_date']    ?? 'null',
          'email':               _auth.currentUser?.email,
          'created_at':          FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (isUserLoggedIn) {
      // 1. إحضار الكاش المحلي فوراً للحماية الإضافية
      final localData = await _getLocalData();
      
      try {
        // 2. الجلب الافتراضي: ذكي جداً، يجلب من الكاش فوراً إذا لم يكن هناك إنترنت
        // دون الحاجة للانتظار (تم مسح timeout و Source.server)
        final doc = await _db.collection('users').doc(currentUserId).get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          await _saveLocally(
            balance: (data['wallet_balance'] as num?)?.toDouble(),
            salary: (data['salary_amount'] as num?)?.toDouble(),
            transactions: List<String>.from(data['wallet_transactions'] ?? []),
            tasks: List<String>.from(data['user_tasks'] ?? []),
            streak: (data['streak_count'] as num?)?.toInt(),
            level: (data['user_level'] as num?)?.toInt(),
            lastStreak: data['last_streak_date'] as String?,
          );
          return data;
        }
      } catch (e) {
        debugPrint("⚠️ Offline fallback to SharedPreferences: $e");
      }
      return localData;
    } else {
      return _getLocalData();
    }
  }

  // دوال التحديث (update) تعمل بنفس المنطق: حفظ محلي ثم مزامنة مع Firebase
  Future<void> updateSalary(double salary) async {
    await _saveLocally(salary: salary);
    if (isUserLoggedIn) {
      _db.collection('users').doc(currentUserId).update({'salary_amount': salary}).catchError((_){});
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('guest_salary', salary);
    }
  }

  Future<void> updateFinance(double balance, List<String> transactions) async {
    await _saveLocally(balance: balance, transactions: transactions);
    if (isUserLoggedIn) {
      _db.collection('users').doc(currentUserId).update({
        'wallet_balance': balance,
        'wallet_transactions': transactions,
      }).catchError((_){});
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('guest_balance', balance);
      await prefs.setStringList('guest_transactions', transactions);
    }
  }

  Future<void> updateTasks(List<String> tasks) async {
    await _saveLocally(tasks: tasks);
    if (isUserLoggedIn) {
      _db.collection('users').doc(currentUserId).update({'user_tasks': tasks}).catchError((_){});
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('guest_tasks', tasks);
    }
  }

  Future<void> updateStreakAndLevel(int streak, int level, String lastDate) async {
    await _saveLocally(streak: streak, level: level, lastStreak: lastDate);
    if (isUserLoggedIn) {
      _db.collection('users').doc(currentUserId).update({
        'streak_count': streak,
        'user_level': level,
        'last_streak_date': lastDate,
      }).catchError((_){});
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('guest_streak', streak);
      await prefs.setInt('guest_level', level);
      await prefs.setString('guest_last_streak', lastDate);
    }
  }

  Future<void> syncPendingData() async {
    if (!isUserLoggedIn) return;
    final localData = await _getLocalData();
    if (localData != null) {
      _db.collection('users').doc(currentUserId).set(localData, SetOptions(merge: true)).catchError((_){});
    }
  }
}