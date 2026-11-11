import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/file_repository.dart';
import 'core/repositories/subject_repository.dart';
import 'core/services/download_service.dart';
import 'core/services/offline_library_service.dart';
import 'core/services/update_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/downloads/logic/download_cubit.dart';
import 'features/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local persistent preferences & theme
  try {
    await LocalStorageService.initialize();
    await ThemeController.instance.init();
  } catch (e) {
    debugPrint('Service init warning: $e');
  }

  // Dark system navigation and status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090D16),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  bool firebaseInitialized = false;
  String? firebaseError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    firebaseError = e.toString();
    debugPrint('Firebase initialization error: $e');
  }

  runApp(
    NotesHubApp(
      firebaseInitialized: firebaseInitialized,
      initializationError: firebaseError,
    ),
  );
}

class NotesHubApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? initializationError;

  const NotesHubApp({
    super.key,
    this.firebaseInitialized = true,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context) {
    // If Firebase is initialized, provide repositories & BLoCs
    if (firebaseInitialized) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>(
            create: (_) => AuthRepository(),
          ),
          RepositoryProvider<SubjectRepository>(
            create: (_) => SubjectRepository(),
          ),
          RepositoryProvider<FileRepository>(
            create: (_) => FileRepository(),
          ),
          RepositoryProvider<OfflineLibraryService>(
            create: (_) => OfflineLibraryService(),
          ),
          RepositoryProvider<DownloadService>(
            create: (_) => DownloadService(),
          ),
          RepositoryProvider<UpdateService>(
            create: (_) => UpdateService(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(
                authRepository: context.read<AuthRepository>(),
              )..add(const AuthStarted()),
            ),
            BlocProvider<DownloadCubit>(
              create: (context) => DownloadCubit(
                downloadService: context.read<DownloadService>(),
                libraryService: context.read<OfflineLibraryService>(),
              )..loadLibrary(),
            ),
          ],
          child: ThemeScope(
            controller: ThemeController.instance,
            child: Builder(
              builder: (context) {
                final themeController = ThemeScope.of(context);
                return MaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeController.themeMode,
                  home: const HomeScreen(),
                );
              },
            ),
          ),
        ),
      );
    }

    // Graceful fallback UI if Firebase fails to initialize
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Initialization Notice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  initializationError ?? 'Unable to connect to Firebase services.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
