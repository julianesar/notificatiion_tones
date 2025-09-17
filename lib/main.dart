import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'core/network/api_client.dart';
import 'features/categories/data/datasources/categories_remote_ds.dart';
import 'features/categories/data/repositories/categories_repository_impl.dart';
import 'features/categories/domain/usecases/get_categories.dart';
import 'features/categories/presentation/providers/categories_provider.dart';
import 'features/tones/data/datasources/tones_remote_ds.dart';
import 'features/tones/data/repositories/tones_repository_impl.dart';
import 'features/tones/domain/usecases/get_tones_by_category.dart';
import 'features/tones/presentation/providers/tones_provider.dart';
import 'features/favorites/data/datasources/favorites_local_ds.dart';
import 'features/favorites/data/repositories/favorites_repository_impl.dart';
import 'features/favorites/domain/usecases/get_all_favorites.dart';
import 'features/favorites/domain/usecases/toggle_favorite.dart';
import 'features/favorites/domain/usecases/is_favorite.dart';
import 'features/favorites/domain/usecases/clear_all_favorites.dart';
import 'features/favorites/presentation/providers/favorites_provider.dart';
import 'core/services/audio_service.dart';
import 'core/services/permissions_service.dart';
import 'core/di/service_locator.dart' as di;
import 'features/downloads/presentation/providers/downloads_provider.dart';
import 'features/contacts/presentation/providers/contacts_provider.dart';
import 'core/navigation/navigation_service.dart';

void main() async {
  // Asegurarse de que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI overlay style globally for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicialización perezosa del singleton
  AppConfig.I();

  // Initialize service locator
  await di.init();

  // Obtener instancia de ApiClient de forma asíncrona
  final apiClient = await ApiClient.getInstance();
  
  // Initialize audio service
  await AudioService.instance.initialize();

  // Setup navigation service callback
  print('Main: Configurando NavigationService con GlobalKey...');
  setMainScreenBuilder(() => const MainScreen(initialIndex: 2));
  setMainScreenStateKey(MainScreen.mainScreenKey);
  print('Main: NavigationService configurado correctamente');

  // Initialize favorites dependencies
  final favoritesLocalDS = FavoritesLocalDSImpl();
  final favoritesRepository = FavoritesRepositoryImpl(favoritesLocalDS);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: AudioService.instance),
        Provider<PermissionsService>(
          create: (_) => di.sl<PermissionsService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoriesProvider(
            GetCategories(
              CategoriesRepositoryImpl(CategoriesRemoteDS(apiClient)),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TonesProvider(
            GetTonesByCategory(TonesRepositoryImpl(TonesRemoteDS(apiClient))),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(
            getAllFavorites: GetAllFavorites(favoritesRepository),
            toggleFavorite: ToggleFavorite(favoritesRepository),
            isFavorite: IsFavorite(favoritesRepository),
            clearAllFavorites: ClearAllFavorites(favoritesRepository),
          ),
        ),
        ChangeNotifierProvider<DownloadsProvider>(
          create: (_) => di.sl<DownloadsProvider>(),
        ),
        ChangeNotifierProvider<ContactsProvider>(
          create: (_) => di.sl<ContactsProvider>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sonidos de Notificaciones',
          theme: themeProvider.currentTheme,
          navigatorKey: NavigationService.navigatorKey,
          home: MainScreen(key: MainScreen.mainScreenKey),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
