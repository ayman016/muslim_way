import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muslim_way/login_page.dart';
import 'package:muslim_way/root.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _ready = false;
  bool _shouldGoToRoot = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final seenLogin = prefs.getBool('seen_login') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      setState(() {
        // يدخل لـ Root إذا كان مسجل أو ضغط على "تخطي" من قبل
        _shouldGoToRoot = (currentUser != null || seenLogin);
        _ready = true;
      });

      // جلب البيانات فوراً في الخلفية
      if (_shouldGoToRoot) {
        context.read<UserDataProvider>().fetchData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return _shouldGoToRoot ? const Root() : const LoginPage();
  }
}