import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../utils.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedMonth = '';
  List<Map<String, dynamic>> _occupancy = [];
  List<Map<String, dynamic>> _revenue = [];
  List<Map<String, dynamic>> _guestDist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper();
      final occ = await db.getOccupancyReport(_selectedMonth);
      final rev = await db.getRevenueReport(_selectedMonth);
      final dist = await db.getGuestTypeDistribution();
      if (mounted) {
        setState(() {
          _occupancy = occ;
          _revenue = rev;
          _guestDist = dist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse('$_selectedMonth-01'),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _selectedMonth = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rev = _revenue.isNotEmpty ? _revenue.first : {};
    final unitRev = rev['unit_revenue'] as int? ?? 0;
    final extraBedRev = rev['extra_bed_revenue'] as int? ?? 0;
    final svcRev = rev['service_revenue'] as int? ?? 0;
    final foodRev = rev['food_revenue'] as int? ?? 0;
    final totalRev = unitRev + extraBedRev + svcRev + foodRev;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            label: Text(_selectedMonth, style: const TextStyle(color: Colors.white)),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue Summary
                  const Text('Ringkasan Pendapatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildRevRow('Unit', unitRev),
                          _buildRevRow('Extra Bed', extraBedRev),
                          _buildRevRow('Services', svcRev),
                          _buildRevRow('Food', foodRev),
                          const Divider(),
                          _buildRevRow('TOTAL', totalRev, isTotal: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Occupancy Table
                  const Text('Okupasi per Unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Unit')),
                          DataColumn(label: Text('Booking'), numeric: true),
                          DataColumn(label: Text('Malam'), numeric: true),
                          DataColumn(label: Text('Pendapatan'), numeric: true),
                        ],
                        rows: _occupancy.map((o) {
                          return DataRow(cells: [
                            DataCell(Text(o['unit_name'] as String? ?? '')),
                            DataCell(Text('${o['booking_count'] ?? 0}')),
                            DataCell(Text('${o['total_nights'] ?? 0}')),
                            DataCell(Text(Formatters.currency((o['revenue'] as int?) ?? 0))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Guest Distribution
                  const Text('Distribusi Tamu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Tipe Tamu')),
                          DataColumn(label: Text('Jumlah'), numeric: true),
                        ],
                        rows: _guestDist.map((d) {
                          return DataRow(cells: [
                            DataCell(Text(d['guest_type_name'] as String? ?? '')),
                            DataCell(Text('${d['count'] ?? 0}')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRevRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            Formatters.currency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}