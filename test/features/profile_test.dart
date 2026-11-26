import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/core/network/api_exception.dart';
import 'package:purchase_app/core/theme/app_theme.dart';
import 'package:purchase_app/features/profile/data/profile_models.dart';
import 'package:purchase_app/features/profile/data/profile_repository.dart';
import 'package:purchase_app/features/profile/presentation/widgets/change_pin_sheet.dart';

/// Fakes `POST /change-pin`.
class _FakeRepo implements ProfileRepository {
  _FakeRepo(this.onChange);
  final Future<String> Function(String current, String next, String confirm)
  onChange;
  int calls = 0;

  @override
  Future<String> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) {
    calls++;
    return onChange(currentPin, newPin, confirmPin);
  }

  @override
  Future<ProfileData> fetch() => throw UnimplementedError();
}

Future<void> _pumpSheet(WidgetTester tester, _FakeRepo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ChangePinSheet()),
      ),
    ),
  );
}

Future<void> _fill(WidgetTester tester, String a, String b, String c) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), a);
  await tester.enterText(fields.at(1), b);
  await tester.enterText(fields.at(2), c);
  await tester.tap(find.text('Save new PIN'));
  await tester.pumpAndSettle();
}

void main() {
  group('ProfileData.fromJson', () {
    test('reads store, window and notifications', () {
      final data = ProfileData.fromJson({
        'store': {
          'name': 'Green Corner Store',
          'company': null,
          'phone': '01712345678',
          'email': 'store@example.com',
        },
        'window': {'open': false, 'opens_at': '10:00', 'closes_at': '14:00'},
        'notifications': [
          {
            'type': 'quote_reviewed',
            'title': 'Quote approved',
            'body': '5 of 8 products approved for 19 Nov.',
            'time_ago': '2 hours ago',
          },
          {'type': 'payment', 'title': 'Payment received', 'body': '৳40,000'},
          {'type': 'something_new', 'title': 'Hi'},
        ],
      });

      expect(data.store?.phone, '01712345678');
      expect(data.window.range, '10:00 – 14:00');
      expect(data.notifications.map((n) => n.type), [
        NotificationType.quoteReviewed,
        NotificationType.payment,
        NotificationType.other,
      ]);
      expect(data.notifications.first.timeAgo, '2 hours ago');
      expect(data.notifications.last.body, '');
    });

    test('empty response is safe', () {
      final data = ProfileData.fromJson(null);
      expect(data.store, isNull);
      expect(data.notifications, isEmpty);
    });
  });

  group('Change PIN sheet', () {
    testWidgets('checks the form before calling the server', (tester) async {
      final repo = _FakeRepo((_, _, _) async => 'PIN changed');
      await _pumpSheet(tester, repo);

      await _fill(tester, '123456', '654', '654');
      expect(find.text('PIN must be at least 6 characters'), findsOneWidget);

      await _fill(tester, '123456', '654321', '654320');
      expect(find.text('PINs do not match'), findsOneWidget);

      await _fill(tester, '123456', '123456', '123456');
      expect(
        find.text('New PIN must be different from the current one'),
        findsOneWidget,
      );
      expect(repo.calls, 0);
    });

    testWidgets('shows the 422 message under the current PIN', (tester) async {
      final repo = _FakeRepo(
        (_, _, _) async => throw const ApiException(
          ApiErrorKind.validation,
          'The current PIN is not correct.',
          statusCode: 422,
          fieldErrors: {
            'current_pin': ['The current PIN is not correct.'],
          },
        ),
      );
      await _pumpSheet(tester, repo);

      await _fill(tester, '111111', '654321', '654321');
      expect(repo.calls, 1);
      expect(find.text('The current PIN is not correct.'), findsOneWidget);
    });
  });
}
