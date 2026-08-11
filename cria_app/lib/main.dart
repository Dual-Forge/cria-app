import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
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
import 'package:cria_app/widgets/app_background.dart';
import 'package:cria_app/features/baby/ui/baby_details_screen.dart';
import 'package:cria_app/features/splash/ui/splash_screen.dart';
import 'package:cria_app/features/parents/ui/main_screen.dart';
import 'package:cria_app/features/parents/ui/login_screen.dart';
import 'package:cria_app/features/parents/ui/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SEGURANÇA (SEG-01): o .env NÃO é mais asset e NUNCA é carregado em produção.
  // Em debug, carregamos o .env local apenas para o desenvolvimento (editor);
  // em release, a configuração vem exclusivamente de --dart-define via EnvConfig.
  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('[main] .env carregado (desenvolvimento).');
    } catch (_) {
      debugPrint('[main] .env não encontrado (dev) — usando dart-define.');
    }
  }

  // url_strategy é exclusivo da Web
  if (kIsWeb) {
    setPathUrlStrategy();
  }

  await initializeDateFormatting('pt_BR', null);

  final supabaseUrl = EnvConfig.supabaseUrl;
  final supabaseAnonKey = EnvConfig.supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint(
      '[main] ERRO: credenciais Supabase não configuradas! '
      'Verifique --dart-define=SUPABASE_URL e --dart-define=SUPABASE_ANON_KEY.',
    );
    runApp(const _ConfigErrorApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    // Falha rara de inicialização (rede/perm) nunca pode virar tela branca.
    debugPrint('[main] ERRO ao inicializar Supabase: $e');
    runApp(const _ConfigErrorApp());
    return;
  }

  runApp(const CriaApp());
}

// ─────────────────────────────────────────────
// SupabaseAuthNotifier — ChangeNotifier que escuta o stream de auth
// e notifica o GoRouter via refreshListenable.
// Isso elimina race conditions de chamar _router.go() antes do router existir.
// ─────────────────────────────────────────────
class SupabaseAuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;
  Session? _session;

  SupabaseAuthNotifier() {
    // Lê a sessão atual de forma síncrona (pode já estar disponível)
    _session = Supabase.instance.client.auth.currentSession;

    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('[Auth] Evento: ${data.event} | session: ${data.session?.user.id}');
      _session = data.session;
      notifyListeners(); // dispara o redirect do GoRouter automaticamente
    });
  }

  Session? get session => _session;
  bool get isLoggedIn => _session != null;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// CriaApp
// ─────────────────────────────────────────────
class CriaApp extends StatefulWidget {
  const CriaApp({super.key});

  @override
  State<CriaApp> createState() => _CriaAppState();
}

class _CriaAppState extends State<CriaApp> {
  late final SupabaseAuthNotifier _authNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _authNotifier = SupabaseAuthNotifier();

    _router = GoRouter(
      // Sempre inicia em '/'. O redirect decide para onde ir com base na sessão.
      initialLocation: '/',

      // refreshListenable: o router reavalia o redirect automaticamente
      // sempre que o auth muda — sem _router.go() manual e sem race conditions.
      refreshListenable: _authNotifier,

      redirect: (context, state) {
        final isLoggedIn = _authNotifier.isLoggedIn;
        final location = state.matchedLocation;

        debugPrint('[Router] redirect → isLoggedIn=$isLoggedIn, location=$location');

        final publicRoutes = ['/login'];
        final isPublic = publicRoutes.contains(location);

        // Se não logado e tentando acessar rota protegida → login
        if (!isLoggedIn && !isPublic) {
          return '/login';
        }

        // Se logado e na tela de login → /splash
        if (isLoggedIn && location == '/login') {
          return '/splash';
        }

        // Se logado e na rota raiz → /splash
        if (isLoggedIn && location == '/') {
          return '/splash';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthGateScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainScreen(),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),

        // Baby Details
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

      ],
    );
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cria',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) => Material(
        type: MaterialType.transparency,
        child: GlobalBackgroundWrapper(child: child),
      ),
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

/// Exibida quando as credenciais do Supabase não estão configuradas.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF0F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Configuração Incompleta',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'As variáveis SUPABASE_URL e SUPABASE_ANON_KEY não foram encontradas.\n\n'
                  'Verifique se o arquivo .env está presente e configurado corretamente.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
