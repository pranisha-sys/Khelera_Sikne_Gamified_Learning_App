import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugStatsPage extends StatefulWidget {
  const DebugStatsPage({Key? key}) : super(key: key);

  @override
  State<DebugStatsPage> createState() => _DebugStatsPageState();
}

class _DebugStatsPageState extends State<DebugStatsPage> {
  Map<String, dynamic> allStats = {};

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      allStats = {
        'total_quizzes': prefs.getInt('total_quizzes') ?? 0,
        'total_correct_answers': prefs.getInt('total_correct_answers') ?? 0,
        'total_questions': prefs.getInt('total_questions') ?? 0,
        'last_quiz_score': prefs.getInt('last_quiz_score') ?? 0,
        'last_quiz_percentage': prefs.getInt('last_quiz_percentage') ?? 0,
        'completed_topics': prefs.getStringList('completed_topics') ?? [],
        'all_keys': prefs.getKeys().toList(),
      };
    });

    print('========== DEBUG STATS ==========');
    allStats.forEach((key, value) {
      print('$key: $value');
    });
    print('=================================');
  }

  Future<void> _clearAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('total_quizzes');
    await prefs.remove('total_correct_answers');
    await prefs.remove('total_questions');
    await prefs.remove('last_quiz_score');
    await prefs.remove('last_quiz_percentage');
    await prefs.remove('completed_topics');

    _loadAllStats();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All stats cleared!')),
      );
    }
  }

  Future<void> _addTestStats() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('total_quizzes', 3);
    await prefs.setInt('total_correct_answers', 150);
    await prefs.setInt('total_questions', 18);
    await prefs.setInt('last_quiz_score', 60);
    await prefs.setInt('last_quiz_percentage', 100);
    await prefs
        .setStringList('completed_topics', ['topic1', 'topic2', 'topic3']);

    _loadAllStats();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test stats added!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Stats'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Stats in SharedPreferences:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('Total Quizzes',
                      allStats['total_quizzes']?.toString() ?? '0'),
                  _buildStatRow('Total Coins',
                      allStats['total_correct_answers']?.toString() ?? '0'),
                  _buildStatRow('Total Questions',
                      allStats['total_questions']?.toString() ?? '0'),
                  _buildStatRow('Last Quiz Score',
                      allStats['last_quiz_score']?.toString() ?? '0'),
                  _buildStatRow('Last Quiz %',
                      allStats['last_quiz_percentage']?.toString() ?? '0'),
                  const Divider(),
                  const Text('Completed Topics:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    (allStats['completed_topics'] as List?)?.join(', ') ??
                        'None',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Divider(),
                  const Text('All SharedPreferences Keys:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    (allStats['all_keys'] as List?)?.join(', ') ?? 'None',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadAllStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Reload Stats',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addTestStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Add Test Stats',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _clearAllStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Clear All Stats',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
