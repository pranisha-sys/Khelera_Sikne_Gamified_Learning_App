import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_home_page.dart';

// ══════════════════════════════════════════════
//  SECRET CODES — only YOU know these!
//  Admin code:   ADMIN@2026
//  Teacher code: TEACHER@2026
//  Change these before releasing the app.
// ══════════════════════════════════════════════
const String adminCode = 'ADMIN@2026';
const String teacherCode = 'TEACHER@2026';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedRole = 'Admin';
  bool _isLoading = false;
  bool _isSignUpMode = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ── Generate unique ID: ADM-1770132831 or TCH-1770132831 ──
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _selectedRole == 'Admin' ? 'ADM-$timestamp' : 'TCH-$timestamp';
  }

  // ── Validate secret code ──
  bool _validateCode() {
    final code = _codeController.text.trim();
    if (_selectedRole == 'Admin' && code == adminCode) return true;
    if (_selectedRole == 'Teacher' && code == teacherCode) return true;
    return false;
  }

  // ── SIGN UP ──
  Future<void> _handleSignUp() async {
    setState(() {
      _errorMessage = null;
    });

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the $_selectedRole code';
      });
      return;
    }

    // Check code BEFORE creating account
    if (!_validateCode()) {
      setState(() {
        _errorMessage =
            'Invalid $_selectedRole code. Ask your admin for the correct code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Create Firebase Auth account
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Step 2: Save to Firestore
      final uniqueId = _generateUniqueId();
      final role = _selectedRole.toLowerCase();

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': role,
        'uniqueId': uniqueId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ $_selectedRole registered! UniqueId: $uniqueId');

      // Step 3: Go to Admin Dashboard
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Sign up failed';
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = 'This email is already registered. Try logging in.';
          break;
        case 'weak-password':
          errorMsg = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'invalid-email':
          errorMsg = 'Invalid email address.';
          break;
        default:
          errorMsg = e.message ?? 'Sign up failed';
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── LOGIN ──
  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
    });

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Firebase Auth login
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Step 2: Check Firestore - confirm role
      final userId = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        await _auth.signOut();
        setState(() {
          _errorMessage =
              'This account is not registered as $_selectedRole. Please sign up first.';
        });
        return;
      }

      final userData = doc.data()!;
      final storedRole = userData['role'] as String;

      if (storedRole != _selectedRole.toLowerCase()) {
        await _auth.signOut();
        setState(() {
          _errorMessage =
              'This account is "$storedRole", not "${_selectedRole.toLowerCase()}". Select the correct role.';
        });
        return;
      }

      print('✅ $_selectedRole logged in! UniqueId: ${userData['uniqueId']}');

      // Step 3: Go to Admin Dashboard
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'No account found. Please sign up first.';
          break;
        case 'wrong-password':
          errorMsg = 'Incorrect password.';
          break;
        case 'invalid-credential':
          errorMsg = 'Invalid email or password.';
          break;
        default:
          errorMsg = e.message ?? 'Login failed';
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      // ── ONE SingleChildScrollView handles ALL scrolling ──
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Logo ──
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.science,
                            size: 80, color: Colors.cyan);
                      },
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── White Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title ──
                        Row(
                          children: [
                            Text(
                              _isSignUpMode
                                  ? 'Create Account '
                                  : 'Welcome Back ',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F6F85),
                              ),
                            ),
                            Text(
                              _isSignUpMode ? '🎓' : '👋',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignUpMode
                              ? 'Register as Admin or Teacher'
                              : 'Login to manage Matter learning',
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 24),

                        // ── Role Selection Label ──
                        const Text(
                          'Select Your Role',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Role Buttons ──
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleButton(
                                'Admin',
                                Icons.shield_outlined,
                                _selectedRole == 'Admin',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRoleButton(
                                'Teacher',
                                Icons.person_outline,
                                _selectedRole == 'Teacher',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Error Message ──
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // ── Name Field (sign up only) ──
                        if (_isSignUpMode) ...[
                          const Text(
                            'Name',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Enter your name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Email Field ──
                        const Text(
                          'Email',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // ── Password Field ──
                        const Text(
                          'Password',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Enter your password',
                          icon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF9CA3AF),
                            ),
                            onPressed: () => setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Secret Code Field (sign up only) ──
                        if (_isSignUpMode) ...[
                          Text(
                            '$_selectedRole Code',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _codeController,
                            hint: 'Enter ${_selectedRole.toLowerCase()} code',
                            icon: Icons.key_outlined,
                            obscureText: true,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask your admin for the ${_selectedRole.toLowerCase()} code',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Submit Button ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_isSignUpMode
                                    ? _handleSignUp
                                    : _handleLogin),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFBBF24),
                              foregroundColor: const Color(0xFF1F2937),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _isSignUpMode ? 'Create Account' : 'Login',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Toggle Login / Sign Up ──
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUpMode = !_isSignUpMode;
                                _errorMessage = null;
                              });
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2196F3)),
                            child: Text(
                              _isSignUpMode
                                  ? 'Already have an account? Login'
                                  : "Don't have an account? Sign Up",
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        // ── Forgot Password (login only) ──
                        if (!_isSignUpMode)
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // TODO: implement forgot password
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF9CA3AF)),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Footer ──
                  const SizedBox(height: 28),
                  const Text(
                    '© 2026 Khelera Sikne. All rights reserved.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 32), // bottom breathing room
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── TextField Builder ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // ── Role Button Builder ──
  Widget _buildRoleButton(String role, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () => setState(() {
        _selectedRole = role;
        _errorMessage = null;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2196F3) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : const Color(0xFF9CA3AF),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              role,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
