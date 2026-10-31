import 'package:flutter/material.dart';

enum ServiceType { doctor, pharmacy, laboratory, hospital }

extension ServiceTypePresentation on ServiceType {
  String get label => switch (this) {
    ServiceType.doctor => 'أطباء',
    ServiceType.pharmacy => 'صيدليات',
    ServiceType.laboratory => 'معامل',
    ServiceType.hospital => 'مستشفيات',
  };

  String get singularLabel => switch (this) {
    ServiceType.doctor => 'طبيب',
    ServiceType.pharmacy => 'صيدلية',
    ServiceType.laboratory => 'معمل تحاليل',
    ServiceType.hospital => 'مستشفى',
  };

  IconData get icon => switch (this) {
    ServiceType.doctor => Icons.medical_services_outlined,
    ServiceType.pharmacy => Icons.local_pharmacy_outlined,
    ServiceType.laboratory => Icons.biotech_outlined,
    ServiceType.hospital => Icons.local_hospital_outlined,
  };
}

class HealthService {
  const HealthService({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.area,
    required this.address,
    required this.phone,
    required this.description,
    required this.hours,
    this.specialty,
    this.rating,
    this.price,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final ServiceType type;
  final String city;
  final String area;
  final String address;
  final String phone;
  final String description;
  final String hours;
  final String? specialty;
  final double? rating;
  final String? price;
  final double? latitude;
  final double? longitude;

  String get locationLabel => '$area، $city';

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'city': city,
    'area': area,
    'address': address,
    'phone': phone,
    'description': description,
    'hours': hours,
    'specialty': specialty,
    'rating': rating,
    'price': price,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory HealthService.fromJson(Map<String, dynamic> json) => HealthService(
    id: json['id'] as String,
    name: json['name'] as String,
    type: ServiceType.values.byName(json['type'] as String),
    city: json['city'] as String,
    area: json['area'] as String,
    address: json['address'] as String,
    phone: json['phone'] as String,
    description: json['description'] as String,
    hours: json['hours'] as String,
    specialty: json['specialty'] as String?,
    rating: (json['rating'] as num?)?.toDouble(),
    price: json['price'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}
