import 'package:flutter/material.dart';
import 'package:muslim_way/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class UserDataProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // ✅ البيانات
  double _salary = 0.0;
  double _balance = 0.0;
  List<String> _tasks = [];
  List<String> _transactions = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false; // 🆕 Cache flag

  // 🆕 Debounce Timer
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  // Getters
  double get salary => _salary;
  double get balance => _balance;
  List<String> get tasks => List.unmodifiable(_tasks);
  List<String> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get hasData => _hasLoadedOnce;

  // ✅ Optimized fetch with caching
  Future<void> fetchData({bool forceRefresh = false}) async {
    if (_hasLoadedOnce && !forceRefresh) {
      debugPrint("✅ Data cached, skipping fetch");
      return;
    }

    _isLoading = true;
    _notifyListenersDebounced();

    try {
      await _firestoreService.createUserIfNotExists();
      final data = await _firestoreService.getUserData();

      if (data != null) {
        _salary = (data['salary_amount'] as num?)?.toDouble() ?? 0.0;
        _balance = (data['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        _tasks = List<String>.from(data['user_tasks'] ?? []);
        _transactions = List<String>.from(data['wallet_transactions'] ?? []);
      }

      _hasLoadedOnce = true;
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
    } finally {
      _isLoading = false;
      _notifyListenersDebounced();
    }
  }

  // 🆕 Debounced notify
  void _notifyListenersDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, notifyListeners);
  }

  // ✅ Immediate notify for critical updates
  void _notifyListenersImmediate() {
    _debounceTimer?.cancel();
    notifyListeners();
  }

  // ==============================
  // 💰 Finance Management
  // ==============================

  Future<void> updateSalary(double newSalary) async {
    if (_salary == newSalary) return;

    _salary = newSalary;
    _notifyListenersImmediate();
    
    unawaited(_firestoreService.updateSalary(newSalary));
  }

  Future<void> addTransaction(double amount, bool isIncome, String categoryKey) async {
    if (isIncome) {
      _balance += amount;
      _salary += amount;
    } else {
      _balance -= amount;
    }

    String typeSymbol = isIncome ? "+" : "-";
    String newTrans = "$typeSymbol $amount|$categoryKey|${DateTime.now().toString()}|$_balance";
    _transactions.insert(0, newTrans);

    _notifyListenersImmediate();

    unawaited(_firestoreService.updateFinance(_balance, _transactions));
    if (isIncome) unawaited(_firestoreService.updateSalary(_salary));
  }

  Future<void> deleteTransaction(int index) async {
    if (index < 0 || index >= _transactions.length) return;

    String transaction = _transactions[index];
    List<String> parts = transaction.split('|');
    String amountStr = parts[0].replaceAll(' ', '');
    double amount = double.tryParse(amountStr.substring(1)) ?? 0.0;
    bool wasIncome = amountStr.startsWith('+');

    if (wasIncome) {
      _balance -= amount;
      _salary -= amount;
    } else {
      _balance += amount;
    }
    _transactions.removeAt(index);

    _notifyListenersImmediate();

    unawaited(_firestoreService.updateFinance(_balance, _transactions));
    if (wasIncome) unawaited(_firestoreService.updateSalary(_salary));
  }

  Future<void> editTransaction(int index, double newAmount, bool newIsIncome, String newCategory) async {
    await deleteTransaction(index);
    await addTransaction(newAmount, newIsIncome, newCategory);
  }

  // ==============================
  // ✅ Task Management
  // ==============================

  Future<void> addTask(String newTaskString) async {
    _tasks.add(newTaskString);
    _notifyListenersImmediate();
    unawaited(_firestoreService.updateTasks(_tasks));
  }

  Future<void> editTask(int index, String updatedTaskString) async {
    if (index < 0 || index >= _tasks.length) return;
    
    _tasks[index] = updatedTaskString;
    _notifyListenersImmediate();
    unawaited(_firestoreService.updateTasks(_tasks));
  }

  Future<void> deleteTask(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    
    _tasks.removeAt(index);
    _notifyListenersImmediate();
    unawaited(_firestoreService.updateTasks(_tasks));
  }

  Future<void> toggleTaskStatus(int index) async {
    if (index < 0 || index >= _tasks.length) return;

    String task = _tasks[index];
    List<String> parts = task.split('|');
    
    while (parts.length <= 6) parts.add("null");

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    parts[6] = (parts[6] == todayStr) ? "null" : todayStr;
    
    _tasks[index] = parts.join('|');
    _notifyListenersImmediate();
    unawaited(_firestoreService.updateTasks(_tasks));
  }

  Future<void> markTaskAsDone(int index) => toggleTaskStatus(index);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

void unawaited(Future<void> future) {
  future.catchError((e) => debugPrint("⚠️ Background error: $e"));
}
