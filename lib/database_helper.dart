import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'constants.dart';
import 'utils.dart';
import 'seed_data.dart';

int? _firstIntValue(List<Map<String, Object?>>? list) {
  if (list == null || list.isEmpty) return null;
  final map = list.first;
  if (map.isEmpty) return null;
  return map.values.first as int?;
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE business_rules (
        rule_code TEXT PRIMARY KEY,
        rule_name TEXT NOT NULL,
        rule_value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE guest_types (
        guest_type_code TEXT PRIMARY KEY,
        guest_type_name TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        payment_method_code TEXT PRIMARY KEY,
        payment_method_name TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reservation_statuses (
        status_code TEXT PRIMARY KEY,
        status_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE room_statuses (
        status_code TEXT PRIMARY KEY,
        status_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE units (
        unit_code TEXT PRIMARY KEY,
        unit_name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit_type TEXT NOT NULL,
        floor_count INTEGER NOT NULL,
        normal_capacity INTEGER NOT NULL,
        breakfast_included INTEGER NOT NULL,
        max_extra_bed INTEGER NOT NULL,
        max_occupancy INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        description TEXT,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        service_code TEXT PRIMARY KEY,
        service_name TEXT NOT NULL,
        category TEXT NOT NULL,
        pricing_type TEXT NOT NULL,
        unit_price INTEGER,
        description TEXT,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE food_packages (
        service_code TEXT PRIMARY KEY,
        service_name TEXT NOT NULL,
        category TEXT NOT NULL,
        pricing_type TEXT NOT NULL,
        unit_price INTEGER NOT NULL,
        description TEXT,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        pin_code TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE guests (
        guest_id TEXT PRIMARY KEY,
        guest_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        guest_type_code TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reservations (
        reservation_id TEXT PRIMARY KEY,
        guest_id TEXT NOT NULL,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT NOT NULL,
        actual_check_in TEXT,
        actual_check_out TEXT,
        adult_count INTEGER NOT NULL,
        child_count INTEGER NOT NULL DEFAULT 0,
        status_code TEXT NOT NULL,
        payment_method_code TEXT,
        payment_status TEXT DEFAULT 'PENDING',
        grand_total INTEGER NOT NULL,
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE reservation_units (
        id TEXT PRIMARY KEY,
        reservation_id TEXT NOT NULL,
        unit_code TEXT NOT NULL,
        unit_price INTEGER NOT NULL,
        nights INTEGER NOT NULL,
        extra_bed_count INTEGER DEFAULT 0,
        extra_bed_price INTEGER DEFAULT 0,
        subtotal INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reservation_services (
        id TEXT PRIMARY KEY,
        reservation_id TEXT NOT NULL,
        service_code TEXT NOT NULL,
        service_name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price INTEGER NOT NULL,
        subtotal INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reservation_foods (
        id TEXT PRIMARY KEY,
        reservation_id TEXT NOT NULL,
        food_code TEXT NOT NULL,
        food_name TEXT NOT NULL,
        pax_count INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        subtotal INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        payment_id TEXT PRIMARY KEY,
        reservation_id TEXT NOT NULL,
        payment_method_code TEXT NOT NULL,
        amount INTEGER NOT NULL,
        payment_date TEXT DEFAULT CURRENT_TIMESTAMP,
        notes TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_res_guest ON reservations(guest_id)');
    await db.execute('CREATE INDEX idx_res_dates ON reservations(check_in_date, check_out_date)');
    await db.execute('CREATE INDEX idx_res_status ON reservations(status_code)');
    await db.execute('CREATE INDEX idx_ru_res ON reservation_units(reservation_id)');
    await db.execute('CREATE INDEX idx_ru_unit ON reservation_units(unit_code)');
    await db.execute('CREATE INDEX idx_guests_phone ON guests(phone)');

    await SeedData.seed(db);
  }

  // ==================== UNITS ====================

  Future<List<Unit>> getAllUnits() async {
    final db = await database;
    final maps = await db.query('units', orderBy: 'unit_code');
    return maps.map((m) => Unit.fromMap(m)).toList();
  }

  Future<List<Unit>> getAvailableUnits() async {
    final db = await database;
    final maps = await db.query(
      'units',
      where: 'status = ?',
      whereArgs: ['ACTIVE'],
      orderBy: 'unit_code',
    );
    return maps.map((m) => Unit.fromMap(m)).toList();
  }

  Future<Unit?> getUnit(String unitCode) async {
    final db = await database;
    final maps = await db.query(
      'units',
      where: 'unit_code = ?',
      whereArgs: [unitCode],
    );
    if (maps.isNotEmpty) return Unit.fromMap(maps.first);
    return null;
  }

  // ==================== REFERENCE DATA ====================

  Future<List<GuestType>> getGuestTypes() async {
    final db = await database;
    final maps = await db.query('guest_types', orderBy: 'guest_type_code');
    return maps.map((m) => GuestType.fromMap(m)).toList();
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final db = await database;
    final maps = await db.query(
      'payment_methods',
      where: 'status = ?',
      whereArgs: ['ACTIVE'],
      orderBy: 'payment_method_code',
    );
    return maps.map((m) => PaymentMethod.fromMap(m)).toList();
  }

  Future<List<ReservationStatus>> getReservationStatuses() async {
    final db = await database;
    final maps = await db.query('reservation_statuses', orderBy: 'status_code');
    return maps.map((m) => ReservationStatus.fromMap(m)).toList();
  }

  Future<List<FoodPackage>> getFoodPackages() async {
    final db = await database;
    final maps = await db.query(
      'food_packages',
      where: 'status = ?',
      whereArgs: ['ACTIVE'],
      orderBy: 'service_code',
    );
    return maps.map((m) => FoodPackage.fromMap(m)).toList();
  }

  Future<List<Service>> getServices() async {
    final db = await database;
    final maps = await db.query(
      'services',
      where: 'status = ?',
      whereArgs: ['ACTIVE'],
      orderBy: 'service_code',
    );
    return maps.map((m) => Service.fromMap(m)).toList();
  }

  Future<BusinessRule?> getBusinessRule(String ruleCode) async {
    final db = await database;
    final maps = await db.query(
      'business_rules',
      where: 'rule_code = ?',
      whereArgs: [ruleCode],
    );
    if (maps.isNotEmpty) return BusinessRule.fromMap(maps.first);
    return null;
  }

  // ==================== USERS ====================

  Future<User?> getUserByPin(String pin) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'pin_code = ? AND is_active = 1',
      whereArgs: [pin],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  // ==================== GUESTS ====================

  Future<String> createGuest(Guest guest) async {
    final db = await database;
    final id = IdGenerator.generate('GST');
    final map = guest.toMap();
    map['guest_id'] = id;
    await db.insert('guests', map);
    return id;
  }

  Future<void> updateGuest(Guest guest) async {
    final db = await database;
    if (guest.guestId == null) return;
    await db.update(
      'guests',
      guest.toMap(),
      where: 'guest_id = ?',
      whereArgs: [guest.guestId],
    );
  }

  Future<List<Guest>> searchGuests(String query) async {
    final db = await database;
    final maps = await db.query(
      'guests',
      where: 'guest_name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'guest_name',
      limit: 50,
    );
    return maps.map((m) => Guest.fromMap(m)).toList();
  }

  Future<Guest?> getGuestByPhone(String phone) async {
    final db = await database;
    final maps = await db.query(
      'guests',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    if (maps.isNotEmpty) return Guest.fromMap(maps.first);
    return null;
  }

  Future<Guest?> getGuest(String guestId) async {
    final db = await database;
    final maps = await db.query(
      'guests',
      where: 'guest_id = ?',
      whereArgs: [guestId],
    );
    if (maps.isNotEmpty) return Guest.fromMap(maps.first);
    return null;
  }

  // ==================== RESERVATIONS ====================

  Future<String> createReservation(
    Reservation reservation,
    List<ReservationUnit> units,
    List<ReservationService> services,
    List<ReservationFood> foods,
  ) async {
    final db = await database;
    final id = IdGenerator.generate('RES');

    await db.transaction((txn) async {
      final map = reservation.toMap();
      map['reservation_id'] = id;
      await txn.insert('reservations', map);

      for (final unit in units) {
        final unitMap = unit.toMap();
        unitMap['id'] = IdGenerator.generate('RU');
        unitMap['reservation_id'] = id;
        await txn.insert('reservation_units', unitMap);
      }

      for (final svc in services) {
        final svcMap = svc.toMap();
        svcMap['id'] = IdGenerator.generate('RS');
        svcMap['reservation_id'] = id;
        await txn.insert('reservation_services', svcMap);
      }

      for (final food in foods) {
        final foodMap = food.toMap();
        foodMap['id'] = IdGenerator.generate('RF');
        foodMap['reservation_id'] = id;
        await txn.insert('reservation_foods', foodMap);
      }
    });

    return id;
  }

  Future<void> updateReservation(
    String reservationId,
    Reservation reservation,
    List<ReservationUnit> units,
    List<ReservationService> services,
    List<ReservationFood> foods,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.update(
        'reservations',
        reservation.toMap(),
        where: 'reservation_id = ?',
        whereArgs: [reservationId],
      );

      await txn.delete('reservation_units', where: 'reservation_id = ?', whereArgs: [reservationId]);
      await txn.delete('reservation_services', where: 'reservation_id = ?', whereArgs: [reservationId]);
      await txn.delete('reservation_foods', where: 'reservation_id = ?', whereArgs: [reservationId]);

      for (final unit in units) {
        final unitMap = unit.toMap();
        unitMap['id'] = IdGenerator.generate('RU');
        unitMap['reservation_id'] = reservationId;
        await txn.insert('reservation_units', unitMap);
      }
      for (final svc in services) {
        final svcMap = svc.toMap();
        svcMap['id'] = IdGenerator.generate('RS');
        svcMap['reservation_id'] = reservationId;
        await txn.insert('reservation_services', svcMap);
      }
      for (final food in foods) {
        final foodMap = food.toMap();
        foodMap['id'] = IdGenerator.generate('RF');
        foodMap['reservation_id'] = reservationId;
        await txn.insert('reservation_foods', foodMap);
      }
    });
  }

  Future<void> deleteReservation(String reservationId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('reservation_foods', where: 'reservation_id = ?', whereArgs: [reservationId]);
      await txn.delete('reservation_services', where: 'reservation_id = ?', whereArgs: [reservationId]);
      await txn.delete('reservation_units', where: 'reservation_id = ?', whereArgs: [reservationId]);
      await txn.delete('payments', where: 'reservation_id = ?', whereArgs: [reservationId]);
      await txn.delete('reservations', where: 'reservation_id = ?', whereArgs: [reservationId]);
    });
  }

  Future<void> updateReservationStatus(
    String reservationId,
    String newStatus, {
    String? actualTime,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{'status_code': newStatus};
    if (newStatus == AppConstants.statusCheckedIn && actualTime != null) {
      updates['actual_check_in'] = actualTime;
    }
    if (newStatus == AppConstants.statusCheckedOut && actualTime != null) {
      updates['actual_check_out'] = actualTime;
      updates['payment_status'] = 'PAID';
    }
    await db.update(
      'reservations',
      updates,
      where: 'reservation_id = ?',
      whereArgs: [reservationId],
    );
  }

  Future<Reservation?> getReservation(String id) async {
    final db = await database;
    final maps = await db.query(
      'reservations',
      where: 'reservation_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Reservation.fromMap(maps.first);
    return null;
  }

  Future<List<ReservationUnit>> getReservationUnits(String reservationId) async {
    final db = await database;
    final maps = await db.query(
      'reservation_units',
      where: 'reservation_id = ?',
      whereArgs: [reservationId],
    );
    return maps.map((m) => ReservationUnit.fromMap(m)).toList();
  }

  Future<List<ReservationService>> getReservationServices(String reservationId) async {
    final db = await database;
    final maps = await db.query(
      'reservation_services',
      where: 'reservation_id = ?',
      whereArgs: [reservationId],
    );
    return maps.map((m) => ReservationService.fromMap(m)).toList();
  }

  Future<List<ReservationFood>> getReservationFoods(String reservationId) async {
    final db = await database;
    final maps = await db.query(
      'reservation_foods',
      where: 'reservation_id = ?',
      whereArgs: [reservationId],
    );
    return maps.map((m) => ReservationFood.fromMap(m)).toList();
  }

  Future<List<ReservationWithGuest>> getReservationsWithGuest({
    String? statusCode,
    String? searchQuery,
    int limit = 100,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (statusCode != null && statusCode.isNotEmpty) {
      whereClauses.add('r.status_code = ?');
      whereArgs.add(statusCode);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(g.guest_name LIKE ? OR g.phone LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final whereString = whereClauses.isEmpty ? '1=1' : whereClauses.join(' AND ');

    final maps = await db.rawQuery('''
      SELECT r.*, g.guest_name, g.phone,
        IFNULL((SELECT GROUP_CONCAT(u.unit_name, ', ') 
         FROM reservation_units ru2 
         JOIN units u ON ru2.unit_code = u.unit_code 
         WHERE ru2.reservation_id = r.reservation_id), '') as unit_names
      FROM reservations r
      JOIN guests g ON r.guest_id = g.guest_id
      WHERE $whereString
      ORDER BY r.check_in_date DESC, r.created_at DESC
      LIMIT ?
    ''', [...whereArgs, limit]);

    return maps.map((m) => ReservationWithGuest(
      reservationId: (m['reservation_id'] as String?) ?? '',
      guestName: (m['guest_name'] as String?) ?? '',
      phone: (m['phone'] as String?) ?? '',
      unitNames: (m['unit_names'] as String?) ?? '',
      checkInDate: (m['check_in_date'] as String?) ?? '',
      checkOutDate: (m['check_out_date'] as String?) ?? '',
      statusCode: (m['status_code'] as String?) ?? '',
      grandTotal: (m['grand_total'] as int?) ?? 0,
      createdAt: m['created_at'] as String?,
    )).toList();
  }

  // ==================== AVAILABILITY ====================

  Future<bool> isUnitAvailable(
    String unitCode,
    String checkIn,
    String checkOut, {
    String? excludeReservationId,
  }) async {
    final db = await database;
    var query = '''
      SELECT COUNT(*) as count FROM reservation_units ru
      JOIN reservations r ON ru.reservation_id = r.reservation_id
      WHERE ru.unit_code = ?
      AND r.status_code IN (?, ?, ?)
      AND r.check_in_date < ? AND r.check_out_date > ?
    ''';
    var args = <dynamic>[
      unitCode,
      AppConstants.statusPending,
      AppConstants.statusConfirmed,
      AppConstants.statusCheckedIn,
      checkOut,
      checkIn,
    ];

    if (excludeReservationId != null) {
      query += ' AND r.reservation_id != ?';
      args.add(excludeReservationId);
    }

    final result = await db.rawQuery(query, args);
    final count = _firstIntValue(result) ?? 0;
    return count == 0;
  }

  Future<bool> areUnitsAvailable(
    List<String> unitCodes,
    String checkIn,
    String checkOut, {
    String? excludeReservationId,
  }) async {
    for (final code in unitCodes) {
      final available = await isUnitAvailable(
        code,
        checkIn,
        checkOut,
        excludeReservationId: excludeReservationId,
      );
      if (!available) return false;
    }
    return true;
  }

  // ==================== CALENDAR ====================

  Future<List<CalendarCell>> getCalendarMatrix(DateTime startDate, int days) async {
    final db = await database;
    final units = await getAllUnits();
    final cells = <CalendarCell>[];

    final endDate = startDate.add(Duration(days: days));
    final startStr = Formatters.dbDate(startDate);
    final endStr = Formatters.dbDate(endDate);

    final reservations = await db.rawQuery('''
      SELECT ru.unit_code, r.reservation_id, r.check_in_date, r.check_out_date, r.status_code,
        g.guest_name
      FROM reservation_units ru
      JOIN reservations r ON ru.reservation_id = r.reservation_id
      JOIN guests g ON r.guest_id = g.guest_id
      WHERE r.status_code IN (?, ?, ?)
      AND r.check_in_date <= ? AND r.check_out_date >= ?
    ''', [
      AppConstants.statusPending,
      AppConstants.statusConfirmed,
      AppConstants.statusCheckedIn,
      endStr,
      startStr,
    ]);

    final occupied = <String, Map<String, dynamic>>{};
    for (final res in reservations) {
      final resStart = DateTime.parse(res['check_in_date'] as String);
      final resEnd = DateTime.parse(res['check_out_date'] as String);
      final unitCode = res['unit_code'] as String;

      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        if (!date.isBefore(resStart) && date.isBefore(resEnd)) {
          final key = '${unitCode}_${Formatters.dbDate(date)}';
          occupied[key] = {
            'reservation_id': res['reservation_id'],
            'guest_name': res['guest_name'],
          };
        }
      }
    }

    for (final unit in units) {
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final key = '${unit.unitCode}_${Formatters.dbDate(date)}';
        final occ = occupied[key];

        cells.add(CalendarCell(
          unitCode: unit.unitCode,
          unitName: unit.unitName,
          date: date,
          reservationId: occ?['reservation_id'] as String?,
          guestName: occ?['guest_name'] as String?,
          statusCode: occ != null ? 'occupied' : 'available',
        ));
      }
    }

    return cells;
  }

  // ==================== DASHBOARD & REPORTS ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final today = Formatters.dbDate(DateTime.now());

    final checkInResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM reservations
      WHERE status_code = ? AND check_in_date = ?
    ''', [AppConstants.statusConfirmed, today]);

    final checkOutResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM reservations
      WHERE status_code IN (?, ?) AND check_out_date = ?
    ''', [AppConstants.statusCheckedIn, AppConstants.statusCheckedOut, today]);

    final occupiedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM reservations
      WHERE status_code = ?
    ''', [AppConstants.statusCheckedIn]);

    final pendingResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM reservations
      WHERE status_code = ?
    ''', [AppConstants.statusPending]);

    return {
      'check_ins_today': _firstIntValue(checkInResult) ?? 0,
      'check_outs_today': _firstIntValue(checkOutResult) ?? 0,
      'currently_occupied': _firstIntValue(occupiedResult) ?? 0,
      'pending_count': _firstIntValue(pendingResult) ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getOccupancyReport(String month) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT u.unit_code, u.unit_name,
        COUNT(DISTINCT r.reservation_id) as booking_count,
        SUM(ru.nights) as total_nights,
        SUM(ru.subtotal) as revenue
      FROM units u
      LEFT JOIN reservation_units ru ON u.unit_code = ru.unit_code
      LEFT JOIN reservations r ON ru.reservation_id = r.reservation_id
        AND r.status_code IN (?, ?)
        AND strftime('%Y-%m', r.check_in_date) = ?
      GROUP BY u.unit_code
      ORDER BY u.unit_code
    ''', [AppConstants.statusCheckedIn, AppConstants.statusCheckedOut, month]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getRevenueReport(String month) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(ru.subtotal) as unit_revenue,
        SUM(ru.extra_bed_price) as extra_bed_revenue,
        (SELECT SUM(subtotal) FROM reservation_services rs 
         JOIN reservations r2 ON rs.reservation_id = r2.reservation_id
         WHERE strftime('%Y-%m', r2.check_in_date) = ? 
         AND r2.status_code IN (?, ?)) as service_revenue,
        (SELECT SUM(subtotal) FROM reservation_foods rf 
         JOIN reservations r3 ON rf.reservation_id = r3.reservation_id
         WHERE strftime('%Y-%m', r3.check_in_date) = ? 
         AND r3.status_code IN (?, ?)) as food_revenue
      FROM reservation_units ru
      JOIN reservations r ON ru.reservation_id = r.reservation_id
      WHERE strftime('%Y-%m', r.check_in_date) = ?
        AND r.status_code IN (?, ?)
    ''', [
      month, AppConstants.statusCheckedIn, AppConstants.statusCheckedOut,
      month, AppConstants.statusCheckedIn, AppConstants.statusCheckedOut,
      month, AppConstants.statusCheckedIn, AppConstants.statusCheckedOut,
    ]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getGuestTypeDistribution() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT g.guest_type_code, gt.guest_type_name, COUNT(*) as count
      FROM reservations r
      JOIN guests g ON r.guest_id = g.guest_id
      JOIN guest_types gt ON g.guest_type_code = gt.guest_type_code
      WHERE r.status_code IN (?, ?)
      GROUP BY g.guest_type_code
      ORDER BY count DESC
    ''', [AppConstants.statusCheckedIn, AppConstants.statusCheckedOut]);
    return result;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
