import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../config/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _todayMinutes = 0;
  int _dailyGoal = 120;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().firebaseUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Bugünkü oturumları al
      final sessions = await _firestoreService.getTodaysSessions(user.uid);
      _todayMinutes = sessions.fold(0, (sum, s) => sum + s.durationMinutes);

      // Hedefi al
      final goal = await _firestoreService.getGoal(user.uid);
      if (goal != null) {
        _dailyGoal = goal.dailyTargetMinutes;
      }
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  double get _progressPercentage {
    if (_dailyGoal == 0) return 0;
    return (_todayMinutes / _dailyGoal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Merhaba, ${user?.displayName?.split(' ').first ?? 'Öğrenci'}! 👋'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Günlük Özet Kartı
                    _buildSummaryCard(),
                    const SizedBox(height: 24),

                    // Kısayol Butonları
                    Text(
                      'Hızlı Erişim',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bugünkü Çalışma',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _progressPercentage >= 1
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_progressPercentage * 100).toInt()}%',
                    style: TextStyle(
                      color: _progressPercentage >= 1
                          ? AppTheme.success
                          : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_todayMinutes dk',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                      Text(
                        'Hedef: $_dailyGoal dk',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _progressPercentage,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          _progressPercentage >= 1
                              ? AppTheme.success
                              : AppTheme.primaryColor,
                        ),
                      ),
                      Center(
                        child: Icon(
                          _progressPercentage >= 1
                              ? Icons.check_circle
                              : Icons.timer_outlined,
                          size: 32,
                          color: _progressPercentage >= 1
                              ? AppTheme.success
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progressPercentage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  _progressPercentage >= 1 ? AppTheme.success : AppTheme.primaryColor,
                ),
              ),
            ),
            if (_progressPercentage < 1 && _todayMinutes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Hedefe ulaşmak için ${_dailyGoal - _todayMinutes} dk daha çalışmalısın!',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          icon: Icons.play_circle_filled,
          title: 'Çalışmaya Başla',
          subtitle: 'Zamanlayıcı',
          color: AppTheme.primaryColor,
          onTap: () => Navigator.pushNamed(context, '/timer'),
        ),
        _buildActionCard(
          icon: Icons.flag_rounded,
          title: 'Hedeflerim',
          subtitle: 'Düzenle',
          color: AppTheme.secondaryColor,
          onTap: () => Navigator.pushNamed(context, '/goals'),
        ),
        _buildActionCard(
          icon: Icons.bar_chart_rounded,
          title: 'İstatistikler',
          subtitle: 'Görüntüle',
          color: AppTheme.success,
          onTap: () {
            // MainScreen'de Statistics tab'ına geç
            // Bu kısım MainScreen'den kontrol edilmeli
          },
        ),
        _buildActionCard(
          icon: Icons.people_rounded,
          title: 'Topluluk',
          subtitle: 'Paylaşımlar',
          color: AppTheme.accentColor,
          onTap: () {
            // MainScreen'de Community tab'ına geç
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
