import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'shopping_list_screen.dart'; // <--- O NOME CERTO É ESSE
import 'diary_screen.dart';
import 'timeline_screen.dart';
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _familyStream,
      builder: (context, snapshot) {
        Color themeColor = Colors.purple;
        String? babyName;
        String? babyGender;
        DateTime? dumDate;
        String? familyCode;
        String? babyPhotoUrl;

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          babyName = data['baby_name'];
          babyGender = data['baby_gender'];
          familyCode = data['invite_code'];
          babyPhotoUrl = data['baby_photo_url'];
          
          if (data['dum_date'] != null) {
            dumDate = DateTime.parse(data['dum_date']);
          }

          if (babyGender == 'menino') {
            themeColor = const Color(0xFF64B5F6);
          } else if (babyGender == 'menina') {
            themeColor = const Color(0xFFF06292);
          } else {
            themeColor = Colors.deepPurple.shade300;
          }
        }

        final List<Widget> screens = [
          HomePregnancyScreen(
            themeColor: themeColor,
            babyName: babyName,
            babyGender: babyGender,
            babyPhotoUrl: babyPhotoUrl,
            dumDate: dumDate,
            familyCode: familyCode,
            familyId: _familyId,
          ),

          // AQUI: USAMOS O SHOPPING LIST COM O ID DA FAMILIA
          ShoppingListScreen(currentTheme: themeColor, familyId: _familyId),

          DiaryScreen(themeColor: themeColor, familyId: _familyId),
          TimelineScreen(currentTheme: themeColor, familyId: _familyId),
          SettingsScreen(themeColor: themeColor),
        ];

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: CurvedNavigationBar(
            index: _currentIndex,
            backgroundColor: Colors.transparent,
            color: Colors.white,
            buttonBackgroundColor: Colors.white,
            animationCurve: Curves.easeInOut,
            animationDuration: const Duration(milliseconds: 300),
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: [
              Icon(Icons.favorite, color: _currentIndex == 0 ? themeColor : Colors.grey[600]),
              Icon(Icons.shopping_bag, color: _currentIndex == 1 ? themeColor : Colors.grey[600]),
              Icon(Icons.book, color: _currentIndex == 2 ? themeColor : Colors.grey[600]),
              Icon(Icons.photo_library, color: _currentIndex == 3 ? themeColor : Colors.grey[600]),
              Icon(Icons.settings, color: _currentIndex == 4 ? themeColor : Colors.grey[600]),
            ],
          ),
        );
      },
    );
  }
}
