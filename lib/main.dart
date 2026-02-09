import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin/admin_home_page.dart';
import 'admin/admin_login_page.dart';
import 'admin/user_management_page.dart';
import 'student/home_page.dart';
import 'teacher/teacher_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint("✅ Firebase connected successfully!");
    debugPrint("Firebase App Name: ${Firebase.app().name}");
    debugPrint("Firebase Auth instance: ${FirebaseAuth.instance}");

    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://mltvhrlltjtkgzcgxvvr.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sdHZocmxsdGp0a2d6Y2d4dnZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyOTI2MzYsImV4cCI6MjA4NTg2ODYzNn0.aDXNqWUTcD0l3GGUejoGzAE7aQ9YrFSjMbRVVhpsJ-k',
    );
    debugPrint("✅ Supabase connected successfully!");
  } catch (e) {
    debugPrint("❌ Initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khelera Sikne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SelectScreen(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminLoginPage(),
        '/admin-home': (context) => const AdminHomePage(),
        '/teacher-home': (context) => const TeacherHomePage(),
        '/admin-users': (context) => const UserManagementPage(),
      },
    );
  }
}

class SelectScreen extends StatelessWidget {
  const SelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Khelera Sikne',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select how you want to continue',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 280,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/home'),
                icon: const Icon(Icons.person_outline, size: 22),
                label: const Text(
                  'Student App',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 280,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin'),
                icon: const Icon(Icons.shield_outlined, size: 22),
                label: const Text(
                  'Admin Panel',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF1F2937),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
