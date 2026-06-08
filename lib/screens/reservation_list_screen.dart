import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../constants.dart';
import '../utils.dart';
import 'reservation_form_screen.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  final _searchController = TextEditingController();
  List<ReservationWithGuest> _reservations = [];
  String _statusFilter = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper().getReservationsWithGuest(
        statusCode: _statusFilter.isEmpty ? null : _statusFilter,
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _reservations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIn(String id) async {
    try {
      await DatabaseHelper().updateReservationStatus(
        id,
        AppConstants.statusCheckedIn,
        actualTime: Formatters.dbDate(DateTime.now()),
      );
      _load();
    } catch (e) {
      _showError('Gagal check-in: \$e');
    }
  }

  Future<void> _checkOut(String id) async {
    try {
      await DatabaseHelper().updateReservationStatus(
        id,
        AppConstants.statusCheckedOut,
        actualTime: Formatters.dbDate(DateTime.now()),
      );
      _load();
    } catch (e) {
      _showError('Gagal check-out: \$e');
    }
  }

  Future<void> _cancel(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Reservasi'),
        content: const Text('Yakin ingin membatalkan reservasi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DatabaseHelper().updateReservationStatus(id, AppConstants.statusCancelled);
        _load();
      } catch (e) {
        _showError('Gagal membatalkan: \$e');
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Reservasi'),
        content: const Text('Yakin ingin menghapus reservasi ini? Data tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DatabaseHelper().deleteReservation(id);
        _load();
      } catch (e) {
        _showError('Gagal menghapus: \$e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Reservasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReservationFormScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau telepon...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter.isEmpty ? null : _statusFilter,
                  hint: const Text('Filter Status'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Semua')),
                    ...StatusConfig.names.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v ?? '');
                    _load();
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.search),
                  label: const Text('Cari'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _reservations.length,
                    itemBuilder: (_, i) {
                      final res = _reservations[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: StatusConfig.getColor(res.statusCode),
                            child: Text(
                              res.statusCode.substring(3),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text(
                            res.guestName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('\${res.unitNames} \u2022 \${Formatters.displayDate(res.checkInDate)} - \${Formatters.displayDate(res.checkOutDate)}'),
                              Text('\${StatusConfig.getName(res.statusCode)} \u2022 \${Formatters.currency(res.grandTotal)}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              switch (val) {
                                case 'checkin':
                                  _checkIn(res.reservationId);
                                  break;
                                case 'checkout':
                                  _checkOut(res.reservationId);
                                  break;
                                case 'cancel':
                                  _cancel(res.reservationId);
                                  break;
                                case 'delete':
                                  _delete(res.reservationId);
                                  break;
                              }
                            },
                            itemBuilder: (_) => [
                              if (res.statusCode == AppConstants.statusConfirmed)
                                const PopupMenuItem(value: 'checkin', child: Text('Check-In')),
                              if (res.statusCode == AppConstants.statusCheckedIn)
                                const PopupMenuItem(value: 'checkout', child: Text('Check-Out')),
                              if ([AppConstants.statusPending, AppConstants.statusConfirmed].contains(res.statusCode))
                                const PopupMenuItem(value: 'cancel', child: Text('Batalkan')),
                              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}