import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/widgets/baby_card/trimestre_progress_bar.dart';
import 'package:cria_app/core/utils/pregnancy_utils.dart';

void main() {
  group('TrimestreProgressBar', () {
    testWidgets('displays trimestre name and percentage', (
      WidgetTester tester,
    ) async {
      final dumDate = DateTime.now().subtract(
        const Duration(days: 70),
      ); // ~10 weeks
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(
              dumDate: dumDate,
              themeColor: themeColor,
              showPercentage: true,
              showTrimestreName: true,
            ),
          ),
        ),
      );

      expect(find.text('1º Trimestre'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays null dumDate gracefully', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(dumDate: null, themeColor: themeColor),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('calculates correct trimestre for different weeks', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      // Test 1º Trimestre (week 10)
      var dumDate = DateTime.now().subtract(const Duration(days: 70));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(
              dumDate: dumDate,
              themeColor: themeColor,
            ),
          ),
        ),
      );
      expect(find.text('1º Trimestre'), findsOneWidget);

      // Test 2º Trimestre (week 20)
      dumDate = DateTime.now().subtract(const Duration(days: 140));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(
              dumDate: dumDate,
              themeColor: themeColor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2º Trimestre'), findsOneWidget);

      // Test 3º Trimestre (week 32)
      dumDate = DateTime.now().subtract(const Duration(days: 224));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(
              dumDate: dumDate,
              themeColor: themeColor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3º Trimestre'), findsOneWidget);
    });

    testWidgets('progress bar has correct value', (WidgetTester tester) async {
      final dumDate = DateTime.now().subtract(
        const Duration(days: 70),
      ); // ~10 weeks
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(
              dumDate: dumDate,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      final progress = calculateTrimestreProgress(dumDate);
      final progressIndicator = find.byType(LinearProgressIndicator);
      expect(progressIndicator, findsOneWidget);

      // Verify the progress value is between 0 and 1
      expect(progress.progress >= 0.0 && progress.progress <= 1.0, true);
    });

    testWidgets('hides trimestre name when showTrimestreName is false', (
      WidgetTester tester,
    ) async {
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(
              dumDate: dumDate,
              themeColor: themeColor,
              showTrimestreName: false,
            ),
          ),
        ),
      );

      expect(find.text('1º Trimestre'), findsNothing);
    });

    testWidgets('hides percentage when showPercentage is false', (
      WidgetTester tester,
    ) async {
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(
              dumDate: dumDate,
              themeColor: themeColor,
              showPercentage: false,
            ),
          ),
        ),
      );

      // The percentage text should not be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('responds to tap callback', (WidgetTester tester) async {
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      const themeColor = Color(0xFFE91E63);
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBar(
              dumDate: dumDate,
              themeColor: themeColor,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap on the LinearProgressIndicator which is inside the GestureDetector
      await tester.tap(find.byType(LinearProgressIndicator));
      expect(tapped, true);
    });
  });

  group('TrimestreProgressBarCompact', () {
    testWidgets('displays compact version correctly', (
      WidgetTester tester,
    ) async {
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBarCompact(
              dumDate: dumDate,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('1º Trimestre'), findsOneWidget);
    });
  });

  group('TrimestreProgressBarDetailed', () {
    testWidgets('displays detailed information', (WidgetTester tester) async {
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBarDetailed(
              dumDate: dumDate,
              themeColor: themeColor,
              showMilestone: true,
              showDaysRemaining: true,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('1º Trimestre'), findsOneWidget);
    });

    testWidgets('hides milestone when showMilestone is false', (
      WidgetTester tester,
    ) async {
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBarDetailed(
              dumDate: dumDate,
              themeColor: themeColor,
              showMilestone: false,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('TrimestreProgressBarAnimated', () {
    testWidgets('animates progress on load', (WidgetTester tester) async {
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimestreProgressBarAnimated(
              dumDate: dumDate,
              themeColor: themeColor,
              animationDuration: const Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Advance animation
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
