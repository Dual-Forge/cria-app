import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Para deixar o calendário em PT-BR
import 'package:intl/date_symbol_data_local.dart'; // Para formatar datas

// Importa o arquivo que controla o fluxo de entrada
import 'screens/auth_flow_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa a formatação de datas em Português
  await initializeDateFormatting('pt_BR', null);

  // --- CONFIGURAÇÃO DO SUPABASE ---
  // ATENÇÃO: Se você copiou suas chaves antes, cole-as aqui novamente.
  // Se elas sumiram, pegue no Supabase Dashboard > Project Settings > API
  await Supabase.initialize(
    url: 'https://drkuxfafxoruuvszowld.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRya3V4ZmFmeG9ydXV2c3pvd2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwNDczNDAsImV4cCI6MjA4NTYyMzM0MH0.Bqx6dSMel9Bj3rjOCXJFINJrhJV8IrhQWOyocrFBxGY',
  );

  runApp(const CriaApp());
}

class CriaApp extends StatelessWidget {
  const CriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cria',
      debugShowCheckedModeBanner: false, // Remove a faixa "Debug" do canto
      // Configurações de Tema Padrão
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),

      // --- CONFIGURAÇÃO DE IDIOMA (PT-BR) ---
      // Isso faz o calendário e os date pickers ficarem em português
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],

      // --- PONTO DE PARTIDA ---
      // Chama o "Portão de Autenticação" que criamos no auth_flow_screens.dart
      // Ele vai decidir automaticamente para onde mandar o usuário.
      home: const AuthGateScreen(),
    );
  }
}
