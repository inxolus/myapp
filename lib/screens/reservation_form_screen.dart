import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../constants.dart';
import '../utils.dart';

class ReservationFormScreen extends StatefulWidget {
  const ReservationFormScreen({super.key});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _adultController = TextEditingController(text: '2');
  final _childController = TextEditingController(text: '0');

  // State
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  GuestType? _selectedGuestType;
  PaymentMethod? _selectedPayment;
  String _statusCode = AppConstants.statusConfirmed;

  // Multi-unit selection
  final List<SelectedUnit> _selectedUnits = [];

  // Services & Foods
  final List<SelectedService> _selectedServices = [];
  final List<SelectedFood> _selectedFoods = [];

  // Reference data
  List<Unit> _allUnits = [];
  List<GuestType> _guestTypes = [];
  List<PaymentMethod> _paymentMethods = [];
  List<ReservationStatus> _statuses = [];
  List<Service> _services = [];
  List<FoodPackage> _foodPackages = [];
  BusinessRule? _extraBedRule;

  bool _isLoading = true;
  String _error = '';
  int _grandTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _adultController.dispose();
    _childController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper();
      final units = await db.getAvailableUnits();
      final guestTypes = await db.getGuestTypes();
      final payments = await db.getPaymentMethods();
      final statuses = await db.getReservationStatuses();
      final services = await db.getServices();
      final foods = await db.getFoodPackages();
      final rule = await db.getBusinessRule(AppConstants.ruleExtraBedPrice);

