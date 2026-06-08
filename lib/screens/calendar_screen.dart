import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils.dart';
import 'reservation_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _startDate = DateTime.now();
  final int _days = 14;
  List<CalendarCell> _cells = [];
  List<Unit> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper();
      final cells = await db.getCalendarMatrix(_startDate, _days);
      final units = await db.getAllUnits();
      if (mounted) {
        setState(() {
          _cells = cells;
          _units = units;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _prev() {
    setState(() => _startDate = _startDate.subtract(const Duration(days: 7)));
    _load();
  }

  void _next() {
    setState(() => _startDate = _startDate.add(const Duration(days: 7)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kalender ${Formatters.displayDateOnly(_startDate)} - '
          '${Formatters.displayDateOnly(_startDate.add(Duration(days: _days - 1)))}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _prev,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _next,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend('Tersedia', Colors.green.shade100),
                      const SizedBox(width: 16),
                      _buildLegend('Terbooking', Colors.red),
                      const SizedBox(width: 16),
                      _buildLegend('Check-in', Colors.orange),
                    ],
                  ),
                ),
                Container(
                  height: 50,
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        alignment: Alignment.center,
                        child: const Text(
                          'Unit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...List.generate(_days, (i) {
                        final date = _startDate.add(Duration(days: i));
                        return Container(
                          width: 50,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _weekdayShort(date.weekday),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: _units.map((unit) {
                        return Row(
                          children: [
                            Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                unit.unitName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...List.generate(_days, (i) {
                              final date = _startDate.add(Duration(days: i));
                              final cell = _cells.firstWhere(
                                (c) =>
                                    c.unitCode == unit.unitCode &&
                                    Formatters.dbDate(c.date) ==
                                        Formatters.dbDate(date),
                                orElse: () => CalendarCell(
                                  unitCode: unit.unitCode,
                                  unitName: unit.unitName,
                                  date: date,
                                  statusCode: 'available',
                                ),
                              );
                              final isCheckInDay = cell.reservationId != null &&
                                  Formatters.dbDate(cell.date) ==
                                      Formatters.dbDate(_startDate);
                              final color = cell.statusCode == 'occupied'
                                  ? (isCheckInDay
                                      ? Colors.orange
                                      : Colors.red)
                                  : Colors.green.shade100;

                              return InkWell(
                                onTap: cell.statusCode == 'occupied' &&
                                        cell.reservationId != null
                                    ? () => _showReservationDetail(
                                        cell.reservationId!)
                                    : () => _createNewReservation(unit, date),
                                child: Container(
                                  width: 50,
                                  height: 40,
                                  margin: const EdgeInsets.all(1),
                                  color: color,
                                  child: cell.statusCode == 'occupied'
                                      ? const Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _weekdayShort(int weekday) {
    const days = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
    return days[weekday - 1];
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showReservationDetail(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reservasi ID: $id')),
    );
  }

  void _createNewReservation(Unit unit, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReservationFormScreen(),
      ),
    );
  }
}