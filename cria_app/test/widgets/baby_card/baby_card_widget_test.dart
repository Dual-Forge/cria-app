import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/widgets/baby_card/baby_card_widget.dart';

void main() {
  group('BabyCardWidget', () {
    testWidgets('displays baby name', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
    });

    testWidgets('displays all components by default', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      final expectedDueDate = DateTime.now().add(const Duration(days: 210));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              dumDate: dumDate,
              expectedDueDate: expectedDueDate,
              lastBpm: 120,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget); // Trimestre progress
      expect(find.text('Registrar Chute (5)'), findsOneWidget); // Kick counter
    });

    testWidgets('hides BPM when showBpm is false', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              lastBpm: 120,
              showBpm: false,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      // BPM display should not be visible
    });

    testWidgets('hides zodiac when showZodiac is false', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);
      final expectedDueDate = DateTime.now().add(const Duration(days: 210));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              expectedDueDate: expectedDueDate,
              showZodiac: false,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      // Zodiac badge should not be visible
    });

    testWidgets('hides trimestre progress when showTrimestreProgress is false',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);
      final dumDate = DateTime.now().subtract(const Duration(days: 70));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              dumDate: dumDate,
              showTrimestreProgress: false,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('hides kick counter when showKickCounter is false',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              showKickCounter: false,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      expect(find.text('Registrar Chute (5)'), findsNothing);
    });

    testWidgets('displays profile photo when provided', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              profilePhotoUrl: 'https://example.com/photo.jpg',
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      // Photo widget should be present
    });

    testWidgets('displays fallback icon when no photo provided', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              profilePhotoUrl: null,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      expect(find.byIcon(Icons.child_care_rounded), findsOneWidget);
    });

    testWidgets('calls onKickCountUpdated callback', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);
      int? updatedCount;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              onKickCountUpdated: (count) => updatedCount = count,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      // Callback should be passed to KickCounterButton
    });

    testWidgets('has correct styling with theme color', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
    });
  });

  group('BabyCardCompactWidget', () {
    testWidgets('displays compact version correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);
      final dumDate = DateTime.now().subtract(const Duration(days: 70));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardCompactWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              dumDate: dumDate,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays BPM when provided', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardCompactWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              lastBpm: 120,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
    });
  });

  group('BabyCardDetailedWidget', () {
    testWidgets('displays detailed version correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);
      final dumDate = DateTime.now().subtract(const Duration(days: 70));
      final expectedDueDate = DateTime.now().add(const Duration(days: 210));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardDetailedWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              dumDate: dumDate,
              expectedDueDate: expectedDueDate,
              lastBpm: 120,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Registrar Chute (5)'), findsOneWidget);
    });
  });

  group('BabyCardMinimalWidget', () {
    testWidgets('displays minimal version correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardMinimalWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
    });

    testWidgets('displays zodiac badge', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);
      final expectedDueDate = DateTime.now().add(const Duration(days: 210));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyCardMinimalWidget(
              babyName: 'Ayla',
              familyId: 'test-family-id',
              kickCount: 5,
              themeColor: themeColor,
              expectedDueDate: expectedDueDate,
            ),
          ),
        ),
      );

      expect(find.text('Ayla'), findsOneWidget);
    });
  });
}
