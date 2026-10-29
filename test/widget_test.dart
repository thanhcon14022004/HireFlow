import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hireflow/widgets/common_widgets.dart';

void main() {
  testWidgets('CreditBadge should display correct balance and coin icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CreditBadge(balance: 25),
        ),
      ),
    );

    expect(find.text('25 credit'), findsOneWidget);
    expect(find.byIcon(Icons.monetization_on), findsOneWidget);
  });

  testWidgets('StatusBadge should display correct Vietnamese label for statuses', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusBadge(status: 'Open'),
              StatusBadge(status: 'Pending'),
              StatusBadge(status: 'Accepted'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Đang nhận hồ sơ'), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsOneWidget);
    expect(find.text('Được nhận'), findsOneWidget);
  });
}
