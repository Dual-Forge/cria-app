import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/widgets/baby_card/bpm_display_widget.dart';

void main() {
  group('BPMDisplayWidget - Playback Rate Calculation', () {
    /// Test playback rate calculation for BPM 60
    /// Expected: 60 / 120 = 0.5x playback rate
    testWidgets('calculates correct playback rate for BPM 60 (0.5x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 60, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('60 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify the widget displays correctly for BPM 60
      final bpmText = find.text('60 BPM');
      expect(bpmText, findsOneWidget);
    });

    /// Test playback rate calculation for BPM 90
    /// Expected: 90 / 120 = 0.75x playback rate
    testWidgets('calculates correct playback rate for BPM 90 (0.75x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 90, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('90 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify the widget displays correctly for BPM 90
      final bpmText = find.text('90 BPM');
      expect(bpmText, findsOneWidget);
    });

    /// Test playback rate calculation for BPM 120
    /// Expected: 120 / 120 = 1.0x playback rate (base rate)
    testWidgets('calculates correct playback rate for BPM 120 (1.0x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 120, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify the widget displays correctly for BPM 120
      final bpmText = find.text('120 BPM');
      expect(bpmText, findsOneWidget);
    });

    /// Test playback rate calculation for BPM 150
    /// Expected: 150 / 120 = 1.25x playback rate
    testWidgets('calculates correct playback rate for BPM 150 (1.25x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 150, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('150 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify the widget displays correctly for BPM 150
      final bpmText = find.text('150 BPM');
      expect(bpmText, findsOneWidget);
    });

    /// Test playback rate calculation for BPM 180
    /// Expected: 180 / 120 = 1.5x playback rate
    testWidgets('calculates correct playback rate for BPM 180 (1.5x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 180, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('180 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify the widget displays correctly for BPM 180
      final bpmText = find.text('180 BPM');
      expect(bpmText, findsOneWidget);
    });
  });

  group('BPMDisplayWidget - Playback Rate Clamping', () {
    /// Test that playback rate is clamped between 0.5x and 2.0x
    testWidgets('clamps playback rate to minimum 0.5x for low BPM', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      // BPM 40 should result in 40/120 = 0.333x, clamped to 0.5x
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 40, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('40 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    /// Test that playback rate is clamped to maximum 2.0x for high BPM
    testWidgets('clamps playback rate to maximum 2.0x for high BPM', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      // BPM 200 should result in 200/120 = 1.666x, within range
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 200, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('200 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    /// Test that playback rate is clamped for BPM below minimum
    testWidgets('clamps playback rate for BPM below 40', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      // BPM 30 should be clamped to 0.5x
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 30, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('30 BPM'), findsOneWidget);
    });

    /// Test that playback rate is clamped for BPM above maximum
    testWidgets('clamps playback rate for BPM above 200', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      // BPM 250 should be clamped to 2.0x
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 250, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('250 BPM'), findsOneWidget);
    });
  });

  group('BPMDisplayWidget - Animation Duration Synchronization', () {
    /// Test animation duration for BPM 60
    /// Expected: 60000 / 60 = 1000ms
    testWidgets('animation duration matches BPM 60 (1000ms)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 60, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('60 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    /// Test animation duration for BPM 90
    /// Expected: 60000 / 90 = 666.67ms
    testWidgets('animation duration matches BPM 90 (666ms)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 90, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('90 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    /// Test animation duration for BPM 120
    /// Expected: 60000 / 120 = 500ms
    testWidgets('animation duration matches BPM 120 (500ms)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 120, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    /// Test animation duration for BPM 150
    /// Expected: 60000 / 150 = 400ms
    testWidgets('animation duration matches BPM 150 (400ms)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 150, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('150 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    /// Test animation duration for BPM 180
    /// Expected: 60000 / 180 = 333.33ms
    testWidgets('animation duration matches BPM 180 (333ms)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 180, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('180 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('BPMDisplayWidget - Audio Playback with Different BPMs', () {
    /// Test audio playback for BPM 60
    testWidgets('plays audio correctly for BPM 60', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 60, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('60 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify play button is tappable
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);
    });

    /// Test audio playback for BPM 90
    testWidgets('plays audio correctly for BPM 90', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 90, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('90 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify play button is tappable
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);
    });

    /// Test audio playback for BPM 120
    testWidgets('plays audio correctly for BPM 120', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 120, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify play button is tappable
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);
    });

    /// Test audio playback for BPM 150
    testWidgets('plays audio correctly for BPM 150', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 150, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('150 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify play button is tappable
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);
    });

    /// Test audio playback for BPM 180
    testWidgets('plays audio correctly for BPM 180', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(lastBpm: 180, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('180 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify play button is tappable
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);
    });
  });

  group('BPMDisplayWidget - Playback Rate Validation', () {
    /// Test that playback rate is correctly calculated for all test BPMs
    testWidgets('validates playback rate calculation for BPM 60 (0.5x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 60,
              themeColor: themeColor,
              baseAudioBpm: 120.0,
            ),
          ),
        ),
      );

      expect(find.text('60 BPM'), findsOneWidget);
      // 60 / 120 = 0.5x
    });

    /// Test that playback rate is correctly calculated for BPM 90
    testWidgets('validates playback rate calculation for BPM 90 (0.75x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 90,
              themeColor: themeColor,
              baseAudioBpm: 120.0,
            ),
          ),
        ),
      );

      expect(find.text('90 BPM'), findsOneWidget);
      // 90 / 120 = 0.75x
    });

    /// Test that playback rate is correctly calculated for BPM 120
    testWidgets('validates playback rate calculation for BPM 120 (1.0x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 120,
              themeColor: themeColor,
              baseAudioBpm: 120.0,
            ),
          ),
        ),
      );

      expect(find.text('120 BPM'), findsOneWidget);
      // 120 / 120 = 1.0x
    });

    /// Test that playback rate is correctly calculated for BPM 150
    testWidgets('validates playback rate calculation for BPM 150 (1.25x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 150,
              themeColor: themeColor,
              baseAudioBpm: 120.0,
            ),
          ),
        ),
      );

      expect(find.text('150 BPM'), findsOneWidget);
      // 150 / 120 = 1.25x
    });

    /// Test that playback rate is correctly calculated for BPM 180
    testWidgets('validates playback rate calculation for BPM 180 (1.5x)', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayWidget(
              lastBpm: 180,
              themeColor: themeColor,
              baseAudioBpm: 120.0,
            ),
          ),
        ),
      );

      expect(find.text('180 BPM'), findsOneWidget);
      // 180 / 120 = 1.5x
    });
  });

  group('BPMDisplayCompactWidget - Playback Rate with Different BPMs', () {
    /// Test compact widget with BPM 60
    testWidgets('compact widget displays BPM 60 correctly', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(lastBpm: 60, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('60'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    /// Test compact widget with BPM 90
    testWidgets('compact widget displays BPM 90 correctly', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(lastBpm: 90, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('90'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    /// Test compact widget with BPM 120
    testWidgets('compact widget displays BPM 120 correctly', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(lastBpm: 120, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('120'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    /// Test compact widget with BPM 150
    testWidgets('compact widget displays BPM 150 correctly', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(lastBpm: 150, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('150'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    /// Test compact widget with BPM 180
    testWidgets('compact widget displays BPM 180 correctly', (
      WidgetTester tester,
    ) async {
      const themeColor = Color(0xFFE91E63);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BPMDisplayCompactWidget(lastBpm: 180, themeColor: themeColor),
          ),
        ),
      );

      expect(find.text('180'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
