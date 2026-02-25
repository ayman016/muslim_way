import 'package:flutter/material.dart';
import 'package:muslim_way/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class UserDataProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  double _salary = 0.0;
  double _balance = 0.0;
  List<String> _tasks = [];
  List<String> _transactions = [];
  bool _isLoading = false;
  bool _dataLoaded = false;

  int _streakCount = 0;
  int _userLevel = 0;
  String _lastStreakDate = "null";
  int _levelAtStartOfToday = 0;

  StreamSubscription? _connectivitySub;

  double get salary             => _salary;
  double get balance            => _balance;
  List<String> get tasks        => _tasks;
  List<String> get transactions => _transactions;
  bool get isLoading            => _isLoading;
  bool get dataLoaded           => _dataLoaded;
  int get streakCount           => _streakCount;
  int get userLevel             => _userLevel;

  void clearData() {
    _salary = 0.0;
    _balance = 0.0;
    _tasks = [];
    _transactions = [];
    _streakCount = 0;
    _userLevel = 0;
    _lastStreakDate = "null";
    _levelAtStartOfToday = 0;
    _dataLoaded = false;
    _isLoading = false;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    notifyListeners();
  }

  Future<void> fetchData({bool forceRefresh = false}) async {
    if (_dataLoaded && !forceRefresh) return;
    if (_isLoading) return;

    _isLoading = true;
    // ✅ بدون notifyListeners هنا — ما نعيطوهاش أثناء build

    try {
      await _firestoreService.createUserIfNotExists();
      await _firestoreService.syncPendingData();

      final data = await _firestoreService.getUserData();

      if (data != null) {
        _salary        = (data['salary_amount']    as num?)?.toDouble() ?? 0.0;
        _balance       = (data['wallet_balance']   as num?)?.toDouble() ?? 0.0;
        _tasks         = List<String>.from(data['user_tasks']          ?? []);
        _transactions  = List<String>.from(data['wallet_transactions'] ?? []);
        _streakCount   = (data['streak_count']     as num?)?.toInt()   ?? 0;
        _userLevel     = (data['user_level']        as num?)?.toInt()   ?? 0;
        _lastStreakDate = data['last_streak_date']  as String?          ?? "null";

        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (_lastStreakDate == todayStr && _streakCount == 7) {
          _levelAtStartOfToday = _userLevel - 1;
        } else {
          _levelAtStartOfToday = _userLevel;
        }

        debugPrint("✅ Data loaded: balance=$_balance, salary=$_salary, tasks=${_tasks.length}");

        await _checkAndResetForNewMonth();
        await _evaluateStreak(fromFetch: true);

        _dataLoaded = true;

        _connectivitySub?.cancel();
        _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
          final hasInternet = results.isNotEmpty &&
              results.first != ConnectivityResult.none;
          if (hasInternet) {
            debugPrint("🌐 Internet back — syncing...");
            _firestoreService.syncPendingData()
                .catchError((e) => debugPrint(e.toString()));
          }
        });
      } else {
        _dataLoaded = true;
        debugPrint("⚠️ No data available");
      }
    } catch (e) {
      _dataLoaded = true;
      debugPrint("❌ fetchData error: $e");
    } finally {
      _isLoading = false;
      // ✅ addPostFrameCallback — نضمنو ما كنعيطوش notifyListeners أثناء build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _checkAndResetForNewMonth() async {
    if (_salary == 0) return;
    if (_transactions.isEmpty) return;

    final now             = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    String? lastRealTransactionMonthKey;
    for (var trans in _transactions) {
      final parts = trans.split('|');
      if (parts.length > 1 && parts[1] == 'cat_monthly_reset') continue;
      if (parts.length > 2) {
        try {
          final date = DateTime.parse(parts[2]);
          lastRealTransactionMonthKey = DateFormat('yyyy-MM').format(date);
          break;
        } catch (_) {}
      }
    }

    if (lastRealTransactionMonthKey != null &&
        lastRealTransactionMonthKey != currentMonthKey) {
      debugPrint("🔄 Monthly reset: $lastRealTransactionMonthKey → $currentMonthKey");
      _balance = _salary;
      final resetTrans = "+0|cat_monthly_reset|${now.toIso8601String()}|$_balance";
      _transactions = [resetTrans, ..._transactions];
      _firestoreService
          .updateFinance(_balance, _transactions)
          .catchError((e) => debugPrint(e.toString()));
    }
  }

  Future<void> _evaluateStreak({bool fromFetch = false}) async {
    final todayStr     = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(const Duration(days: 1)));

    bool changed = false;

    if (_lastStreakDate != todayStr &&
        _lastStreakDate != yesterdayStr &&
        _lastStreakDate != "null") {
      _streakCount    = 0;
      _lastStreakDate = "null";
      changed = true;
    }

    final dailyTasks = _tasks.where((t) {
      final p = t.split('|');
      return p.length > 2 && p[2] == 'true';
    }).toList();

    if (dailyTasks.isEmpty) {
      if (changed && !fromFetch) {
        _firestoreService
            .updateStreakAndLevel(_streakCount, _userLevel, _lastStreakDate)
            .catchError((e) => debugPrint(e.toString()));
      }
      return;
    }

    final bool allDoneToday = dailyTasks.every((t) {
      final p = t.split('|');
      return p.length > 6 && p[6] == todayStr;
    });

    if (allDoneToday) {
      if (_lastStreakDate != todayStr) {
        if (_lastStreakDate == yesterdayStr) {
          _streakCount = _streakCount >= 7 ? 1 : _streakCount + 1;
        } else {
          _streakCount = 1;
        }
        if (_streakCount == 7) {
          _userLevel++;
          _levelAtStartOfToday = _userLevel - 1;
        }
        _lastStreakDate = todayStr;
        changed = true;
      }
    } else {
      if (_lastStreakDate == todayStr && !fromFetch) {
        if (_streakCount == 7) {
          _userLevel   = _levelAtStartOfToday;
          _streakCount = 6;
        } else if (_streakCount <= 1) {
          _streakCount    = 0;
          _lastStreakDate = "null";
        } else {
          _streakCount--;
          _lastStreakDate = yesterdayStr;
        }
        if (_userLevel < _levelAtStartOfToday) _userLevel = _levelAtStartOfToday;
        changed = true;
      }
    }

    if (changed) {
      // ✅ بدون notifyListeners هنا — غادي يتعمل فـ finally
      if (!fromFetch) {
        _firestoreService
            .updateStreakAndLevel(_streakCount, _userLevel, _lastStreakDate)
            .catchError((e) => debugPrint(e.toString()));
      }
    }
  }

  // ==============================
  // 💰 Finance Management
  // ==============================

  Future<void> updateSalary(double newAmount) async {
    _salary  = newAmount;
    _balance = newAmount;
    notifyListeners();
    _firestoreService.updateSalary(_salary)
        .catchError((e) => debugPrint(e.toString()));
    _firestoreService.updateFinance(_balance, _transactions)
        .catchError((e) => debugPrint(e.toString()));
  }

  Future<void> updateBalanceOnly(double newBalance) async {
    _balance = newBalance;
    notifyListeners();
    _firestoreService.updateFinance(_balance, _transactions)
        .catchError((e) => debugPrint(e.toString()));
  }

  Future<void> updateSalaryOnly(double newSalary) async {
    _salary = newSalary;
    notifyListeners();
    _firestoreService.updateSalary(_salary)
        .catchError((e) => debugPrint(e.toString()));
  }

  Future<void> addTransaction(
      double amount, bool isIncome, String categoryKey) async {
    if (isIncome) {
      _balance += amount;
      _salary  += amount;
    } else {
      _balance -= amount;
    }
    final typeSymbol = isIncome ? "+" : "-";
    final newTrans =
        "$typeSymbol $amount|$categoryKey|${DateTime.now().toIso8601String()}|$_balance";
    _transactions = [newTrans, ..._transactions];
    notifyListeners();
    _firestoreService.updateFinance(_balance, _transactions)
        .catchError((e) => debugPrint(e.toString()));
    if (isIncome) {
      _firestoreService.updateSalary(_salary)
          .catchError((e) => debugPrint(e.toString()));
    }
  }

  Future<void> deleteTransaction(int index) async {
    if (index < 0 || index >= _transactions.length) return;
    final transaction = _transactions[index];
    final parts       = transaction.split('|');
    final amountStr   = parts[0].replaceAll(' ', '');
    if (parts.length > 1 && parts[1] == 'cat_monthly_reset') return;

    final amount    = double.tryParse(amountStr.substring(1)) ?? 0.0;
    final wasIncome = amountStr.startsWith('+');

    if (wasIncome) {
      _balance -= amount;
      _salary  -= amount;
    } else {
      _balance += amount;
    }

    final newList = List<String>.from(_transactions);
    newList.removeAt(index);
    _transactions = newList;
    notifyListeners();
    _firestoreService.updateFinance(_balance, _transactions)
        .catchError((e) => debugPrint(e.toString()));
    if (wasIncome) {
      _firestoreService.updateSalary(_salary)
          .catchError((e) => debugPrint(e.toString()));
    }
  }

  Future<void> editTransaction(
      int index, double newAmount, bool newIsIncome, String newCategory) async {
    await deleteTransaction(index);
    await addTransaction(newAmount, newIsIncome, newCategory);
  }

  // ==============================
  // ✅ Task Management
  // ==============================

  Future<void> addTask(String newTaskString) async {
    _tasks = [..._tasks, newTaskString];
    await _evaluateStreak(fromFetch: false);
    notifyListeners();
    _firestoreService.updateTasks(_tasks)
        .catchError((e) => debugPrint(e.toString()));
  }

  Future<void> editTask(int index, String updatedTaskString) async {
    if (index < 0 || index >= _tasks.length) return;
    final newList  = List<String>.from(_tasks);
    newList[index] = updatedTaskString;
    _tasks = newList;
    await _evaluateStreak(fromFetch: false);
    notifyListeners();
    _firestoreService.updateTasks(_tasks)
        .catchError((e) => debugPrint(e.toString()));
  }

  Future<void> deleteTask(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    final newList = List<String>.from(_tasks);
    newList.removeAt(index);
    _tasks = newList;
    await _evaluateStreak(fromFetch: false);
    notifyListeners();
    _firestoreService.updateTasks(_tasks)
        .catchError((e) => debugPrint(e.toString()));
  }

  Future<void> toggleTaskStatus(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    final newList      = List<String>.from(_tasks);
    String task        = newList[index];
    List<String> parts = task.split('|');
    while (parts.length <= 6) parts.add("null");
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    parts[6]       = (parts[6] == todayStr) ? "null" : todayStr;
    newList[index] = parts.join('|');
    _tasks = newList;
    await _evaluateStreak(fromFetch: false);
    notifyListeners();
    _firestoreService.updateTasks(_tasks)
        .catchError((e) => debugPrint(e.toString()));
  }

  Future<void> markTaskAsDone(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    final newList      = List<String>.from(_tasks);
    String task        = newList[index];
    List<String> parts = task.split('|');
    while (parts.length <= 6) parts.add("null");
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (parts[6] != todayStr) {
      parts[6]       = todayStr;
      newList[index] = parts.join('|');
      _tasks = newList;
      await _evaluateStreak(fromFetch: false);
      notifyListeners();
      _firestoreService.updateTasks(_tasks)
          .catchError((e) => debugPrint(e.toString()));
    }
  }
}