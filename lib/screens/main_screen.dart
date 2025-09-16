import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import '../features/downloads/presentation/pages/downloads_page.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  // Static key para acceder a la instancia del state desde fuera
  static final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();
  
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const DownloadsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }
  
  // Método público para cambiar el tab desde fuera
  void changeTab(int index) {
    if (mounted && index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Recientes',
          ),
        ],
        ),
      ),
    );
  }
}
