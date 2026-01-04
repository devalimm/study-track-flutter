import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/study_session.dart';
import '../config/theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<StudySession> _sessions = [];
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
      _sessions = await _firestoreService.getWeeklySessions(user.uid);
    } catch (e) {
      debugPrint('İstatistik yükleme hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  Map<String, int> get _dailyTotals {
    final Map<String, int> totals = {};
    final now = DateTime.now();
    
    // Son 7 gün için sıfırla
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('dd/MM').format(date);
      totals[key] = 0;
    }
    
    // Oturumları topla
    for (final session in _sessions) {
      final key = DateFormat('dd/MM').format(session.date);
      if (totals.containsKey(key)) {
        totals[key] = totals[key]! + session.durationMinutes;
      }
    }
    
    return totals;
  }

  Map<String, int> get _subjectTotals {
    final Map<String, int> totals = {};
    for (final session in _sessions) {
      totals[session.subject] = (totals[session.subject] ?? 0) + session.durationMinutes;
    }
    return totals;
  }

  int get _totalMinutes {
    return _sessions.fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get _averageDaily {
    if (_sessions.isEmpty) return 0;
    final days = _dailyTotals.values.where((v) => v > 0).length;
    return days > 0 ? _totalMinutes ~/ days : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
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
                    // Özet Kartları
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Haftalık Grafik
                    Text(
                      'Son 7 Gün',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildWeeklyChart(),
                    const SizedBox(height: 24),

                    // Ders Bazlı Özet
                    Text(
                      'Ders Bazlı Çalışma',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildSubjectList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Toplam',
            value: '${_totalMinutes} dk',
            icon: Icons.timer,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Günlük Ort.',
            value: '${_averageDaily} dk',
            icon: Icons.trending_up,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Oturum',
            value: '${_sessions.length}',
            icon: Icons.event_note,
            color: AppTheme.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final dailyData = _dailyTotals;
    final maxY = dailyData.values.isEmpty
        ? 60.0
        : (dailyData.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: dailyData.isEmpty
              ? const Center(child: Text('Henüz veri yok'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY > 0 ? maxY : 60,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} dk',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            final keys = dailyData.keys.toList();
                            if (index < keys.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  keys[index],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: dailyData.entries.toList().asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value.toDouble(),
                            color: AppTheme.primaryColor,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    final subjects = _subjectTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (subjects.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 48,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Henüz çalışma kaydı yok',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maxMinutes = subjects.first.value;

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: subjects.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = subjects[index];
          final percentage = maxMinutes > 0 ? entry.value / maxMinutes : 0.0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                entry.key[0],
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(entry.key),
            subtitle: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
              ),
            ),
            trailing: Text(
              '${entry.value} dk',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
