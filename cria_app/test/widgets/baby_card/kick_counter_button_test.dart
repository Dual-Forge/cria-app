import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/widgets/baby_card/kick_counter_button.dart';

void main() {
  group('KickCounterButton', () {
    testWidgets('displays kick count correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 5,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('Registrar Chute (5)'), findsOneWidget);
    });

    testWidgets('displays zero kick count', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 0,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('Registrar Chute (0)'), findsOneWidget);
    });

    testWidgets('displays large kick count', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 999,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('Registrar Chute (999)'), findsOneWidget);
    });

    testWidgets('button is enabled by default', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 5,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      // Find the button by looking for the text
      expect(find.text('Registrar Chute (5)'), findsOneWidget);

      // Se está habilitado, o tap abre o diálogo de confirmação.
      await tester.tap(find.text('Registrar Chute (5)'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows confirmation dialog on tap', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 5,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      // Tap the button using the text finder
      await tester.tap(find.text('Registrar Chute (5)'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Ayla chutou?'), findsOneWidget);
      expect(find.text('Deseja registrar esse movimento?'), findsOneWidget);
    });

    testWidgets('dialog has cancel and register buttons', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 5,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Registrar Chute (5)'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('closes dialog when cancel is tapped', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 5,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Registrar Chute (5)'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows dialog with correct baby name', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 5,
              babyName: 'Sofia',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Registrar Chute (5)'));
      await tester.pumpAndSettle();

      expect(find.text('Sofia chutou?'), findsOneWidget);
    });

    testWidgets('displays kick counter emoji', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterButton(
              kickCount: 5,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('🦶'), findsOneWidget);
    });
  });

  group('KickCounterCompactButton', () {
    testWidgets('displays compact version correctly', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterCompactButton(
              kickCount: 5,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('🦶'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog on tap', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterCompactButton(
              kickCount: 5,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('displays zero count', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterCompactButton(
              kickCount: 0,
              babyName: 'Ayla',
              familyId: 'test-family-id',
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });
  });

  group('KickCounterDisplayWidget', () {
    testWidgets('displays kick count without interaction', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterDisplayWidget(
              kickCount: 5,
              themeColor: themeColor,
              showIcon: true,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('🦶'), findsOneWidget);
    });

    testWidgets('hides icon when showIcon is false', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterDisplayWidget(
              kickCount: 5,
              themeColor: themeColor,
              showIcon: false,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('🦶'), findsNothing);
    });

    testWidgets('displays zero count', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterDisplayWidget(
              kickCount: 0,
              themeColor: themeColor,
              showIcon: true,
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });
  });

  group('KickCounterHistoryWidget', () {
    testWidgets('displays kick count and last kick date', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);
      final lastKickDate = DateTime.now().subtract(const Duration(hours: 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterHistoryWidget(
              kickCount: 5,
              lastKickDate: lastKickDate,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('Total de chutes: 5'), findsOneWidget);
      expect(find.text('Último chute: Há 2 hora(s)'), findsOneWidget);
    });

    testWidgets('displays without last kick date', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterHistoryWidget(
              kickCount: 5,
              lastKickDate: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('Total de chutes: 5'), findsOneWidget);
    });

    testWidgets('displays emoji', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickCounterHistoryWidget(
              kickCount: 5,
              lastKickDate: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('🦶'), findsOneWidget);
    });
  });
}
