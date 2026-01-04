import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../providers/timer_provider.dart';
import '../services/firestore_service.dart';
import '../models/study_session.dart';
import '../config/theme.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _subjects = [
    'Matematik',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Tarih',
    'Coğrafya',
    'Türkçe',
    'İngilizce',
    'Programlama',
    'Diğer',
  ];

  String _selectedSubject = 'Matematik';
  bool _showManualEntry = false;
  final _manualMinutesController = TextEditingController();

  @override
  void dispose() {
    _manualMinutesController.dispose();
    super.dispose();
  }

  Future<void> _saveSession(int minutes) async {
    final user = context.read<AuthProvider>().firebaseUser;
    if (user == null) return;

    final session = StudySession(
      id: const Uuid().v4(),
      odiserId: user.uid,
      subject: _selectedSubject,
      durationMinutes: minutes,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.addStudySession(session);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$minutes dakikalık $_selectedSubject çalışması kaydedildi!'),
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
  }

  void _showSaveDialog() {
    final timerProvider = context.read<TimerProvider>();
    final minutes = timerProvider.stopAndGetMinutes();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çalışmayı Kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Süre: $minutes dakika'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Ders Seçin',
              ),
              items: _subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSubject = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              timerProvider.reset();
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSession(minutes);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _handleManualEntry() {
    final minutes = int.tryParse(_manualMinutesController.text);
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir süre girin'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    _saveSession(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışma Zamanlayıcısı'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() => _showManualEntry = !_showManualEntry);
            },
            icon: Icon(_showManualEntry ? Icons.timer : Icons.edit),
            label: Text(_showManualEntry ? 'Zamanlayıcı' : 'Manuel Ekle'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _showManualEntry ? _buildManualEntry() : _buildTimer(),
      ),
    );
  }

  Widget _buildTimer() {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ders Seçimi
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Ders Seçin',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: _subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSubject = value!);
                timer.setSubject(value!);
              },
            ),
            const SizedBox(height: 48),

            // Timer Display
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 4,
                ),
              ),
              child: Text(
                timer.formattedTime,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontFamily: 'monospace',
                    ),
              ),
            ),
            const SizedBox(height: 48),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                if (timer.seconds > 0)
                  IconButton(
                    onPressed: timer.reset,
                    icon: const Icon(Icons.refresh),
                    iconSize: 32,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                const SizedBox(width: 24),

                // Start/Pause Button
                ElevatedButton(
                  onPressed: timer.isRunning ? timer.pause : timer.start,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    backgroundColor:
                        timer.isRunning ? AppTheme.warning : AppTheme.primaryColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(timer.isRunning ? 'Duraklat' : 'Başlat'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Save Button
                if (timer.seconds > 0 && !timer.isRunning)
                  IconButton(
                    onPressed: _showSaveDialog,
                    icon: const Icon(Icons.save),
                    iconSize: 32,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
              ],
            ),

            if (timer.isRunning)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(
                  '$_selectedSubject çalışıyorsun... 📚',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildManualEntry() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.edit_note_rounded,
          size: 64,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Manuel Çalışma Ekle',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 32),

        // Ders Seçimi
        DropdownButtonFormField<String>(
          value: _selectedSubject,
          decoration: const InputDecoration(
            labelText: 'Ders Seçin',
            prefixIcon: Icon(Icons.book_outlined),
          ),
          items: _subjects
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedSubject = value!);
          },
        ),
        const SizedBox(height: 16),

        // Süre Girişi
        TextFormField(
          controller: _manualMinutesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Süre (dakika)',
            prefixIcon: Icon(Icons.timer_outlined),
            hintText: 'Örn: 45',
          ),
        ),
        const SizedBox(height: 32),

        ElevatedButton.icon(
          onPressed: _handleManualEntry,
          icon: const Icon(Icons.save),
          label: const Text('Kaydet'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          ),
        ),
      ],
    );
  }
}
