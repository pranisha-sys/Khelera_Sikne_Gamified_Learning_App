import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart'; // Uncomment after running: flutter pub add file_picker

class ImportQuestionsPage extends StatefulWidget {
  const ImportQuestionsPage({super.key});

  @override
  State<ImportQuestionsPage> createState() => _ImportQuestionsPageState();
}

class _ImportQuestionsPageState extends State<ImportQuestionsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isUploading = false;
  bool _isProcessing = false;
  double _uploadProgress = 0.0;

  // Supported file types
  final List<String> _supportedExtensions = ['pdf', 'doc', 'docx'];

  Future<void> _pickFile() async {
    // Show instruction message
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Step 1: Run "flutter pub add file_picker" in terminal\nStep 2: Uncomment the file_picker code'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );

    // TODO: After adding file_picker package, uncomment the code below:
    /*
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedExtensions,
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFilePath = result.files.single.path;
          if (!kIsWeb && result.files.single.path != null) {
            _selectedFile = File(result.files.single.path!);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: $_selectedFileName'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    */
  }

  Future<void> _uploadAndProcessFile() async {
    if (_selectedFile == null && _selectedFilePath == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please install file_picker package first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: After adding file_picker, uncomment upload logic below:
    /*
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String storagePath = 'quiz_imports/${user.uid}/${timestamp}_$_selectedFileName';

      UploadTask uploadTask;

      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: _supportedExtensions,
          withData: true,
        );
        if (result != null && result.files.single.bytes != null) {
          uploadTask = _storage.ref(storagePath).putData(result.files.single.bytes!);
        } else {
          throw Exception('Failed to read file data');
        }
      } else {
        uploadTask = _storage.ref(storagePath).putFile(_selectedFile!);
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _isUploading = false;
          _isProcessing = true;
        });
      }

      final docRef = await _firestore.collection('imported_files').add({
        'userId': user.uid,
        'fileName': _selectedFileName,
        'fileUrl': downloadUrl,
        'storagePath': storagePath,
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'processing',
        'fileType': _selectedFileName!.split('.').last,
      });

      await Future.delayed(const Duration(seconds: 2));

      await docRef.update({
        'status': 'completed',
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully! 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        _showSuccessDialog(docRef.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    */
  }

  void _showSuccessDialog(String documentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your file has been uploaded and is ready for review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Review Questions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeSelectedFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFilePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Questions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Upload a document to auto-generate questions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Upload Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 60,
                            color: Color(0xFF3B82F6),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Upload Your File',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Drop your file here or click to browse',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Upload Area
                        if (_selectedFileName == null)
                          InkWell(
                            onTap: _isUploading || _isProcessing
                                ? null
                                : _pickFile,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(48),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF3B82F6),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: const Color(0xFFEFF6FF),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6)
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.upload_file,
                                      size: 48,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Drag & drop here',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _isUploading || _isProcessing
                                        ? null
                                        : _pickFile,
                                    icon: const Icon(Icons.upload_file,
                                        color: Colors.white),
                                    label: const Text(
                                      'Upload File',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Selected File Display
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getFileIcon(_selectedFileName!),
                                    size: 32,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFileName!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getFileType(_selectedFileName!),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isUploading && !_isProcessing)
                                  IconButton(
                                    onPressed: _removeSelectedFile,
                                    icon: const Icon(Icons.close),
                                    color: const Color(0xFFEF4444),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Upload Progress
                        if (_isUploading)
                          Column(
                            children: [
                              LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3B82F6),
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                        // Processing Indicator
                        if (_isProcessing)
                          const Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3B82F6),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Processing your file...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 32),

                        // Supported Formats Info
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Color(0xFFCA8A04),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Supported Formats',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF854D0E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildFormatItem(Icons.picture_as_pdf, 'PDF',
                                  'Portable Document Format'),
                              const SizedBox(height: 8),
                              _buildFormatItem(Icons.description, 'DOC/DOCX',
                                  'Microsoft Word Document'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tips Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBBF24),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Setup Instructions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTipItem(
                                '1️⃣ Run: flutter pub add file_picker',
                              ),
                              _buildTipItem(
                                '2️⃣ Uncomment the file picker code in import_questions_page.dart',
                              ),
                              _buildTipItem(
                                '3️⃣ Add Firebase Storage rules (see README)',
                              ),
                              _buildTipItem(
                                '4️⃣ Maximum file size: 10MB',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Upload Button
              if (_selectedFileName != null && !_isUploading && !_isProcessing)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _uploadAndProcessFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Upload & Generate Questions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFCA8A04), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF854D0E),
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        tip,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1E40AF),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toUpperCase();
    return '$extension Document';
  }
}
