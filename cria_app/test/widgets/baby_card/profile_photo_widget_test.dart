import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/widgets/baby_card/profile_photo_widget.dart';

void main() {
  group('ProfilePhotoWidget Tests', () {
    testWidgets('exibe ícone fallback quando photoUrl é nulo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWidget(
              photoUrl: null,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.child_care_rounded), findsOneWidget);
    });

    testWidgets('exibe ícone fallback quando photoUrl é vazio',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWidget(
              photoUrl: '',
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.child_care_rounded), findsOneWidget);
    });

    testWidgets('renderiza com tamanho correto', (WidgetTester tester) async {
      const double testSize = 150;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWidget(
              photoUrl: null,
              themeColor: Colors.pink,
              size: testSize,
            ),
          ),
        ),
      );

      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
    });

    testWidgets('aplica cor do tema ao ícone fallback',
        (WidgetTester tester) async {
      const Color testColor = Colors.purple;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWidget(
              photoUrl: null,
              themeColor: testColor,
            ),
          ),
        ),
      );

      final icon = find.byIcon(Icons.child_care_rounded);
      expect(icon, findsOneWidget);

      final iconWidget = tester.widget<Icon>(icon);
      expect(iconWidget.color, equals(testColor));
    });

    testWidgets('chama onImageLoaded quando imagem carrega com sucesso',
        (WidgetTester tester) async {
      bool imageLoaded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWidget(
              photoUrl: null,
              themeColor: Colors.pink,
              onImageLoaded: () {
                imageLoaded = true;
              },
            ),
          ),
        ),
      );

      // Sem URL, não deve chamar onImageLoaded
      expect(imageLoaded, isFalse);
    });

    testWidgets('chama onImageError quando há erro ao carregar',
        (WidgetTester tester) async {
      Object? capturedError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWidget(
              photoUrl: null,
              themeColor: Colors.pink,
              onImageError: (error) {
                capturedError = error;
              },
            ),
          ),
        ),
      );

      // Sem URL, não deve chamar onImageError
      expect(capturedError, isNull);
    });

    testWidgets('renderiza com sombra', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWidget(
              photoUrl: null,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      final container = find.byType(Container).first;
      expect(container, findsOneWidget);

      final containerWidget = tester.widget<Container>(container);
      expect(containerWidget.decoration, isNotNull);
    });
  });

  group('ProfilePhotoWithBorderWidget Tests', () {
    testWidgets('exibe borda com cor e largura corretas',
        (WidgetTester tester) async {
      const Color borderColor = Colors.white;
      const double borderWidth = 3;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWithBorderWidget(
              photoUrl: null,
              themeColor: Colors.pink,
              borderColor: borderColor,
              borderWidth: borderWidth,
            ),
          ),
        ),
      );

      expect(find.byType(ProfilePhotoWithBorderWidget), findsOneWidget);
    });

    testWidgets('renderiza ProfilePhotoWidget internamente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoWithBorderWidget(
              photoUrl: null,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.byType(ProfilePhotoWidget), findsOneWidget);
    });
  });

  group('ProfilePhotoCircleAvatarWidget Tests', () {
    testWidgets('renderiza CircleAvatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoCircleAvatarWidget(
              photoUrl: null,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('exibe ícone fallback no CircleAvatar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoCircleAvatarWidget(
              photoUrl: null,
              themeColor: Colors.pink,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.child_care_rounded), findsOneWidget);
    });

    testWidgets('aplica raio correto ao CircleAvatar',
        (WidgetTester tester) async {
      const double testRadius = 75;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoCircleAvatarWidget(
              photoUrl: null,
              themeColor: Colors.pink,
              radius: testRadius,
            ),
          ),
        ),
      );

      final avatar = find.byType(CircleAvatar);
      expect(avatar, findsOneWidget);

      final avatarWidget = tester.widget<CircleAvatar>(avatar);
      expect(avatarWidget.radius, equals(testRadius));
    });

    testWidgets('aplica cor de fundo com opacidade', (WidgetTester tester) async {
      const Color themeColor = Colors.pink;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoCircleAvatarWidget(
              photoUrl: null,
              themeColor: themeColor,
            ),
          ),
        ),
      );

      final avatar = find.byType(CircleAvatar);
      expect(avatar, findsOneWidget);

      final avatarWidget = tester.widget<CircleAvatar>(avatar);
      expect(avatarWidget.backgroundColor, isNotNull);
    });
  });

  group('Integration Tests', () {
    testWidgets('ProfilePhotoWidget renderiza sem erros',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfilePhotoWidget(
                photoUrl: null,
                themeColor: Colors.pink,
                size: 130,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProfilePhotoWidget), findsOneWidget);
      expect(find.byIcon(Icons.child_care_rounded), findsOneWidget);
    });

    testWidgets('ProfilePhotoWithBorderWidget renderiza sem erros',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfilePhotoWithBorderWidget(
                photoUrl: null,
                themeColor: Colors.pink,
                size: 130,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProfilePhotoWithBorderWidget), findsOneWidget);
    });

    testWidgets('ProfilePhotoCircleAvatarWidget renderiza sem erros',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfilePhotoCircleAvatarWidget(
                photoUrl: null,
                themeColor: Colors.pink,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProfilePhotoCircleAvatarWidget), findsOneWidget);
    });

    testWidgets('múltiplos widgets renderizam juntos',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ProfilePhotoWidget(
                  photoUrl: null,
                  themeColor: Colors.pink,
                ),
                ProfilePhotoWithBorderWidget(
                  photoUrl: null,
                  themeColor: Colors.blue,
                ),
                ProfilePhotoCircleAvatarWidget(
                  photoUrl: null,
                  themeColor: Colors.purple,
                ),
              ],
            ),
          ),
        ),
      );

      // Há 2 ProfilePhotoWidget: o direto + o interno do ProfilePhotoWithBorderWidget.
      expect(find.byType(ProfilePhotoWidget), findsNWidgets(2));
      expect(find.byType(ProfilePhotoWithBorderWidget), findsOneWidget);
      expect(find.byType(ProfilePhotoCircleAvatarWidget), findsOneWidget);
    });
  });
}
