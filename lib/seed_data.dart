import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class SeedData {
  SeedData._();

  static final List<Map<String, dynamic>> businessRules = [
    {'rule_code': 'BR001', 'rule_name': 'EXTRA_BED_PRICE', 'rule_value': '100000'},
    {'rule_code': 'BR002', 'rule_name': 'EXTRA_BED_INCLUDE_BREAKFAST', 'rule_value': 'TRUE'},
    {'rule_code': 'BR003', 'rule_name': 'CHECK_IN_TIME', 'rule_value': '14:00'},
    {'rule_code': 'BR004', 'rule_name': 'CHECK_OUT_TIME', 'rule_value': '12:00'},
    {'rule_code': 'BR005', 'rule_name': 'MAX_RESERVATION_YEARS', 'rule_value': '10'},
  ];

  static final List<Map<String, dynamic>> guestTypes = [
    {'guest_type_code': 'GT001', 'guest_type_name': 'Regular', 'description': 'Tamu umum'},
    {'guest_type_code': 'GT002', 'guest_type_name': 'Corporate', 'description': 'Instansi atau perusahaan'},
    {'guest_type_code': 'GT003', 'guest_type_name': 'Wedding', 'description': 'Tamu paket wedding'},
    {'guest_type_code': 'GT004', 'guest_type_name': 'Family', 'description': 'Liburan keluarga'},
    {'guest_type_code': 'GT005', 'guest_type_name': 'Group', 'description': 'Rombongan besar'},
  ];

  static final List<Map<String, dynamic>> paymentMethods = [
    {'payment_method_code': 'PM001', 'payment_method_name': 'Cash', 'status': 'ACTIVE'},
    {'payment_method_code': 'PM002', 'payment_method_name': 'Transfer BCA', 'status': 'ACTIVE'},
    {'payment_method_code': 'PM003', 'payment_method_name': 'Transfer BRI', 'status': 'ACTIVE'},
    {'payment_method_code': 'PM004', 'payment_method_name': 'Transfer Mandiri', 'status': 'ACTIVE'},
    {'payment_method_code': 'PM005', 'payment_method_name': 'QRIS', 'status': 'ACTIVE'},
  ];

  static final List<Map<String, dynamic>> reservationStatuses = [
    {'status_code': 'RS001', 'status_name': 'Pending'},
    {'status_code': 'RS002', 'status_name': 'Confirmed'},
    {'status_code': 'RS003', 'status_name': 'Checked In'},
    {'status_code': 'RS004', 'status_name': 'Checked Out'},
    {'status_code': 'RS005', 'status_name': 'Cancelled'},
    {'status_code': 'RS006', 'status_name': 'No Show'},
  ];

  static final List<Map<String, dynamic>> roomStatuses = [
    {'status_code': 'RM001', 'status_name': 'Available'},
    {'status_code': 'RM002', 'status_name': 'Occupied'},
    {'status_code': 'RM003', 'status_name': 'Maintenance'},
    {'status_code': 'RM004', 'status_name': 'Blocked'},
  ];

  static final List<Map<String, dynamic>> units = [
    {'unit_code': 'V001', 'unit_name': 'Room 1', 'category': 'ACCOMMODATION', 'unit_type': 'ROOM', 'floor_count': 1, 'normal_capacity': 2, 'breakfast_included': 2, 'max_extra_bed': 3, 'max_occupancy': 5, 'unit_price': 600000, 'description': '1 bed besar, TV, AC, water heater, toilet, wifi', 'status': 'ACTIVE'},
    {'unit_code': 'V002', 'unit_name': 'Room 2', 'category': 'ACCOMMODATION', 'unit_type': 'ROOM', 'floor_count': 1, 'normal_capacity': 2, 'breakfast_included': 2, 'max_extra_bed': 3, 'max_occupancy': 5, 'unit_price': 600000, 'description': '1 bed besar, TV, AC, water heater, toilet, wifi', 'status': 'ACTIVE'},
    {'unit_code': 'V003', 'unit_name': 'Room 3', 'category': 'ACCOMMODATION', 'unit_type': 'ROOM', 'floor_count': 1, 'normal_capacity': 2, 'breakfast_included': 2, 'max_extra_bed': 6, 'max_occupancy': 8, 'unit_price': 500000, 'description': '1 bed besar, TV, AC, water heater, toilet, wifi', 'status': 'ACTIVE'},
    {'unit_code': 'V004', 'unit_name': 'Room 4', 'category': 'ACCOMMODATION', 'unit_type': 'ROOM', 'floor_count': 1, 'normal_capacity': 2, 'breakfast_included': 2, 'max_extra_bed': 6, 'max_occupancy': 8, 'unit_price': 500000, 'description': '1 bed besar, TV, AC, water heater, toilet, wifi', 'status': 'ACTIVE'},
    {'unit_code': 'V005', 'unit_name': 'Room 5', 'category': 'ACCOMMODATION', 'unit_type': 'ROOM', 'floor_count': 2, 'normal_capacity': 4, 'breakfast_included': 4, 'max_extra_bed': 3, 'max_occupancy': 7, 'unit_price': 900000, 'description': 'Lt1 bed besar, Lt2 single bed, TV, AC, water heater, wifi, kipas angin', 'status': 'ACTIVE'},
    {'unit_code': 'V006', 'unit_name': 'Room 6', 'category': 'ACCOMMODATION', 'unit_type': 'ROOM', 'floor_count': 2, 'normal_capacity': 4, 'breakfast_included': 4, 'max_extra_bed': 3, 'max_occupancy': 7, 'unit_price': 900000, 'description': 'Lt1 bed besar, Lt2 single bed, TV, AC, water heater, wifi, kipas angin', 'status': 'ACTIVE'},
    {'unit_code': 'V007', 'unit_name': 'Room 7', 'category': 'ACCOMMODATION', 'unit_type': 'ROOM', 'floor_count': 1, 'normal_capacity': 2, 'breakfast_included': 2, 'max_extra_bed': 3, 'max_occupancy': 5, 'unit_price': 600000, 'description': '1 bed besar, TV, AC, water heater, toilet, wifi', 'status': 'ACTIVE'},
    {'unit_code': 'V008', 'unit_name': 'Room 8', 'category': 'ACCOMMODATION', 'unit_type': 'ROOM', 'floor_count': 2, 'normal_capacity': 5, 'breakfast_included': 5, 'max_extra_bed': 4, 'max_occupancy': 9, 'unit_price': 1400000, 'description': '2 bed besar, TV, AC, water heater, wifi, kipas angin, toilet dalam & luar', 'status': 'ACTIVE'},
    {'unit_code': 'V009', 'unit_name': 'Villa 9', 'category': 'ACCOMMODATION', 'unit_type': 'VILLA', 'floor_count': 2, 'normal_capacity': 6, 'breakfast_included': 6, 'max_extra_bed': 9, 'max_occupancy': 15, 'unit_price': 2200000, 'description': 'Lt1 1 bed besar, Lt2 1 bed besar + 2 single bed, ruang tamu, sofa, dapur mini, AC, TV, kulkas, dispenser, wifi, 2 kamar mandi water heater', 'status': 'ACTIVE'},
    {'unit_code': 'V010', 'unit_name': 'Villa 10', 'category': 'ACCOMMODATION', 'unit_type': 'VILLA', 'floor_count': 2, 'normal_capacity': 8, 'breakfast_included': 8, 'max_extra_bed': 12, 'max_occupancy': 20, 'unit_price': 3300000, 'description': 'Lt1 1 bed besar + 1 single bed, Lt2 2 bed besar + 2 single bed, ruang tamu, sofa, dapur mini, TV, 2 AC, kulkas, dispenser, wifi, 3 kamar mandi water heater', 'status': 'ACTIVE'},
    {'unit_code': 'A001', 'unit_name': 'Aula', 'category': 'VENUE', 'unit_type': 'HALL', 'floor_count': 1, 'normal_capacity': 90, 'breakfast_included': 0, 'max_extra_bed': 0, 'max_occupancy': 90, 'unit_price': 3000000, 'description': 'Ukuran 8x16 meter, kapasitas 90 orang, meja kursi, panggung, podium, sound system, infocus, mushola, 3 toilet', 'status': 'ACTIVE'},
  ];

  static final List<Map<String, dynamic>> services = [
    {'service_code': 'EX001', 'service_name': 'Extra Bed', 'category': 'ACCOMMODATION', 'pricing_type': 'PER_UNIT', 'unit_price': 100000, 'description': 'Include breakfast', 'status': 'ACTIVE'},
    {'service_code': 'EV001', 'service_name': 'Intimate Wedding', 'category': 'EVENT', 'pricing_type': 'CUSTOM', 'unit_price': 7500000, 'description': 'Paket intimate wedding', 'status': 'ACTIVE'},
  ];

  static final List<Map<String, dynamic>> foodPackages = [
    {'service_code': 'FOOD001', 'service_name': 'Paket Prasmanan A', 'category': 'CATERING', 'pricing_type': 'PER_PERSON', 'unit_price': 60000, 'description': '2 lauk, sayur/gulai, sambal, kerupuk, buah, air mineral', 'status': 'ACTIVE'},
    {'service_code': 'FOOD002', 'service_name': 'Paket Prasmanan B', 'category': 'CATERING', 'pricing_type': 'PER_PERSON', 'unit_price': 45000, 'description': '1 lauk, sayur/gulai, sambal, kerupuk, buah, air mineral', 'status': 'ACTIVE'},
    {'service_code': 'FOOD003', 'service_name': 'Paket BBQ', 'category': 'CATERING', 'pricing_type': 'PER_PERSON', 'unit_price': 60000, 'description': 'Ayam/ikan bakar, tempe/tahu, sambal, lalapan, kerupuk', 'status': 'ACTIVE'},
    {'service_code': 'FOOD004', 'service_name': 'Nasi Kotak', 'category': 'CATERING', 'pricing_type': 'PER_PERSON', 'unit_price': 40000, 'description': '1 lauk, sayur/gulai, kerupuk, buah', 'status': 'ACTIVE'},
    {'service_code': 'FOOD005', 'service_name': 'Nasi Bungkus', 'category': 'CATERING', 'pricing_type': 'PER_PERSON', 'unit_price': 25000, 'description': 'Nasi bungkus', 'status': 'ACTIVE'},
    {'service_code': 'FOOD006', 'service_name': 'Coffee Break', 'category': 'CATERING', 'pricing_type': 'PER_PERSON', 'unit_price': 15000, 'description': 'Snack, kopi/teh', 'status': 'ACTIVE'},
    {'service_code': 'FOOD007', 'service_name': 'BBQ Paket Hemat', 'category': 'CATERING', 'pricing_type': 'PER_PACKAGE', 'unit_price': 250000, 'description': '1 ekor ayam, nasi, sambal, lalapan', 'status': 'ACTIVE'},
    {'service_code': 'FOOD008', 'service_name': 'Kambing Guling', 'category': 'CATERING', 'pricing_type': 'PER_PACKAGE', 'unit_price': 3500000, 'description': '1 ekor kambing, acar, sambal kecap, lalapan', 'status': 'ACTIVE'},
  ];

  static final List<Map<String, dynamic>> users = [
    {'user_id': 'USR001', 'username': 'manager', 'role': 'MANAGER', 'pin_code': '1234', 'is_active': 1},
  ];

  static Future<void> seed(Database db) async {
    // Attempt to load from CSV if available; otherwise fallback to static data
    try {
      await rootBundle.loadString('assets/data/seed.csv');
      // CSV parsing can be implemented here if seed.csv is provided
    } catch (_) {
      // Fallback to static seed data
    }

    for (final r in businessRules) {
      await db.insert('business_rules', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final r in guestTypes) {
      await db.insert('guest_types', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final r in paymentMethods) {
      await db.insert('payment_methods', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final r in reservationStatuses) {
      await db.insert('reservation_statuses', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final r in roomStatuses) {
      await db.insert('room_statuses', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final r in units) {
      await db.insert('units', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final r in services) {
      await db.insert('services', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final r in foodPackages) {
      await db.insert('food_packages', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final r in users) {
      await db.insert('users', r, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
