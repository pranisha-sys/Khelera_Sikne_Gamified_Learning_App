import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  String selectedAvatar = '🐨'; // Default avatar
  bool showAvatarPicker = false;
  bool _isLoading = true;

  // Cute avatar options for students
  final List<String> avatarOptions = [
    '🦊', // Fox
    '🐼', // Panda
    '🦁', // Lion
    '🐸', // Frog
    '🐨', // Koala
    '🦄', // Unicorn
    '🐙', // Octopus
    '🦋', // Butterfly
    '🐱', // Cat
    '🐶', // Dog
    '🐰', // Rabbit
    '🐯', // Tiger
    '🦉', // Owl
    '🐵', // Monkey
    '🐷', // Pig
    '🦒', // Giraffe
    '🐻', // Teddy Bear
    '🐹', // Hamster
    '🐣', // Baby Chick
    '🐧', // Penguin
    '🦖', // T-Rex
    '🦕', // Dinosaur
    '🐢', // Turtle
    '🐬', // Dolphin
    '🐠', // Tropical Fish
    '🦜', // Parrot
    '🐝', // Bee
    '🐞', // Lady Beetle
    '🌈', // Rainbow
    '⭐', // Star
    '🍭', // Lollipop
    '🍦', // Ice Cream
    '🧸', // Teddy
    '🎈', // Balloon
    '⚽', // Soccer Ball
    '🚀', // Rocket
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load from SharedPreferences first (quick display)
      setState(() {
        _nameController.text = user?.displayName ?? '';
        _nicknameController.text =
            prefs.getString('student_nickname_${user!.uid}') ?? '';
        selectedAvatar = prefs.getString('student_avatar_${user!.uid}') ?? '🐨';
      });

      // Then load from Firestore
      final userDoc = await _firestore.collection('users').doc(user!.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _nicknameController.text = data['nickname'] ?? '';
          selectedAvatar = data['avatar'] ?? '🐨';
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) {
      _showSnackBar('No user logged in', Colors.red);
      return;
    }

    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter your name', Colors.orange);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1976D2),
        ),
      ),
    );

    try {
      // 1. Update Firebase Auth display name
      await user?.updateDisplayName(_nameController.text);

      // 2. Save to Firestore
      await _firestore.collection('users').doc(user!.uid).set({
        'nickname': _nicknameController.text,
        'avatar': selectedAvatar,
        'display_name': _nameController.text,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true to not overwrite other fields

      // 3. Save to SharedPreferences (offline backup)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'student_nickname_${user!.uid}', _nicknameController.text);
      await prefs.setString('student_avatar_${user!.uid}', selectedAvatar);

      debugPrint('✅ Profile saved successfully:');
      debugPrint('  - Name: ${_nameController.text}');
      debugPrint('  - Nickname: ${_nicknameController.text}');
      debugPrint('  - Avatar: $selectedAvatar');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        _showSnackBar('Profile updated successfully! 🎉', Colors.green);

        // Wait a bit for snackbar to show
        await Future.delayed(const Duration(milliseconds: 500));

        // Return true to indicate success
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to update profile: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF81D4FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1976D2),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Avatar Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar Display
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF81D4FA),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    selectedAvatar,
                                    style: const TextStyle(fontSize: 60),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Change Avatar Button
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showAvatarPicker = !showAvatarPicker;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF81D4FA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Change Avatar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Avatar Picker
                          if (showAvatarPicker) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Choose your avatar:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: avatarOptions.length,
                              itemBuilder: (context, index) {
                                final avatar = avatarOptions[index];
                                final isSelected = avatar == selectedAvatar;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedAvatar = avatar;
                                      showAvatarPicker = false;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF81D4FA)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1976D2)
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        avatar,
                                        style: const TextStyle(fontSize: 36),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Information
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Student Name
                          Text(
                            'Student Name *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              filled: true,
                              fillColor: const Color(0xFFE3F2FD),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF81D4FA),
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1976D2),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Nickname
                          Text(
                            'Nickname',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This name will appear on your welcome screen',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nicknameController,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter a cool nickname (e.g., Ace, Champ)',
                              filled: true,
                              fillColor: const Color(0xFFE3F2FD),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF81D4FA),
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1976D2),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

      // Fixed Save Button at bottom
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
