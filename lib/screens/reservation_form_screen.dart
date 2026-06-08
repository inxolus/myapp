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

  // Guest counts (default 2 adults, 0 children)
  int _adultCount = 2;
  int _childCount = 0;

  // Dates
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));

  // Selections
  GuestType? _selectedGuestType;
  PaymentMethod? _selectedPayment;
  String _statusCode = AppConstants.statusConfirmed;

  // Multi-unit selection
  final List<SelectedUnit> _selectedUnits = [];

  // Services & Foods (chip-only)
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

  int get _totalGuests => _adultCount + _childCount;

  int get _maxCapacity {
    int max = 0;
    for (final su in _selectedUnits) {
      if (su.unit != null && su.unit!.maxOccupancy > max) {
        max = su.unit!.maxOccupancy;
      }
    }
    return max;
  }

  bool get _isOverCapacity => _selectedUnits.isNotEmpty && _totalGuests > _maxCapacity;

  void _calculatePrice() {
    int total = 0;
    final nights = _checkOut.difference(_checkIn).inDays;

    for (final su in _selectedUnits) {
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

  void _updateUnitExtraBed(int index, int delta) {
    if (index < 0 || index >= _selectedUnits.length) return;
    final unit = _selectedUnits[index].unit;
    if (unit == null) return;

    final newCount = _selectedUnits[index].extraBedCount + delta;
    if (newCount < 0) return;
    if (newCount > unit.maxExtraBed) {
      _showSnack('Max extra bed untuk ${unit.unitName}: ${unit.maxExtraBed}');
      return;
    }

    setState(() => _selectedUnits[index].extraBedCount = newCount);
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

  void _updateServiceQty(int index, int delta) {
    if (index < 0 || index >= _selectedServices.length) return;
    final newQty = _selectedServices[index].quantity + delta;
    if (newQty <= 0) {
      _removeService(index);
      return;
    }
    setState(() => _selectedServices[index].quantity = newQty);
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

  void _updateFoodQty(int index, int delta) {
    if (index < 0 || index >= _selectedFoods.length) return;
    final newQty = _selectedFoods[index].paxCount + delta;
    if (newQty <= 0) {
      _removeFood(index);
      return;
    }
    setState(() => _selectedFoods[index].paxCount = newQty);
    _calculatePrice();
  }

  Future<void> _saveReservation() async {
    // Validation
    final nameError = Validators.required(_nameController.text, 'Nama tamu');
    if (nameError != null) {
      _showSnack(nameError);
      return;
    }
    final phoneError = Validators.phone(_phoneController.text);
    if (phoneError != null) {
      _showSnack(phoneError);
      return;
    }
    if (_selectedUnits.isEmpty) {
      _showSnack('Pilih minimal 1 unit');
      return;
    }
    final dateError = Validators.dateRange(_checkIn, _checkOut);
    if (dateError != null) {
      _showSnack(dateError);
      return;
    }
    if (_isOverCapacity) {
      _showSnack('Total tamu ($_totalGuests) melebihi kapasitas maksimal $_maxCapacity orang');
      return;
    }

    final checkInStr = Formatters.dbDate(_checkIn);
    final checkOutStr = Formatters.dbDate(_checkOut);

    // Double booking check
    final unitCodes = _selectedUnits.where((u) => u.unit != null).map((u) => u.unit!.unitCode).toList();
    final available = await DatabaseHelper().areUnitsAvailable(unitCodes, checkInStr, checkOutStr);
    if (!available) {
      _showSnack('Salah satu unit sudah terbooking pada tanggal tersebut');
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
        adultCount: _adultCount,
        childCount: _childCount,
        statusCode: _statusCode,
        paymentMethodCode: _selectedPayment?.paymentMethodCode,
        grandTotal: _grandTotal,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdBy: 'USR001',
      );

      await db.createReservation(reservation, resUnits, resServices, resFoods);

      if (mounted) {
        _showSnack('Reservasi berhasil dibuat!', isError: false);
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

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 16)),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _changeDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked == null) return;

    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
    _calculatePrice();
  }

  Widget _buildStepper(String label, int value, VoidCallback onDec, VoidCallback onInc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.orange, size: 32),
          onPressed: onDec,
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
          onPressed: onInc,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservasi Baru', style: TextStyle(fontSize: 22)),
        actions: [
          TextButton.icon(
            onPressed: _saveReservation,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 16)),
              ),

            // ===== SECTION 1: DATA TAMU =====
            _buildSectionHeader('1. Data Tamu', Icons.person),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Tamu *',
                        hintText: 'Contoh: Budi Santoso',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telepon / WhatsApp *',
                        hintText: '08123456789',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<GuestType>(
                      value: _selectedGuestType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Tamu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _guestTypes.map((gt) {
                        return DropdownMenuItem(value: gt, child: Text(gt.guestTypeName, style: const TextStyle(fontSize: 16)));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedGuestType = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ===== SECTION 2: PILIH UNIT =====
            _buildSectionHeader('2. Pilih Unit', Icons.hotel),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Klik unit untuk menambahkan:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _allUnits.map((unit) {
                        final isSelected = _selectedUnits.any((u) => u.unit?.unitCode == unit.unitCode);
                        return InkWell(
                          onTap: () => isSelected ? null : _addUnit(unit),
                          child: Container(
                            width: 160,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unit.unitName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  Formatters.currency(unit.unitPrice),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected ? Colors.white70 : Colors.grey.shade700,
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
                    // Selected units with stepper
                    if (_selectedUnits.isNotEmpty) ...[
                      const Divider(),
                      const Text('Unit Terpilih:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ..._selectedUnits.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final su = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      su.unit?.unitName ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      'Subtotal: ${Formatters.currency(su.subtotal)}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text('Extra Bed: ', style: TextStyle(fontSize: 14)),
                                        _buildStepper(
                                          '',
                                          su.extraBedCount,
                                          () => _updateUnitExtraBed(idx, -1),
                                          () => _updateUnitExtraBed(idx, 1),
                                        ),
                                        Text(' (Rp${Formatters.currency(_extraBedPrice)})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                onPressed: () => _removeUnit(idx),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ===== SECTION 3: TANGGAL & TAMU =====
            _buildSectionHeader('3. Tanggal & Jumlah Tamu', Icons.calendar_today),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateCard('Check-In', _checkIn, () => _changeDate(true)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateCard('Check-Out', _checkOut, () => _changeDate(false)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_checkOut.difference(_checkIn).inDays} malam',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text('Dewasa', style: TextStyle(fontSize: 16)),
                            _buildStepper(
                              '',
                              _adultCount,
                              () => setState(() { if (_adultCount > 0) _adultCount--; _calculatePrice(); }),
                              () => setState(() { _adultCount++; _calculatePrice(); }),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Anak', style: TextStyle(fontSize: 16)),
                            _buildStepper(
                              '',
                              _childCount,
                              () => setState(() { if (_childCount > 0) _childCount--; _calculatePrice(); }),
                              () => setState(() { _childCount++; _calculatePrice(); }),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isOverCapacity)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚠️ Total tamu $_totalGuests melebihi kapasitas maksimal $_maxCapacity orang!',
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ===== SECTION 4: SERVICES =====
            _buildSectionHeader('4. Services (Opsional)', Icons.room_service),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Klik untuk menambahkan:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _services.map((svc) {
                        final selected = _selectedServices.where((s) => s.serviceCode == svc.serviceCode).toList();
                        final qty = selected.isNotEmpty ? selected.first.quantity : 0;
                        final isSelected = qty > 0;
                        return ActionChip(
                          avatar: isSelected ? CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Text('$qty', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                          ) : null,
                          label: Text('${svc.serviceName}\n${Formatters.currency(svc.unitPrice ?? 0)}', textAlign: TextAlign.center),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                          onPressed: () => _addService(svc),
                        );
                      }).toList(),
                    ),
                    // Selected services with stepper
                    if (_selectedServices.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const Text('Services Terpilih:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._selectedServices.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        return ListTile(
                          dense: true,
                          title: Text(s.serviceName, style: const TextStyle(fontSize: 16)),
                          subtitle: Text('${Formatters.currency(s.unitPrice)} x ${s.quantity} = ${Formatters.currency(s.subtotal)}'),
                          trailing: _buildStepper('', s.quantity,
                            () => _updateServiceQty(idx, -1),
                            () => _updateServiceQty(idx, 1),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ===== SECTION 5: FOOD PACKAGES =====
            _buildSectionHeader('5. Paket Makanan (Opsional)', Icons.restaurant),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Klik untuk menambahkan:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _foodPackages.map((food) {
                        final selected = _selectedFoods.where((f) => f.foodCode == food.serviceCode).toList();
                        final qty = selected.isNotEmpty ? selected.first.paxCount : 0;
                        final isSelected = qty > 0;
                        return ActionChip(
                          avatar: isSelected ? CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Text('$qty', style: const TextStyle(fontSize: 12, color: Colors.green)),
                          ) : null,
                          label: Text('${food.serviceName}\n${Formatters.currency(food.unitPrice)}', textAlign: TextAlign.center),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
                          onPressed: () => _addFood(food),
                        );
                      }).toList(),
                    ),
                    if (_selectedFoods.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const Text('Makanan Terpilih:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._selectedFoods.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final f = entry.value;
                        return ListTile(
                          dense: true,
                          title: Text(f.foodName, style: const TextStyle(fontSize: 16)),
                          subtitle: Text('${Formatters.currency(f.unitPrice)} x ${f.paxCount} pax = ${Formatters.currency(f.subtotal)}'),
                          trailing: _buildStepper('', f.paxCount,
                            () => _updateFoodQty(idx, -1),
                            () => _updateFoodQty(idx, 1),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ===== SECTION 6: PEMBAYARAN & STATUS =====
            _buildSectionHeader('6. Pembayaran & Status', Icons.payment),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PaymentMethod>(
                        value: _selectedPayment,
                        decoration: const InputDecoration(
                          labelText: 'Metode Pembayaran',
                          border: OutlineInputBorder(),
                        ),
                        items: _paymentMethods.map((pm) {
                          return DropdownMenuItem(value: pm, child: Text(pm.paymentMethodName, style: const TextStyle(fontSize: 16)));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedPayment = v),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          return DropdownMenuItem(value: s.statusCode, child: Text(s.statusName, style: const TextStyle(fontSize: 16)));
                        }).toList(),
                        onChanged: (v) => setState(() => _statusCode = v!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                hintText: 'Contoh: Tamu minta extra pillow',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // ===== TOTAL & SAVE =====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Harga:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        Formatters.currency(_grandTotal),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_checkOut.difference(_checkIn).inDays} malam • ${_totalGuests} tamu • ${_selectedUnits.length} unit',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _saveReservation,
                icon: const Icon(Icons.save, size: 28),
                label: const Text('SIMPAN RESERVASI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              Formatters.displayDateOnly(date),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper classes
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