      if (mounted) {
        setState(() {
          _allUnits = units;
          _guestTypes = guestTypes;
          _paymentMethods = payments;
          _statuses = statuses;
          _services = services;
          _foodPackages = foods;
          _extraBedRule = rule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading data: $e';
          _isLoading = false;
        });
      }
    }
  }

  int get _extraBedPrice => _extraBedRule?.valueAsInt ?? 100000;

  void _calculatePrice() {
    int total = 0;
    for (final su in _selectedUnits) {
      final nights = _checkOut.difference(_checkIn).inDays;
      if (nights > 0 && su.unit != null) {
        final base = su.unit!.unitPrice * nights;
        final extra = su.extraBedCount * _extraBedPrice * nights;
        su.subtotal = base + extra;
        total += su.subtotal;
      }
    }
    for (final svc in _selectedServices) {
      total += svc.subtotal;
    }
    for (final food in _selectedFoods) {
      total += food.subtotal;
    }
    setState(() => _grandTotal = total);
  }

  void _addUnit(Unit unit) {
    if (_selectedUnits.any((u) => u.unit?.unitCode == unit.unitCode)) return;
    setState(() {
      _selectedUnits.add(SelectedUnit(unit: unit));
    });
    _calculatePrice();
  }

  void _removeUnit(int index) {
    setState(() => _selectedUnits.removeAt(index));
    _calculatePrice();
  }

  void _updateUnitExtraBed(int index, int count) {
    if (index < 0 || index >= _selectedUnits.length) return;
    final unit = _selectedUnits[index].unit;
    if (unit != null && count > unit.maxExtraBed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Max extra bed untuk ${unit.unitName}: ${unit.maxExtraBed}')),
      );
      return;
    }
    setState(() => _selectedUnits[index].extraBedCount = count);
    _calculatePrice();
  }

  void _addService(Service service) {
    final existing = _selectedServices.indexWhere((s) => s.serviceCode == service.serviceCode);
    if (existing >= 0) {
      setState(() => _selectedServices[existing].quantity++);
    } else {
      setState(() => _selectedServices.add(SelectedService(
        serviceCode: service.serviceCode,
        serviceName: service.serviceName,
        unitPrice: service.unitPrice ?? 0,
        quantity: 1,
      )));
    }
    _calculatePrice();
  }

  void _removeService(int index) {
    setState(() => _selectedServices.removeAt(index));
    _calculatePrice();
  }

  void _addFood(FoodPackage food) {
    final existing = _selectedFoods.indexWhere((f) => f.foodCode == food.serviceCode);
    if (existing >= 0) {
      setState(() => _selectedFoods[existing].paxCount++);
    } else {
      setState(() => _selectedFoods.add(SelectedFood(
        foodCode: food.serviceCode,
        foodName: food.serviceName,
        unitPrice: food.unitPrice,
        paxCount: 1,
      )));
    }
    _calculatePrice();
  }

  void _removeFood(int index) {
    setState(() => _selectedFoods.removeAt(index));
    _calculatePrice();
  }

  Future<void> _saveReservation() async {
    // Validation
    final nameError = Validators.required(_nameController.text, 'Nama tamu');
    if (nameError != null) {
      _showError(nameError);
      return;
    }
    final phoneError = Validators.phone(_phoneController.text);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }
    if (_selectedUnits.isEmpty) {
      _showError('Pilih minimal 1 unit');
      return;
    }
    final dateError = Validators.dateRange(_checkIn, _checkOut);
    if (dateError != null) {
      _showError(dateError);
      return;
    }

    final adults = int.tryParse(_adultController.text.trim()) ?? 0;
    final children = int.tryParse(_childController.text.trim()) ?? 0;
    final totalGuests = adults + children;

    for (final su in _selectedUnits) {
      if (su.unit == null) continue;
      if (totalGuests > su.unit!.maxOccupancy) {
        _showError('Total tamu ($totalGuests) melebihi kapasitas ${su.unit!.unitName} (${su.unit!.maxOccupancy})');
        return;
      }
    }

    final checkInStr = Formatters.dbDate(_checkIn);
    final checkOutStr = Formatters.dbDate(_checkOut);

    // Double booking check
    final unitCodes = _selectedUnits.where((u) => u.unit != null).map((u) => u.unit!.unitCode).toList();
    final available = await DatabaseHelper().areUnitsAvailable(unitCodes, checkInStr, checkOutStr);
    if (!available) {
      _showError('Salah satu unit sudah terbooking pada tanggal tersebut');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();

      // Create or find guest
      String guestId;
      final existingGuest = await db.getGuestByPhone(_phoneController.text.trim());
      if (existingGuest != null) {
        guestId = existingGuest.guestId!;
        await db.updateGuest(existingGuest.copyWith(
          guestName: _nameController.text.trim(),
          guestTypeCode: _selectedGuestType?.guestTypeCode ?? 'GT001',
        ));
      } else {
        final guest = Guest(
          guestName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          guestTypeCode: _selectedGuestType?.guestTypeCode ?? 'GT001',
        );
        guestId = await db.createGuest(guest);
      }

      final nights = _checkOut.difference(_checkIn).inDays;

      // Build reservation units
      final resUnits = _selectedUnits.where((u) => u.unit != null).map((u) {
        final extraBedTotal = u.extraBedCount * _extraBedPrice * nights;
        final base = u.unit!.unitPrice * nights;
        return ReservationUnit(
          unitCode: u.unit!.unitCode,
          unitPrice: u.unit!.unitPrice,
          nights: nights,
          extraBedCount: u.extraBedCount,
          extraBedPrice: extraBedTotal,
          subtotal: base + extraBedTotal,
        );
      }).toList();

      // Build services
      final resServices = _selectedServices.map((s) => ReservationService(
        serviceCode: s.serviceCode,
        serviceName: s.serviceName,
        quantity: s.quantity,
        unitPrice: s.unitPrice,
        subtotal: s.unitPrice * s.quantity,
      )).toList();

      // Build foods
      final resFoods = _selectedFoods.map((f) => ReservationFood(
        foodCode: f.foodCode,
        foodName: f.foodName,
        paxCount: f.paxCount,
        unitPrice: f.unitPrice,
        subtotal: f.unitPrice * f.paxCount,
      )).toList();

      // Create reservation
      final reservation = Reservation(
        guestId: guestId,
        checkInDate: checkInStr,
        checkOutDate: checkOutStr,
        adultCount: adults,
        childCount: children,
        statusCode: _statusCode,
        paymentMethodCode: _selectedPayment?.paymentMethodCode,
        grandTotal: _grandTotal,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdBy: 'USR001',
      );

      await db.createReservation(reservation, resUnits, resServices, resFoods);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservasi berhasil dibuat!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal menyimpan: $e';
        });
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservasi Baru'),
        actions: [
          TextButton.icon(
            onPressed: _saveReservation,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('SIMPAN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),

            // Guest Info
            _buildSectionTitle('Data Tamu'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tamu *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telepon / WhatsApp *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GuestType>(
              value: _selectedGuestType,
              decoration: const InputDecoration(
                labelText: 'Tipe Tamu',
                border: OutlineInputBorder(),
              ),
              items: _guestTypes.map((gt) {
                return DropdownMenuItem(value: gt, child: Text(gt.guestTypeName));
              }).toList(),
              onChanged: (v) => setState(() => _selectedGuestType = v),
            ),
            const SizedBox(height: 24),

            // Unit Selection
            _buildSectionTitle('Pilih Unit'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _allUnits.map((unit) {
                final isSelected = _selectedUnits.any((u) => u.unit?.unitCode == unit.unitCode);
                return InkWell(
                  onTap: () => isSelected ? null : _addUnit(unit),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.unitName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          Formatters.currency(unit.unitPrice),
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        Text(
                          'Kap: ${unit.normalCapacity} | Max: ${unit.maxOccupancy}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Selected Units with extra bed
            if (_selectedUnits.isNotEmpty) ...[
              const Text('Unit Terpilih:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._selectedUnits.asMap().entries.map((entry) {
                final idx = entry.key;
                final su = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(su.unit?.unitName ?? ''),
                    subtitle: Text('Subtotal: ${Formatters.currency(su.subtotal)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Extra Bed',
                              helperText: 'Rp$_extraBedPrice/bed',
                            ),
                            controller: TextEditingController(text: '${su.extraBedCount}'),
                            onChanged: (v) => _updateUnitExtraBed(idx, int.tryParse(v) ?? 0),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeUnit(idx),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Dates
            _buildSectionTitle('Tanggal'),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker('Check-In', _checkIn, (date) {
                    setState(() => _checkIn = date);
                    if (!_checkOut.isAfter(_checkIn)) {
                      setState(() => _checkOut = _checkIn.add(const Duration(days: 1)));
                    }
                    _calculatePrice();
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePicker('Check-Out', _checkOut, (date) {
                    setState(() => _checkOut = date);
                    _calculatePrice();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Occupancy
            _buildSectionTitle('Jumlah Tamu'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _adultController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dewasa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _childController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Anak',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Services
            _buildSectionTitle('Services'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _services.map((svc) {
                final selected = _selectedServices.where((s) => s.serviceCode == svc.serviceCode).toList();
                final qty = selected.isNotEmpty ? selected.first.quantity : 0;
                return ActionChip(
                  avatar: qty > 0 ? CircleAvatar(child: Text('$qty')) : null,
                  label: Text('${svc.serviceName} ${Formatters.currency(svc.unitPrice ?? 0)}'),
                  onPressed: () => _addService(svc),
                  backgroundColor: qty > 0 ? Colors.blue.shade100 : null,
                );
              }).toList(),
            ),
            if (_selectedServices.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._selectedServices.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                return ListTile(
                  dense: true,
                  title: Text(s.serviceName),
                  subtitle: Text('${s.quantity} x ${Formatters.currency(s.unitPrice)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.orange),
                        onPressed: () {
                          if (s.quantity > 1) {
                            setState(() => s.quantity--);
                          } else {
                            _removeService(idx);
                          }
                          _calculatePrice();
                        },
                      ),
                      Text('${s.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          setState(() => s.quantity++);
                          _calculatePrice();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeService(idx),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),

            // Food Packages
            _buildSectionTitle('Paket Makanan'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _foodPackages.map((food) {
                final selected = _selectedFoods.where((f) => f.foodCode == food.serviceCode).toList();
                final qty = selected.isNotEmpty ? selected.first.paxCount : 0;
                return ActionChip(
                  avatar: qty > 0 ? CircleAvatar(child: Text('$qty')) : null,
                  label: Text('${food.serviceName} ${Formatters.currency(food.unitPrice)}'),
                  onPressed: () => _addFood(food),
                  backgroundColor: qty > 0 ? Colors.green.shade100 : null,
                );
              }).toList(),
            ),
            if (_selectedFoods.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._selectedFoods.asMap().entries.map((entry) {
                final idx = entry.key;
                final f = entry.value;
                return ListTile(
                  dense: true,
                  title: Text(f.foodName),
                  subtitle: Text('${f.paxCount} pax x ${Formatters.currency(f.unitPrice)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.orange),
                        onPressed: () {
                          if (f.paxCount > 1) {
                            setState(() => f.paxCount--);
                          } else {
                            _removeFood(idx);
                          }
                          _calculatePrice();
                        },
                      ),
                      Text('${f.paxCount}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          setState(() => f.paxCount++);
                          _calculatePrice();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFood(idx),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),

            // Payment & Status
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PaymentMethod>(
                    value: _selectedPayment,
                    decoration: const InputDecoration(
                      labelText: 'Metode Pembayaran',
                      border: OutlineInputBorder(),
                    ),
                    items: _paymentMethods.map((pm) {
                      return DropdownMenuItem(value: pm, child: Text(pm.paymentMethodName));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedPayment = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusCode,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.where((s) => [
                      AppConstants.statusPending,
                      AppConstants.statusConfirmed,
                    ].contains(s.statusCode)).map((s) {
                      return DropdownMenuItem(value: s.statusCode, child: Text(s.statusName));
                    }).toList(),
                    onChanged: (v) => setState(() => _statusCode = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Total Price
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Harga:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    Formatters.currency(_grandTotal),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveReservation,
                icon: const Icon(Icons.save),
                label: const Text('SIMPAN RESERVASI', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          Formatters.displayDateOnly(date),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// Helper classes for form state
class SelectedUnit {
  Unit? unit;
  int extraBedCount;
  int subtotal;

  SelectedUnit({this.unit, this.extraBedCount = 0, this.subtotal = 0});
}

class SelectedService {
  final String serviceCode;
  final String serviceName;
  final int unitPrice;
  int quantity;
  int get subtotal => unitPrice * quantity;

  SelectedService({
    required this.serviceCode,
    required this.serviceName,
    required this.unitPrice,
    this.quantity = 1,
  });
}

class SelectedFood {
  final String foodCode;
  final String foodName;
  final int unitPrice;
  int paxCount;
  int get subtotal => unitPrice * paxCount;

  SelectedFood({
    required this.foodCode,
    required this.foodName,
    required this.unitPrice,
    this.paxCount = 1,
  });
}
