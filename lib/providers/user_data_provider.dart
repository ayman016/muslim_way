import 'package:flutter/material.dart';
import 'package:muslim_way/services/firestore_service.dart';
import 'package:intl/intl.dart';

class UserDataProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // البيانات
  double salary = 0.0;
  double balance = 0.0;
  List<String> tasks = [];
  List<String> transactions = [];
  bool isLoading = true;

  // جلب البيانات
  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners(); 

    await _firestoreService.createUserIfNotExists();
    final data = await _firestoreService.getUserData();

    if (data != null) {
      salary = (data['salary_amount'] as num?)?.toDouble() ?? 0.0;
      balance = (data['wallet_balance'] as num?)?.toDouble() ?? 0.0;
      tasks = List<String>.from(data['user_tasks'] ?? []);
      transactions = List<String>.from(data['wallet_transactions'] ?? []);
    }

    isLoading = false;
    notifyListeners(); 
  }

  Future<void> updateSalary(double newSalary) async {
    salary = newSalary;
    notifyListeners();
    await _firestoreService.updateSalary(newSalary);
  }

  Future<void> addTransaction(double amount, bool isIncome, String categoryKey) async {
    if (isIncome) {
      balance += amount;
      salary += amount; 
      _firestoreService.updateSalary(salary);
    } else {
      balance -= amount;
    }
    String typeSymbol = isIncome ? "+" : "-";
    String newTrans = "$typeSymbol $amount|$categoryKey|${DateTime.now().toString()}|$balance";
    transactions.insert(0, newTrans);
    notifyListeners();
    await _firestoreService.updateFinance(balance, transactions);
  }

  Future<void> deleteTransaction(int index) async {
    String transaction = transactions[index];
    List<String> parts = transaction.split('|');
    String amountStr = parts[0].replaceAll(' ', '');
    double amount = double.tryParse(amountStr.substring(1)) ?? 0.0;
    bool wasIncome = amountStr.startsWith('+');

    if (wasIncome) {
      balance -= amount; 
      salary -= amount;  
      _firestoreService.updateSalary(salary);
    } else {
      balance += amount; 
    }
    transactions.removeAt(index);
    notifyListeners();
    await _firestoreService.updateFinance(balance, transactions);
  }

  Future<void> editTransaction(int index, double newAmount, bool newIsIncome, String newCategory) async {
    await deleteTransaction(index); 
    await addTransaction(newAmount, newIsIncome, newCategory);
  }

  // ==============================
  // ✅ إدارة المهام (Tasks Logic)
  // ==============================

  Future<void> addTask(String newTaskString) async {
    tasks.add(newTaskString);
    notifyListeners();
    await _firestoreService.updateTasks(tasks);
  }

  Future<void> editTask(int index, String updatedTaskString) async {
    tasks[index] = updatedTaskString;
    notifyListeners();
    await _firestoreService.updateTasks(tasks);
  }

  Future<void> deleteTask(int index) async {
    tasks.removeAt(index);
    notifyListeners();
    await _firestoreService.updateTasks(tasks);
  }

  // ✅ الدالة الجديدة (Toggle): كتقلب الحالة (تمت ↔️ غير تمت)
  Future<void> toggleTaskStatus(int index) async {
    String task = tasks[index];
    List<String> parts = task.split('|');
    
    // الهيكلة: Title|Cat|IsDaily|Date|Reminder|NotifId|LastDone
    while (parts.length <= 6) {
      parts.add("null");
    }

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String lastDone = parts[6];

    if (lastDone == todayStr) {
      // 🔄 إذا كانت منجزة اليوم، رجعها "null" (إلغاء الإنجاز)
      parts[6] = "null";
    } else {
      // ✅ إذا ماكانتش منجزة، دير ليها تاريخ اليوم
      parts[6] = todayStr;
    }
    
    tasks[index] = parts.join('|');
    notifyListeners(); // تحديث فوري
    await _firestoreService.updateTasks(tasks);
  }
  
  // دالة قديمة، ممكن تخليها للاحتياط أو تمسحها
  Future<void> markTaskAsDone(int index) async {
      await toggleTaskStatus(index);
  }
}