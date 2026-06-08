class Unit {
  final String unitCode;
  final String unitName;
  final String category;
  final String unitType;
  final int floorCount;
  final int normalCapacity;
  final int breakfastIncluded;
  final int maxExtraBed;
  final int maxOccupancy;
  final int unitPrice;
  final String description;
  final String status;

  const Unit({
    required this.unitCode,
    required this.unitName,
    required this.category,
    required this.unitType,
    required this.floorCount,
    required this.normalCapacity,
    required this.breakfastIncluded,
    required this.maxExtraBed,
    required this.maxOccupancy,
    required this.unitPrice,
    required this.description,
    required this.status,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      unitCode: (map['unit_code'] as String?) ?? '',
      unitName: (map['unit_name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      unitType: (map['unit_type'] as String?) ?? '',
      floorCount: (map['floor_count'] as int?) ?? 0,
      normalCapacity: (map['normal_capacity'] as int?) ?? 0,
      breakfastIncluded: (map['breakfast_included'] as int?) ?? 0,
      maxExtraBed: (map['max_extra_bed'] as int?) ?? 0,
      maxOccupancy: (map['max_occupancy'] as int?) ?? 0,
      unitPrice: (map['unit_price'] as int?) ?? 0,
      description: (map['description'] as String?) ?? '',
      status: (map['status'] as String?) ?? '',
    );
  }
}

class GuestType {
  final String guestTypeCode;
  final String guestTypeName;
  final String description;

  const GuestType({
    required this.guestTypeCode,
    required this.guestTypeName,
    required this.description,
  });

  factory GuestType.fromMap(Map<String, dynamic> map) {
    return GuestType(
      guestTypeCode: (map['guest_type_code'] as String?) ?? '',
      guestTypeName: (map['guest_type_name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
    );
  }
}

class PaymentMethod {
  final String paymentMethodCode;
  final String paymentMethodName;
  final String status;

  const PaymentMethod({
    required this.paymentMethodCode,
    required this.paymentMethodName,
    required this.status,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      paymentMethodCode: (map['payment_method_code'] as String?) ?? '',
      paymentMethodName: (map['payment_method_name'] as String?) ?? '',
      status: (map['status'] as String?) ?? '',
    );
  }
}

class ReservationStatus {
  final String statusCode;
  final String statusName;

  const ReservationStatus({
    required this.statusCode,
    required this.statusName,
  });

  factory ReservationStatus.fromMap(Map<String, dynamic> map) {
    return ReservationStatus(
      statusCode: (map['status_code'] as String?) ?? '',
      statusName: (map['status_name'] as String?) ?? '',
    );
  }
}

class BusinessRule {
  final String ruleCode;
  final String ruleName;
  final String ruleValue;

  const BusinessRule({
    required this.ruleCode,
    required this.ruleName,
    required this.ruleValue,
  });

  factory BusinessRule.fromMap(Map<String, dynamic> map) {
    return BusinessRule(
      ruleCode: (map['rule_code'] as String?) ?? '',
      ruleName: (map['rule_name'] as String?) ?? '',
      ruleValue: (map['rule_value'] as String?) ?? '',
    );
  }

  int? get valueAsInt => int.tryParse(ruleValue);
  bool get valueAsBool => ruleValue.toUpperCase() == 'TRUE';
}

class FoodPackage {
  final String serviceCode;
  final String serviceName;
  final String category;
  final String pricingType;
  final int unitPrice;
  final String? description;
  final String status;

  const FoodPackage({
    required this.serviceCode,
    required this.serviceName,
    required this.category,
    required this.pricingType,
    required this.unitPrice,
    this.description,
    required this.status,
  });

  factory FoodPackage.fromMap(Map<String, dynamic> map) {
    return FoodPackage(
      serviceCode: (map['service_code'] as String?) ?? '',
      serviceName: (map['service_name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      pricingType: (map['pricing_type'] as String?) ?? '',
      unitPrice: (map['unit_price'] as int?) ?? 0,
      description: map['description'] as String?,
      status: (map['status'] as String?) ?? '',
    );
  }
}

class Service {
  final String serviceCode;
  final String serviceName;
  final String category;
  final String pricingType;
  final int? unitPrice;
  final String? description;
  final String status;

  const Service({
    required this.serviceCode,
    required this.serviceName,
    required this.category,
    required this.pricingType,
    this.unitPrice,
    this.description,
    required this.status,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      serviceCode: (map['service_code'] as String?) ?? '',
      serviceName: (map['service_name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      pricingType: (map['pricing_type'] as String?) ?? '',
      unitPrice: map['unit_price'] as int?,
      description: map['description'] as String?,
      status: (map['status'] as String?) ?? '',
    );
  }
}

class User {
  final String userId;
  final String username;
  final String role;
  final String pinCode;
  final bool isActive;

  const User({
    required this.userId,
    required this.username,
    required this.role,
    required this.pinCode,
    required this.isActive,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: (map['user_id'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      role: (map['role'] as String?) ?? '',
      pinCode: (map['pin_code'] as String?) ?? '',
      isActive: (map['is_active'] as int?) == 1,
    );
  }
}

class Guest {
  final String? guestId;
  final String guestName;
  final String phone;
  final String? email;
  final String guestTypeCode;
  final String? notes;

  const Guest({
    this.guestId,
    required this.guestName,
    required this.phone,
    this.email,
    required this.guestTypeCode,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'guest_id': guestId,
      'guest_name': guestName,
      'phone': phone,
      'email': email,
      'guest_type_code': guestTypeCode,
      'notes': notes,
    };
  }

  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      guestId: map['guest_id'] as String?,
      guestName: (map['guest_name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      email: map['email'] as String?,
      guestTypeCode: (map['guest_type_code'] as String?) ?? '',
      notes: map['notes'] as String?,
    );
  }

  Guest copyWith({
    String? guestId,
    String? guestName,
    String? phone,
    String? email,
    String? guestTypeCode,
    String? notes,
  }) {
    return Guest(
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      guestTypeCode: guestTypeCode ?? this.guestTypeCode,
      notes: notes ?? this.notes,
    );
  }
}

class Reservation {
  final String? reservationId;
  final String guestId;
  final String checkInDate;
  final String checkOutDate;
  final String? actualCheckIn;
  final String? actualCheckOut;
  final int adultCount;
  final int childCount;
  final String statusCode;
  final String? paymentMethodCode;
  final String paymentStatus;
  final int grandTotal;
  final String? notes;
  final String createdBy;
  final String? createdAt;

  const Reservation({
    this.reservationId,
    required this.guestId,
    required this.checkInDate,
    required this.checkOutDate,
    this.actualCheckIn,
    this.actualCheckOut,
    required this.adultCount,
    required this.childCount,
    required this.statusCode,
    this.paymentMethodCode,
    this.paymentStatus = 'PENDING',
    required this.grandTotal,
    this.notes,
    required this.createdBy,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reservation_id': reservationId,
      'guest_id': guestId,
      'check_in_date': checkInDate,
      'check_out_date': checkOutDate,
      'actual_check_in': actualCheckIn,
      'actual_check_out': actualCheckOut,
      'adult_count': adultCount,
      'child_count': childCount,
      'status_code': statusCode,
      'payment_method_code': paymentMethodCode,
      'payment_status': paymentStatus,
      'grand_total': grandTotal,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      reservationId: map['reservation_id'] as String?,
      guestId: (map['guest_id'] as String?) ?? '',
      checkInDate: (map['check_in_date'] as String?) ?? '',
      checkOutDate: (map['check_out_date'] as String?) ?? '',
      actualCheckIn: map['actual_check_in'] as String?,
      actualCheckOut: map['actual_check_out'] as String?,
      adultCount: (map['adult_count'] as int?) ?? 0,
      childCount: (map['child_count'] as int?) ?? 0,
      statusCode: (map['status_code'] as String?) ?? '',
      paymentMethodCode: map['payment_method_code'] as String?,
      paymentStatus: (map['payment_status'] as String?) ?? 'PENDING',
      grandTotal: (map['grand_total'] as int?) ?? 0,
      notes: map['notes'] as String?,
      createdBy: (map['created_by'] as String?) ?? '',
      createdAt: map['created_at'] as String?,
    );
  }

  int get totalNights {
    try {
      final checkIn = DateTime.parse(checkInDate);
      final checkOut = DateTime.parse(checkOutDate);
      return checkOut.difference(checkIn).inDays;
    } catch (_) {
      return 0;
    }
  }

  Reservation copyWith({
    String? reservationId,
    String? guestId,
    String? checkInDate,
    String? checkOutDate,
    String? actualCheckIn,
    String? actualCheckOut,
    int? adultCount,
    int? childCount,
    String? statusCode,
    String? paymentMethodCode,
    String? paymentStatus,
    int? grandTotal,
    String? notes,
    String? createdBy,
    String? createdAt,
  }) {
    return Reservation(
      reservationId: reservationId ?? this.reservationId,
      guestId: guestId ?? this.guestId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      actualCheckIn: actualCheckIn ?? this.actualCheckIn,
      actualCheckOut: actualCheckOut ?? this.actualCheckOut,
      adultCount: adultCount ?? this.adultCount,
      childCount: childCount ?? this.childCount,
      statusCode: statusCode ?? this.statusCode,
      paymentMethodCode: paymentMethodCode ?? this.paymentMethodCode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      grandTotal: grandTotal ?? this.grandTotal,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReservationUnit {
  final String? id;
  final String? reservationId;
  final String unitCode;
  final int unitPrice;
  final int nights;
  final int extraBedCount;
  final int extraBedPrice;
  final int subtotal;

  const ReservationUnit({
    this.id,
    this.reservationId,
    required this.unitCode,
    required this.unitPrice,
    required this.nights,
    this.extraBedCount = 0,
    this.extraBedPrice = 0,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'unit_code': unitCode,
      'unit_price': unitPrice,
      'nights': nights,
      'extra_bed_count': extraBedCount,
      'extra_bed_price': extraBedPrice,
      'subtotal': subtotal,
    };
  }

  factory ReservationUnit.fromMap(Map<String, dynamic> map) {
    return ReservationUnit(
      id: map['id'] as String?,
      reservationId: map['reservation_id'] as String?,
      unitCode: (map['unit_code'] as String?) ?? '',
      unitPrice: (map['unit_price'] as int?) ?? 0,
      nights: (map['nights'] as int?) ?? 0,
      extraBedCount: (map['extra_bed_count'] as int?) ?? 0,
      extraBedPrice: (map['extra_bed_price'] as int?) ?? 0,
      subtotal: (map['subtotal'] as int?) ?? 0,
    );
  }
}

class ReservationService {
  final String? id;
  final String? reservationId;
  final String serviceCode;
  final String serviceName;
  final int quantity;
  final int unitPrice;
  final int subtotal;

  const ReservationService({
    this.id,
    this.reservationId,
    required this.serviceCode,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'service_code': serviceCode,
      'service_name': serviceName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory ReservationService.fromMap(Map<String, dynamic> map) {
    return ReservationService(
      id: map['id'] as String?,
      reservationId: map['reservation_id'] as String?,
      serviceCode: (map['service_code'] as String?) ?? '',
      serviceName: (map['service_name'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 0,
      unitPrice: (map['unit_price'] as int?) ?? 0,
      subtotal: (map['subtotal'] as int?) ?? 0,
    );
  }
}

class ReservationFood {
  final String? id;
  final String? reservationId;
  final String foodCode;
  final String foodName;
  final int paxCount;
  final int unitPrice;
  final int subtotal;

  const ReservationFood({
    this.id,
    this.reservationId,
    required this.foodCode,
    required this.foodName,
    required this.paxCount,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'food_code': foodCode,
      'food_name': foodName,
      'pax_count': paxCount,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory ReservationFood.fromMap(Map<String, dynamic> map) {
    return ReservationFood(
      id: map['id'] as String?,
      reservationId: map['reservation_id'] as String?,
      foodCode: (map['food_code'] as String?) ?? '',
      foodName: (map['food_name'] as String?) ?? '',
      paxCount: (map['pax_count'] as int?) ?? 0,
      unitPrice: (map['unit_price'] as int?) ?? 0,
      subtotal: (map['subtotal'] as int?) ?? 0,
    );
  }
}

class ReservationWithGuest {
  final String reservationId;
  final String guestName;
  final String phone;
  final String unitNames;
  final String checkInDate;
  final String checkOutDate;
  final String statusCode;
  final int grandTotal;
  final String? createdAt;

  const ReservationWithGuest({
    required this.reservationId,
    required this.guestName,
    required this.phone,
    required this.unitNames,
    required this.checkInDate,
    required this.checkOutDate,
    required this.statusCode,
    required this.grandTotal,
    this.createdAt,
  });
}

class CalendarCell {
  final String unitCode;
  final String unitName;
  final DateTime date;
  final String? reservationId;
  final String? guestName;
  final String statusCode;

  const CalendarCell({
    required this.unitCode,
    required this.unitName,
    required this.date,
    this.reservationId,
    this.guestName,
    this.statusCode = 'available',
  });
}