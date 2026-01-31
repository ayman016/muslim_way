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

  // جلب البيانات من السيرفر
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

  // تحديث الراتب يدوياً
  Future<void> updateSalary(double newSalary) async {
    salary = newSalary;
    notifyListeners();
    await _firestoreService.updateSalary(newSalary);
  }

  // إضافة معاملة (مع Snapshot للرصيد)
  Future<void> addTransaction(double amount, bool isIncome, String categoryKey) async {
    if (isIncome) {
      balance += amount;
      salary += amount; 
      _firestoreService.updateSalary(salary);
    } else {
      balance -= amount;
    }
    
    String typeSymbol = isIncome ? "+" : "-";
    // المبلغ | التصنيف | التاريخ | الرصيد_بعد_العملية
    String newTrans = "$typeSymbol $amount|$categoryKey|${DateTime.now().toString()}|$balance";
    
    transactions.insert(0, newTrans);
    
    notifyListeners();
    await _firestoreService.updateFinance(balance, transactions);
  }

  // حذف معاملة (استرجاع المال)
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

  // تعديل معاملة
  Future<void> editTransaction(int index, double newAmount, bool newIsIncome, String newCategory) async {
    await deleteTransaction(index); 
    await addTransaction(newAmount, newIsIncome, newCategory);
  }

  // ==============================
  // ✅ إدارة المهام (Tasks Logic)
  // ==============================

  // 1. إضافة مهمة جديدة
  Future<void> addTask(String newTaskString) async {
    tasks.add(newTaskString);
    notifyListeners(); // ✅ هذا هو السر لتحديث الإحصائيات فوراً
    await _firestoreService.updateTasks(tasks);
  }

  // 2. تعديل مهمة
  Future<void> editTask(int index, String updatedTaskString) async {
    tasks[index] = updatedTaskString;
    notifyListeners();
    await _firestoreService.updateTasks(tasks);
  }

  // 3. حذف مهمة
  Future<void> deleteTask(int index) async {
    tasks.removeAt(index);
    notifyListeners();
    await _firestoreService.updateTasks(tasks);
  }

  // 4. ✅ وضع علامة "تمت" على المهمة
  Future<void> markTaskAsDone(int index) async {
    String task = tasks[index];
    List<String> parts = task.split('|');
    
    // الهيكلة: Title|Cat|IsDaily|Date|Reminder|NotifId|LastDone
    // Index 6 هو LastDone (تاريخ آخر إنجاز)
    
    // إذا كانت البيانات قديمة وناقصة، نكملوها
    while (parts.length <= 6) {
      parts.add("null");
    }

    // تحديث التاريخ لليوم
    parts[6] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    tasks[index] = parts.join('|');
    
    notifyListeners(); // ✅ تحديث StatsPage فوراً
    await _firestoreService.updateTasks(tasks);
  }
}