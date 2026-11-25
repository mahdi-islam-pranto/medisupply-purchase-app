/// Lenient JSON readers. The server may send numbers as strings
/// (e.g. `"63925.00"`), so models read values through these.
typedef Json = Map<String, dynamic>;

num? asNum(Object? v) => switch (v) {
  null => null,
  num n => n,
  String s => num.tryParse(s.trim()),
  _ => null,
};

int? asInt(Object? v) => asNum(v)?.toInt();

double? asDouble(Object? v) => asNum(v)?.toDouble();

String? asString(Object? v) => switch (v) {
  null => null,
  String s => s,
  _ => v.toString(),
};

bool asBool(Object? v, {bool fallback = false}) => switch (v) {
  bool b => b,
  num n => n != 0,
  String s => s == 'true' || s == '1',
  _ => fallback,
};

Json? asMap(Object? v) => v is Map ? Map<String, dynamic>.from(v) : null;

List<Json> asMapList(Object? v) =>
    v is List ? v.whereType<Map>().map(Map<String, dynamic>.from).toList() : [];
