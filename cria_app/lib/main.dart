import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:cria_app/core/config/env_config.dart';
import 'package:cria_app/features/parents/ui/auth_flow_screens.dart';
import 'package:cria_app/features/store_scraping/ui/web_gift_screen.dart';
import 'package:cria_app/features/store_scraping/services/payment_service.dart';
import 'package:cria_app/widgets/app_background.dart';
import 'package:cria_app/features/baby/ui/baby_details_screen.dart';
import 'package:cria_app/features/store_scraping/ui/public_registry_screen.dart';
import 'package:cria_app/features/splash/ui/splash_screen.dart';
import 'package:cria_app/features/parents/ui/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  setPathUrlStrategy();
  await initializeDateFormatting('pt_BR', null);

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(CriaApp());
}

class CriaApp extends StatelessWidget {
  CriaApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const AuthGateScreen()),
      GoRoute(path: '/home', builder: (context, state) => const MainScreen()),

      // 1. ROTA PÚBLICA (Vitrine) - O link que os pais compartilham
      GoRoute(
        path: '/presentes/:id',
        builder: (context, state) {
          final familyId = state.pathParameters['id']!;
          return PublicRegistryScreen(familyId: familyId); // Abre a nova tela!
        },
      ),

      // Baby Details Route
      GoRoute(
        path: '/baby-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BabyDetailsScreen(
            profilePhotoUrl: extra['profilePhotoUrl'],
            lastBpm: extra['lastBpm'],
            expectedDueDate: extra['expectedDueDate'],
            dumDate: extra['dumDate'],
            kickCount: extra['kickCount'] ?? 0,
            babyName: extra['babyName'] ?? 'Bebê',
            familyId: extra['familyId'] ?? '',
            themeColor: extra['themeColor'] ?? Colors.pink,
          );
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
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.quicksand(),
          displayMedium: GoogleFonts.quicksand(),
          displaySmall: GoogleFonts.quicksand(),
          headlineLarge: GoogleFonts.quicksand(),
          headlineMedium: GoogleFonts.quicksand(),
          headlineSmall: GoogleFonts.quicksand(),
          titleLarge: GoogleFonts.quicksand(),
          titleMedium: GoogleFonts.quicksand(),
          titleSmall: GoogleFonts.quicksand(),
        ),
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
