import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muslim_way/login_page.dart';
import 'package:muslim_way/root.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _hasSkippedLogin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSkippedLogin = prefs.getBool('seen_login') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. بينما كنقراو SharedPreferences، بين Loading
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    // 2. واش المستخدم مسجل بـ Firebase؟
    final user = FirebaseAuth.instance.currentUser;

    // 3. القرار:
    // إلا كان مسجل (user != null) OR دار تخطي (_hasSkippedLogin == true) -> Root
    if (user != null || _hasSkippedLogin == true) {
      return const Root();
    }

    // 4. وإلا -> سير لصفحة الدخول
    return const LoginPage();
  }
}