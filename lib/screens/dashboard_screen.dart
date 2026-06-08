import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'reservation_form_screen.dart';
import 'reservation_list_screen.dart';
import 'calendar_screen.dart';
import 'report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseHelper().getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        'Check-In Hari Ini',
                        _stats['check_ins_today']?.toString() ?? '0',
                        Colors.green,
                        Icons.login,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Check-Out Hari Ini',
                        _stats['check_outs_today']?.toString() ?? '0',
                        Colors.orange,
                        Icons.logout,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Sedang Menginap',
                        _stats['currently_occupied']?.toString() ?? '0',
                        Colors.blue,
                        Icons.bed,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Pending',
                        _stats['pending_count']?.toString() ?? '0',
                        Colors.purple,
                        Icons.pending,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Menu Cepat',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildActionButton(
                        'Reservasi Baru',
                        Icons.add_circle,
                        Colors.green,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReservationFormScreen()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        'Kalender',
                        Icons.calendar_month,
                        Colors.blue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CalendarScreen()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        'Daftar Reservasi',
                        Icons.list,
                        Colors.orange,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReservationListScreen()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        'Laporan',
                        Icons.bar_chart,
                        Colors.purple,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}