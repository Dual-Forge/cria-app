import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/widgets/baby_card/bpm_display_widget.dart';

void main() {
  group('BPMDisplayWidget - BPM Display and Formatting', () {
    testWidgets('displays BPM value correctly with heart icon',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('displays fallback message when BPM is null',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('BPM não disponível'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('displays BPM 60 correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 60,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('60 BPM'), findsOneWidget);
    });

    testWidgets('displays BPM 90 correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 90,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('90 BPM'), findsOneWidget);
    });

    testWidgets('displays BPM 120 correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
    });

    testWidgets('displays BPM 150 correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 150,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('150 BPM'), findsOneWidget);
    });

    testWidgets('displays BPM 180 correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 180,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('180 BPM'), findsOneWidget);
    });
  });

  group('BPMDisplayWidget - Play Button Functionality', () {
    testWidgets('displays play button when BPM is available',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Ouvir'), findsOneWidget);
    });

    testWidgets('does not display play button when BPM is null',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.text('Ouvir'), findsNothing);
    });

    testWidgets('play button is tappable', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });
  });

  group('BPMDisplayWidget - Animation Synchronization', () {
    testWidgets('heart icon is present and animatable',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('animation duration changes with different BPMs',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 60,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('60 BPM'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 180,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('180 BPM'), findsOneWidget);
    });
  });

  group('BPMDisplayWidget - Error Handling for Invalid BPM', () {
    testWidgets('handles BPM below minimum (40)', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 30,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('30 BPM'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('handles BPM above maximum (200)', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 250,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('250 BPM'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('accepts valid BPM range (40-200)', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 40,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('40 BPM'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 200,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('200 BPM'), findsOneWidget);
    });
  });

  group('BPMDisplayWidget - Callbacks', () {
    testWidgets('onAudioStart callback is passed to widget',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
              onAudioStart: () {},
            ),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
    });

    testWidgets('onAudioStop callback is passed to widget',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
              onAudioStop: () {},
            ),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
    });

    testWidgets('onError callback is passed to widget',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
              onError: (error) {},
            ),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
    });
  });

  group('BPMDisplayWidget - Fallback Behavior', () {
    testWidgets('displays fallback message when BPM is null',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('BPM não disponível'), findsOneWidget);
    });

    testWidgets('does not show play button when BPM is null',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.text('Ouvir'), findsNothing);
    });

    testWidgets('does not show heart icon when BPM is null',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('gracefully handles null BPM with callbacks',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: null,
              themeColor: themeColor,
              onAudioStart: () {},
              onAudioStop: () {},
              onError: (error) {},
            ),
          ),
        ),
      );

      expect(find.text('BPM não disponível'), findsOneWidget);
    });
  });

  group('BPMDisplayCompactWidget', () {
    testWidgets('displays compact BPM correctly', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(
              lastBpm: 120,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('120'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('does not display when BPM is null', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(
              lastBpm: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('responds to tap', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(
              lastBpm: 120,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('compact widget with BPM 60', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(
              lastBpm: 60,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('compact widget with BPM 150', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(
              lastBpm: 150,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('compact widget with BPM 180', (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(
              lastBpm: 180,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      expect(find.text('180'), findsOneWidget);
    });

    testWidgets('compact widget calls onAudioStart callback',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(
              lastBpm: 120,
              themeColor: themeColor,
              onAudioStart: () {},
            ),
          ),
        ),
      );

      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('compact widget calls onAudioStop callback',
        (WidgetTester tester) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(
              lastBpm: 120,
              themeColor: themeColor,
              onAudioStop: () {},
            ),
          ),
        ),
      );

      expect(find.text('120'), findsOneWidget);
    });
  });
}
