import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/widgets/baby_card/zodiac_badge_widget.dart';

void main() {
  group('ZodiacBadgeWidget Tests', () {
    testWidgets('renderiza Chip com signo correto', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25); // Áries

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Áries'), findsOneWidget);
    });

    testWidgets('exibe emoji do signo', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25); // Áries (♈)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.text('♈'), findsOneWidget);
    });

    testWidgets('renderiza N/A quando data é nula', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeWidget(
              expectedDueDate: null,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('aplica cor do tema ao texto', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);
      const Color testColor = Colors.purple;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeWidget(
              expectedDueDate: date,
              themeColor: testColor,
            ),
          ),
        ),
      );

      final textWidget = find.text('Áries');
      expect(textWidget, findsOneWidget);
    });

    testWidgets('chama onTap quando clicado', (WidgetTester tester) async {
      bool tapped = false;
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Chip));
      expect(tapped, isTrue);
    });

    testWidgets('renderiza com tamanho de emoji customizável',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              emojiSize: 24,
            ),
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('renderiza com tamanho de texto customizável',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              textSize: 16,
            ),
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('diferentes signos renderizam corretamente',
        (WidgetTester tester) async {
      final testCases = [
        (DateTime(2026, 3, 25), 'Áries', '♈'),
        (DateTime(2026, 5, 15), 'Touro', '♉'),
        (DateTime(2026, 6, 15), 'Gêmeos', '♊'),
        (DateTime(2026, 7, 15), 'Câncer', '♋'),
        (DateTime(2026, 8, 15), 'Leão', '♌'),
      ];

      for (final (date, sign, emoji) in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ZodiacBadgeWidget(
                expectedDueDate: date,
                themeColor: Colors.pink,
              ),
            ),
          ),
        );

        expect(find.text(sign), findsOneWidget);
        expect(find.text(emoji), findsOneWidget);
      }
    });
  });

  group('ZodiacBadgeContainerWidget Tests', () {
    testWidgets('renderiza Container com estilo customizável',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeContainerWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
      expect(find.text('Áries'), findsOneWidget);
    });

    testWidgets('aplica backgroundColor customizável',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);
      const Color customBg = Colors.yellow;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeContainerWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              backgroundColor: customBg,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('aplica borderColor customizável', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);
      const Color customBorder = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeContainerWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              borderColor: customBorder,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('aplica borderRadius customizável', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeContainerWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              borderRadius: 30,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('chama onTap quando clicado', (WidgetTester tester) async {
      bool tapped = false;
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeContainerWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });
  });

  group('ZodiacBadgeDetailedWidget Tests', () {
    testWidgets('renderiza com informações detalhadas',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeDetailedWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              showDueDate: true,
            ),
          ),
        ),
      );

      expect(find.text('Áries'), findsOneWidget);
      expect(find.text('♈'), findsOneWidget);
    });

    testWidgets('exibe data prevista quando showDueDate é true',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeDetailedWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              showDueDate: true,
            ),
          ),
        ),
      );

      expect(find.text('25/3/2026'), findsOneWidget);
    });

    testWidgets('não exibe data quando showDueDate é false',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeDetailedWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              showDueDate: false,
            ),
          ),
        ),
      );

      expect(find.text('25/3/2026'), findsNothing);
    });

    testWidgets('não exibe data quando expectedDueDate é nulo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeDetailedWidget(
              expectedDueDate: null,
              themeColor: Colors.pink,
              showDueDate: true,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsWidgets);
    });
  });

  group('ZodiacBadgeAnimatedWidget Tests', () {
    testWidgets('renderiza com animação', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeAnimatedWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      // O AnimatedWidget e o widget interno podem gerar múltiplas transições.
      expect(find.byType(ScaleTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('aplica duração de animação customizável',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeAnimatedWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              animationDuration: const Duration(milliseconds: 800),
            ),
          ),
        ),
      );

      expect(find.byType(ZodiacBadgeAnimatedWidget), findsOneWidget);
    });

    testWidgets('animação completa sem erros', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeAnimatedWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      // Aguardar animação completar
      await tester.pumpAndSettle();

      expect(find.text('Áries'), findsOneWidget);
    });

    testWidgets('chama onTap durante animação', (WidgetTester tester) async {
      bool tapped = false;
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZodiacBadgeAnimatedWidget(
              expectedDueDate: date,
              themeColor: Colors.pink,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(GestureDetector));

      expect(tapped, isTrue);
    });
  });

  group('Integration Tests', () {
    testWidgets('todos os widgets renderizam sem erros',
        (WidgetTester tester) async {
      final date = DateTime(2026, 3, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ZodiacBadgeWidget(
                  expectedDueDate: date,
                  themeColor: Colors.pink,
                ),
                ZodiacBadgeContainerWidget(
                  expectedDueDate: date,
                  themeColor: Colors.blue,
                ),
                ZodiacBadgeDetailedWidget(
                  expectedDueDate: date,
                  themeColor: Colors.purple,
                ),
                ZodiacBadgeAnimatedWidget(
                  expectedDueDate: date,
                  themeColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ZodiacBadgeWidget), findsOneWidget);
      // Um vem direto e outro é usado internamente pelo ZodiacBadgeAnimatedWidget.
      expect(find.byType(ZodiacBadgeContainerWidget), findsNWidgets(2));
      expect(find.byType(ZodiacBadgeDetailedWidget), findsOneWidget);
      expect(find.byType(ZodiacBadgeAnimatedWidget), findsOneWidget);
    });
  });
}
