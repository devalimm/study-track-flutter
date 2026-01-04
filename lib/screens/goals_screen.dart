import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/goal.dart';
import '../config/theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  int _dailyGoal = 120;
  int _weeklyGoal = 840;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final user = context.read<AuthProvider>().firebaseUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final goal = await _firestoreService.getGoal(user.uid);
      if (goal != null) {
        _dailyGoal = goal.dailyTargetMinutes;
        _weeklyGoal = goal.weeklyTargetMinutes;
      }
    } catch (e) {
      debugPrint('Hedef yükleme hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveGoal() async {
    final user = context.read<AuthProvider>().firebaseUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final goal = Goal(
        id: user.uid,
        odiserId: user.uid,
        dailyTargetMinutes: _dailyGoal,
        weeklyTargetMinutes: _weeklyGoal,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setGoal(goal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hedefler kaydedildi!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes dk';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '$hours saat $mins dk' : '$hours saat';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedeflerim'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık
                  Icon(
                    Icons.flag_rounded,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Çalışma Hedeflerini Belirle',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hedefler motivasyonunu artırır ve ilerlemeyi takip etmeni sağlar.',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Günlük Hedef
                  _buildGoalCard(
                    title: 'Günlük Hedef',
                    icon: Icons.today,
                    value: _dailyGoal,
                    min: 15,
                    max: 480,
                    divisions: 31,
                    onChanged: (value) => setState(() => _dailyGoal = value.toInt()),
                  ),
                  const SizedBox(height: 16),

                  // Haftalık Hedef
                  _buildGoalCard(
                    title: 'Haftalık Hedef',
                    icon: Icons.date_range,
                    value: _weeklyGoal,
                    min: 60,
                    max: 2400,
                    divisions: 39,
                    onChanged: (value) => setState(() => _weeklyGoal = value.toInt()),
                  ),
                  const SizedBox(height: 32),

                  // Özet
                  Card(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Hedef Özeti',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Her gün ${_formatDuration(_dailyGoal)} çalışarak, '
                            'haftada ${_formatDuration(_weeklyGoal)} hedefine ulaşabilirsin!',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Kaydet Butonu
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveGoal,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Hedefleri Kaydet'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required IconData icon,
    required int value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _formatDuration(value),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ),
            Slider(
              value: value.toDouble(),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(min.toInt()),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  _formatDuration(max.toInt()),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
