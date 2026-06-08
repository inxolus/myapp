import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String dbName = 'saliguri.db';
  static const int dbVersion = 1;

  static const String statusPending = 'RS001';
  static const String statusConfirmed = 'RS002';
  static const String statusCheckedIn = 'RS003';
  static const String statusCheckedOut = 'RS004';
  static const String statusCancelled = 'RS005';
  static const String statusNoShow = 'RS006';

  static const String ruleExtraBedPrice = 'BR001';
  static const String ruleExtraBedBreakfast = 'BR002';
  static const String ruleCheckInTime = 'BR003';
  static const String ruleCheckOutTime = 'BR004';
  static const String ruleMaxReservationYears = 'BR005';

  static const List<String> activeReservationStatuses = [
    statusPending, statusConfirmed, statusCheckedIn,
  ];

  static const List<String> billableStatuses = [
    statusCheckedIn, statusCheckedOut,
  ];
}

class StatusConfig {
  StatusConfig._();

  static const Map<String, String> names = {
    AppConstants.statusPending: 'Pending',
    AppConstants.statusConfirmed: 'Confirmed',
    AppConstants.statusCheckedIn: 'Checked In',
    AppConstants.statusCheckedOut: 'Checked Out',
    AppConstants.statusCancelled: 'Cancelled',
    AppConstants.statusNoShow: 'No Show',
  };

  static String getName(String code) => names[code] ?? code;

  static Color getColor(String code) {
    switch (code) {
      case AppConstants.statusPending:
        return Colors.orange;
      case AppConstants.statusConfirmed:
        return Colors.blue;
      case AppConstants.statusCheckedIn:
        return Colors.green;
      case AppConstants.statusCheckedOut:
        return Colors.grey;
      case AppConstants.statusCancelled:
        return Colors.red;
      case AppConstants.statusNoShow:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }
}