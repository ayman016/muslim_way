import 'package:flutter/material.dart';
import 'package:muslim_way/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class UserDataProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  double _salary = 0.0;
  double _balance = 0.0;
  List<String> _tasks = [];
  List<String> _transactions = [];
  bool _isLoading = false;
  
  // Getters
  double get salary => _salary;
  double get balance => _balance;
  List<String> get tasks => _tasks;
  List<String> get transactions => _transactions;
  bool get isLoading => _isLoading;

  void clearData() {
    _salary = 0.0;
    _balance = 0.0;
    _tasks = [];
    _transactions = [];
    notifyListeners();
  }

  Future<void> fetchData({bool forceRefresh = false}) async {
    _isLoading = true;
    try {
      await _firestoreService.createUserIfNotExists();
      final data = await _firestoreService.getUserData();

      if (data != null) {
        _salary = (data['salary_amount'] as num?)?.toDouble() ?? 0.0;
        _balance = (data['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        _tasks = List<String>.from(data['user_tasks'] ?? []);
        _transactions = List<String>.from(data['wallet_transactions'] ?? []);
      }
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==============================
  // 💰 Finance Management
  // ==============================

  // 🔥 التعديل المهم هنا:
  // فاش كنحدثو الراتب يدوياً (من Settings)، كنحدثو حتى الرصيد باش يتقادو
  Future<void> updateSalary(double newAmount) async {
    _salary = newAmount;
    _balance = newAmount; // ✅ هادي هي لي كانت ناقصة (الرصيد كيولي نفس الراتب)
    
    notifyListeners(); 
    
    // نرسل التحديث لـ Firestore بجوج
    await _firestoreService.updateSalary(_salary);
    await _firestoreService.updateFinance(_balance, _transactions);
  }

  Future<void> addTransaction(double amount, bool isIncome, String categoryKey) async {
    if (isIncome) {
      _balance += amount;
      _salary += amount; // المدخول كيزيد فالراتب والرصيد
    } else {
      _balance -= amount;
      // المصروف كينقص من الرصيد فقط (باش الاحصائيات تعرف شحال صرفتي من الراتب الأصلي)
    }

    String typeSymbol = isIncome ? "+" : "-";
    String newTrans = "$typeSymbol $amount|$categoryKey|${DateTime.now().toString()}|$_balance";
    
    _transactions = [newTrans, ..._transactions]; 

    notifyListeners(); 

    await _firestoreService.updateFinance(_balance, _transactions);
    if (isIncome) await _firestoreService.updateSalary(_salary);
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
    
    List<String> newList = List.from(_transactions);
    newList.removeAt(index);
    _transactions = newList;

    notifyListeners();

    await _firestoreService.updateFinance(_balance, _transactions);
    if (wasIncome) await _firestoreService.updateSalary(_salary);
  }

  Future<void> editTransaction(int index, double newAmount, bool newIsIncome, String newCategory) async {
    await deleteTransaction(index);
    await addTransaction(newAmount, newIsIncome, newCategory);
  }

  // ==============================
  // ✅ Task Management
  // ==============================

  Future<void> addTask(String newTaskString) async {
    _tasks = [..._tasks, newTaskString];
    notifyListeners();
    await _firestoreService.updateTasks(_tasks);
  }

  Future<void> editTask(int index, String updatedTaskString) async {
    if (index < 0 || index >= _tasks.length) return;
    List<String> newList = List.from(_tasks);
    newList[index] = updatedTaskString;
    _tasks = newList;
    notifyListeners();
    await _firestoreService.updateTasks(_tasks);
  }

  Future<void> deleteTask(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    List<String> newList = List.from(_tasks);
    newList.removeAt(index);
    _tasks = newList;
    notifyListeners();
    await _firestoreService.updateTasks(_tasks);
  }

  Future<void> toggleTaskStatus(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    List<String> newList = List.from(_tasks);
    String task = newList[index];
    List<String> parts = task.split('|');
    while (parts.length <= 6) parts.add("null");
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    parts[6] = (parts[6] == todayStr) ? "null" : todayStr;
    newList[index] = parts.join('|');
    _tasks = newList;
    notifyListeners();
    await _firestoreService.updateTasks(_tasks);
  }
  
  Future<void> markTaskAsDone(int index) => toggleTaskStatus(index);
}