import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/main.dart';

void main() {
  testWidgets('CareConnectApp launches smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CareConnectApp()));
    await tester.pumpAndSettle();
    expect(find.byType(CareConnectApp), findsOneWidget);
  });
}
