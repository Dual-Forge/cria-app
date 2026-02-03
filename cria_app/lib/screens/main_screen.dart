import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'shopping_list_screen.dart'; // <--- O NOME CERTO É ESSE
import 'diary_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Stream<Map<String, dynamic>>? _familyStream;
  String? _familyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  Future<void> _setupRealtimeListener() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null && profile['family_id'] != null) {
        setState(() {
          _familyId = profile['family_id'];
          _familyStream = Supabase.instance.client
              .from('families')
              .stream(primaryKey: ['id'])
              .eq('id', _familyId!)
              .map((event) => event.first);
          _isLoading = false;
        });
      } else {
        // Se nao tem familia, para de carregar para não travar
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<Map<String, dynamic>>(
      stream: _familyStream,
      builder: (context, snapshot) {
        Color themeColor = Colors.purple;
        String? babyName;
        String? babyGender;
        DateTime? dumDate;
        String? familyCode;

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          babyName = data['baby_name'];
          babyGender = data['baby_gender'];
          familyCode = data['invite_code'];
          if (data['dum_date'] != null)
            dumDate = DateTime.parse(data['dum_date']);

          if (babyGender == 'menino')
            themeColor = const Color(0xFF64B5F6);
          else if (babyGender == 'menina')
            themeColor = const Color(0xFFF06292);
          else
            themeColor = Colors.deepPurple.shade300;
        }

        final List<Widget> screens = [
          HomePregnancyScreen(
            themeColor: themeColor,
            babyName: babyName,
            babyGender: babyGender,
            dumDate: dumDate,
            familyCode: familyCode,
            familyId: _familyId,
          ),

          // AQUI: USAMOS O SHOPPING LIST COM O ID DA FAMILIA
          ShoppingListScreen(currentTheme: themeColor, familyId: _familyId),

          DiaryScreen(themeColor: themeColor, familyId: _familyId),
          SettingsScreen(themeColor: themeColor),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text("Cria"),
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  // Adicione sua navegação de login aqui se necessário
                },
              ),
            ],
          ),
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            indicatorColor: themeColor.withOpacity(0.3),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Gravidez',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'Enxoval',
              ),
              NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book),
                label: 'Diário',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
          ),
        );
      },
    );
  }
}
