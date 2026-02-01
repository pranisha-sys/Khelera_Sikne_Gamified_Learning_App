import 'package:flutter/material.dart';

import 'login_page.dart';
import 'sign_up_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;

  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation;

  late Animation<double> _welcomeAnimation;
  late Animation<double> _appNameAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _loginButtonAnimation;
  late Animation<double> _signInButtonAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller (0-2 seconds)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Content animation controller (2-4 seconds)
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 0.3),
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      _logoController,
    );

    // Content animations (staggered)
    _welcomeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _appNameAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.15, 0.35, curve: Curves.easeOut),
      ),
    );

    _subtitleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
      ),
    );

    _loginButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
      ),
    );

    _signInButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.65, 0.85, curve: Curves.easeOut),
      ),
    );

    // Start animation sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();
    // After logo animation, start content animation
    _contentController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Custom Geometric Background
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            painter: DiagonalBackgroundPainter(),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _logoSlideAnimation,
                            child: ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: FadeTransition(
                                opacity: _logoFadeAnimation,
                                child: GestureDetector(
                                  onTap: () {
                                    // Already on home page, just print a message
                                    debugPrint('Already on Home Page');
                                  },
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    height: 200,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.science,
                                        size: 120,
                                        color: Colors.cyan,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 80),

                      // Welcome Text
                      AnimatedBuilder(
                        animation: _welcomeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _welcomeAnimation.value,
                            child: Transform.translate(
                              offset:
                                  Offset(0, 20 * (1 - _welcomeAnimation.value)),
                              child: Text(
                                'Welcome to',
                                style: TextStyle(
                                    fontSize: 35,
                                    color: Colors.cyan.shade700,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // App Name
                      AnimatedBuilder(
                        animation: _appNameAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _appNameAnimation.value,
                            child: Transform.translate(
                              offset:
                                  Offset(0, 20 * (1 - _appNameAnimation.value)),
                              child: Text(
                                'Khelara Sikne',
                                style: TextStyle(
                                  fontSize: 50,
                                  color: Colors.cyan.shade700,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      AnimatedBuilder(
                        animation: _subtitleAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _subtitleAnimation.value,
                            child: Transform.translate(
                              offset: Offset(
                                  0, 20 * (1 - _subtitleAnimation.value)),
                              child: const Text(
                                '(Play and Learn About Matter)',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 60),

                      // Login Button
                      AnimatedBuilder(
                        animation: _loginButtonAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _loginButtonAnimation.value,
                            child: Transform.scale(
                              scale: _loginButtonAnimation.value,
                              child: SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate to Login Page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: BorderSide(
                                        color: Colors.cyan.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Sign Up Button
                      AnimatedBuilder(
                        animation: _signInButtonAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _signInButtonAnimation.value,
                            child: Transform.scale(
                              scale: _signInButtonAnimation.value,
                              child: SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate to Sign Up Page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: BorderSide(
                                        color: Colors.cyan.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Diagonal Background Design matching the image
class DiagonalBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Cyan background base
    final bgPaint = Paint()..color = Color(0xFFB2EBF2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Main diagonal cyan lighter overlay from top-right to center
    final pathCyan = Path();
    pathCyan.lineTo(
        size.width * 0.2, size.height * 0.55); // Diagonal to left-center
    pathCyan.close();

    final cyanOverlayPaint = Paint()
      ..color = Color(0xFF80DEEA).withOpacity(0.6);
    canvas.drawPath(pathCyan, cyanOverlayPaint);

    // White geometric shape - bottom right only
    final pathBottomRight = Path();
    pathBottomRight.moveTo(
        size.width, size.height * 0.6); // Right side middle-bottom
    pathBottomRight.lineTo(size.width, size.height); // Bottom right corner
    pathBottomRight.lineTo(size.width * 0.5, size.height); // Bottom middle
    pathBottomRight.close();

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawPath(pathBottomRight, whitePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
