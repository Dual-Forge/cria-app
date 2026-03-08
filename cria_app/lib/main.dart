import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Para deixar o calendário em PT-BR
import 'package:intl/date_symbol_data_local.dart'; // Para formatar datas
import 'package:go_router/go_router.dart';
import 'package:url_strategy/url_strategy.dart'; // Remove o '#' da URL na Web
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Importa o arquivo que controla o fluxo de entrada
import 'screens/auth_flow_screens.dart';
import 'screens/web_gift_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Remove o '#' da URL para navegação Web
  setPathUrlStrategy();

  // Inicializa a formatação de datas em Português
  await initializeDateFormatting('pt_BR', null);

  // --- CONFIGURAÇÃO DO SUPABASE ---
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
      GoRoute(
        path: '/presentes/:id',
        builder: (context, state) {
          final familyId = state.pathParameters['id']!;
          return WebGiftScreen(familyId: familyId);
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
