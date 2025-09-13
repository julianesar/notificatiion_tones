import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static NavigationService get instance => _instance;

  // GlobalKey para acceder al Navigator sin depender del contexto
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  void navigateToDownloads() {
    print('NavigationService: Intentando navegar a descargas...');

    if (navigatorKey.currentState != null) {
      print('NavigationService: Navigator disponible');

      // Regresar al MainScreen original (que debería estar en la base)
      navigatorKey.currentState!.popUntil((route) => route.isFirst);

      // Cambiar el tab a descargas después de regresar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_mainScreenStateKey?.currentState != null) {
          print(
            'NavigationService: Cambiando tab a descargas después de popUntil...',
          );
          (_mainScreenStateKey!.currentState! as dynamic).changeTab(2);
          print('NavigationService: Tab cambiado a descargas');
        } else {
          print(
            'NavigationService: MainScreenState no disponible después de popUntil',
          );
        }
      });

      print('NavigationService: PopUntil ejecutado');
    } else {
      print('NavigationService: ¡ERROR! Navigator no está disponible');
    }
  }

  Widget _createMainScreenWithDownloads() {
    // Aquí debemos retornar MainScreen con initialIndex: 2
    // Para evitar import circular, vamos a usar un callback
    return _buildMainScreen();
  }
}

// Función global que será configurada externamente
Widget Function()? _mainScreenBuilder;
// Key para acceder al MainScreenState
GlobalKey? _mainScreenStateKey;

void setMainScreenBuilder(Widget Function() builder) {
  _mainScreenBuilder = builder;
  print('NavigationService: MainScreen builder registrado');
}

void setMainScreenStateKey(GlobalKey key) {
  _mainScreenStateKey = key;
  print('NavigationService: MainScreen state key registrado');
}

Widget _buildMainScreen() {
  if (_mainScreenBuilder != null) {
    print('NavigationService: Creando MainScreen...');
    return _mainScreenBuilder!();
  } else {
    print('NavigationService: ¡ERROR! MainScreen builder no registrado');
    return Container(
      child: const Center(child: Text('Error: MainScreen no disponible')),
    );
  }
}
