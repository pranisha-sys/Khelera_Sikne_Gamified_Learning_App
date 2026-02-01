import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'classfivemain.dart'; // Import the ClassFiveMain dashboard
import 'home_page.dart';
import 'login_page.dart';

class ClassSelectPage extends StatefulWidget {
  const ClassSelectPage({super.key});

  @override
  State<ClassSelectPage> createState() => _ClassSelectPageState();
}

class _ClassSelectPageState extends State<ClassSelectPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _cardsController;

  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _cardsAnimation;

  @override
  void initState() {
    super.initState();

    // Check if user is logged in
    _checkAuthentication();

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    // Cards animation
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardsAnimation = CurvedAnimation(
      parent: _cardsController,
      curve: Curves.easeOut,
    );

    // Start animations in sequence
    _logoController.forward().then((_) {
      _textController.forward().then((_) {
        _cardsController.forward();
      });
    });
  }

  // Check if user is authenticated
  void _checkAuthentication() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User is not logged in, redirect to login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo with animation - Click to go to HomePage
                  FadeTransition(
                    opacity: _logoAnimation,
                    child: ScaleTransition(
                      scale: _logoAnimation,
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to HomePage
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const HomePage()),
                            (route) => false,
                          );
                        },
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0891B2),
                                border: Border.all(
                                  color: const Color(0xFFFBBF24),
                                  width: 4,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.menu_book,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                  Positioned(
                                    top: 10,
                                    child: Icon(
                                      Icons.star,
                                      size: 24,
                                      color: Colors.yellow.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title with animation
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_textAnimation),
                      child: Text(
                        'Choose your class & Start Learning',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cards with staggered animation
                  FadeTransition(
                    opacity: _cardsAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_cardsAnimation),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 30,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1.1,
                        children: const [
                          ClassCard(
                            classNumber: 5,
                            icon: Icons.menu_book,
                            backgroundColor: Color(0xFFE3F2FD),
                            iconColor: Color(0xFF2196F3),
                            numberColor: Color(0xFF2196F3),
                          ),
                          ClassCard(
                            classNumber: 6,
                            icon: Icons.star_border,
                            backgroundColor: Color(0xFFF3E5F5),
                            iconColor: Color(0xFFAB47BC),
                            numberColor: Color(0xFFAB47BC),
                          ),
                          ClassCard(
                            classNumber: 7,
                            icon: Icons.rocket_launch_outlined,
                            backgroundColor: Color(0xFFFCE4EC),
                            iconColor: Color(0xFFEC407A),
                            numberColor: Color(0xFFEC407A),
                          ),
                          ClassCard(
                            classNumber: 8,
                            icon: Icons.science_outlined,
                            backgroundColor: Color(0xFFE8F5E9),
                            iconColor: Color(0xFF66BB6A),
                            numberColor: Color(0xFF66BB6A),
                          ),
                          ClassCard(
                            classNumber: 9,
                            icon: Icons.school_outlined,
                            backgroundColor: Color(0xFFFFF3E0),
                            iconColor: Color(0xFFFF9800),
                            numberColor: Color(0xFFFF9800),
                          ),
                          ClassCard(
                            classNumber: 10,
                            icon: Icons.auto_awesome_outlined,
                            backgroundColor: Color(0xFFE0F7FA),
                            iconColor: Color(0xFF26C6DA),
                            numberColor: Color(0xFF26C6DA),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClassCard extends StatefulWidget {
  final int classNumber;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color numberColor;

  const ClassCard({
    super.key,
    required this.classNumber,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.numberColor,
  });

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isSelected = false;
  late AnimationController _hoverController;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSelected = !_isSelected;
          });
          debugPrint('Class ${widget.classNumber} selected: $_isSelected');

          // Navigate to ClassFiveMain with the selected class number
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassFiveMain(
                classNumber: widget.classNumber,
              ),
            ),
          );
        },
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value * (_isHovered ? 1 : -1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color:
                        _isSelected ? widget.iconColor : widget.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: _isSelected
                        ? Border.all(
                            color: widget.iconColor,
                            width: 3,
                          )
                        : _isHovered
                            ? Border.all(
                                color: widget.iconColor.withOpacity(0.3),
                                width: 2,
                              )
                            : null,
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: widget.iconColor.withOpacity(0.5),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform: _isHovered
                            ? (Matrix4.identity()..translate(0.0, -5.0, 0.0))
                            : Matrix4.identity(),
                        child: Icon(
                          widget.icon,
                          size: 52,
                          color: _isSelected ? Colors.white : widget.iconColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Class',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color:
                              _isSelected ? Colors.white : Colors.cyan.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.classNumber}',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color:
                              _isSelected ? Colors.white : widget.numberColor,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
