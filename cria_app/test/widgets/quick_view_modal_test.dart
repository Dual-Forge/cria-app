import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/screens/web_gift_screen.dart';

Widget _buildTestWidget(QuickViewModal modal) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showDialog(context: ctx, builder: (_) => modal),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  final baseItem = {
    'id': '1',
    'name': 'Carrinho de Bebê',
    'price': '1299.90',
    'image_url': null,
  };

  group('QuickViewModal', () {
    testWidgets('exibe nome do item', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(QuickViewModal(item: baseItem, onAdd: () {})),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Carrinho de Bebê'), findsOneWidget);
    });

    testWidgets('exibe preço formatado com vírgula', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(QuickViewModal(item: baseItem, onAdd: () {})),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('1299,90'), findsOneWidget);
    });

    testWidgets('exibe texto de parcela formatado', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(QuickViewModal(item: baseItem, onAdd: () {})),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 1299.90 / 6 = 216.65
      expect(find.textContaining('6x de 216,65'), findsOneWidget);
    });

    testWidgets('exibe stockHint padrão quando não fornecido', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(QuickViewModal(item: baseItem, onAdd: () {})),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Resta apenas 1 unidade'), findsOneWidget);
    });

    testWidgets('exibe stockHint customizado quando fornecido', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          QuickViewModal(
              item: baseItem,
              onAdd: () {},
              stockHint: 'Últimas 3 unidades!'),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Últimas 3 unidades!'), findsOneWidget);
      expect(find.text('Resta apenas 1 unidade'), findsNothing);
    });

    testWidgets('não exibe preço quando price é zero', (tester) async {
      final itemSemPreco = {...baseItem, 'price': '0'};
      await tester.pumpWidget(
        _buildTestWidget(QuickViewModal(item: itemSemPreco, onAdd: () {})),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('x de'), findsNothing);
    });

    testWidgets('exibe ícone padrão quando image_url é null', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(QuickViewModal(item: baseItem, onAdd: () {})),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
    });
  });
}
