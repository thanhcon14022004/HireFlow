import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hireflow/core/constants/app_colors.dart';
import 'package:hireflow/widgets/common_widgets.dart';
import 'package:hireflow/widgets/skeleton_widgets.dart';

void main() {
  test('StatusStyle maps known statuses and falls back for unknown ones', () {
    expect(StatusStyle.of('Open').label, 'Đang nhận hồ sơ');
    expect(StatusStyle.of('REJECTED').label, 'Từ chối');
    expect(StatusStyle.of('something-else').label, isNull);
    expect(StatusStyle.of('accepted').fg, AppColors.primary);
  });

  testWidgets('CreditBadge shows the new balance after it changes', (tester) async {
    Widget app(int balance) => MaterialApp(
          home: Scaffold(body: CreditBadge(balance: balance)),
        );

    await tester.pumpWidget(app(25));
    expect(find.text('25'), findsOneWidget);

    await tester.pumpWidget(app(22));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('22'), findsOneWidget);
    expect(find.text('25'), findsNothing);
  });

  testWidgets('EmptyStateWidget renders the action button and fires the callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.assignment_outlined,
            title: 'Chưa có hồ sơ',
            subtitle: 'Mô tả',
            buttonText: 'Khám phá dự án',
            buttonIcon: Icons.explore_outlined,
            onButtonPressed: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Chưa có hồ sơ'), findsOneWidget);
    await tester.tap(find.text('Khám phá dự án'));
    expect(tapped, isTrue);
  });

  testWidgets('SkeletonList builds the requested number of placeholders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SkeletonList(type: SkeletonType.jobCard, itemCount: 2),
        ),
      ),
    );
    // The shimmer repeats forever, so use pump() instead of pumpAndSettle().
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(JobCardSkeleton), findsNWidgets(2));
    expect(find.byType(Shimmer), findsNWidgets(2));
  });
}
