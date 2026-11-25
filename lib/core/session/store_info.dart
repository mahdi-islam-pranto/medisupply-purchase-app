import '../utils/json.dart';

/// The signed-in purchase store, as returned by `/login`, `/home`, `/profile`.
class StoreInfo {
  const StoreInfo({required this.name, this.company, this.phone, this.email});

  final String name;
  final String? company;
  final String? phone;
  final String? email;

  factory StoreInfo.fromJson(Json json) => StoreInfo(
    name: asString(json['name']) ?? '',
    company: asString(json['company']),
    phone: asString(json['phone']),
    email: asString(json['email']),
  );

  Json toJson() => {
    'name': name,
    'company': company,
    'phone': phone,
    'email': email,
  };
}
