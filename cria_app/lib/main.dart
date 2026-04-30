import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:cria_app/screens/auth_flow_screens.dart';
import 'package:cria_app/screens/web_gift_screen.dart';
import 'package:cria_app/services/payment_service.dart';
import 'package:cria_app/widgets/app_background.dart';

// IMPORTANTE: Importamos a nova vitrine pública!
import 'package:cria_app/screens/public_registry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  setPathUrlStrategy();
  await initializeDateFormatting('pt_BR', null);

  await Supabase.initialize(
    url: 'https://drkuxfafxoruuvszowld.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRya3V4ZmFmeG9ydXV2c3pvd2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwNDczNDAsImV4cCI6MjA4NTYyMzM0MH0.Bqx6dSMel9Bj3rjOCXJFINJrhJV8IrhQWOyocrFBxGY',
  );

  runApp(CriaApp());
}

class CriaApp extends StatelessWidget {
  CriaApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AuthGateScreen()),

      // 1. ROTA PÚBLICA (Vitrine) - O link que os pais compartilham
      GoRoute(
        path: '/presentes/:id',
        builder: (context, state) {
          final familyId = state.pathParameters['id']!;
          return PublicRegistryScreen(familyId: familyId); // Abre a nova tela!
        },
      ),

      // 2. ROTA DE PAGAMENTO (Checkout) - Oculta, acessada após escolher o presente
      GoRoute(
        path: '/checkout/:id',
        builder: (context, state) {
          final familyId = state.pathParameters['id']!;
          final paymentService = PaymentService(Supabase.instance.client);

          // Pega o item que o usuário selecionou na tela anterior
          final selectedItems =
              state.extra as List<Map<String, dynamic>>? ?? [];

          return WebGiftScreen(
            familyId: familyId,
            paymentService: paymentService,
            selectedItems: selectedItems, // Envia para o Mercado Pago!
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cria',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // Aplica o background global UMA vez, por trás de toda a navegação.
      // GlobalBackgroundWrapper aceita child nullable e usa SizedBox.shrink()
      // como fallback durante a inicialização do GoRouter no Web.
      builder: (context, child) => GlobalBackgroundWrapper(child: child),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
    );
  }
}
