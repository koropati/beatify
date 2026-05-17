import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_theme.dart';
import 'features/music_player/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.beatify.channel.audio',
    androidNotificationChannelName: 'Beatify',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: BeatifyApp()));
}

class BeatifyApp extends ConsumerWidget {
  const BeatifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Beatify',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) => user != null ? const HomePage() : const LoginPage(),
        loading: () => const _SplashScreen(),
        error: (error, stack) => const LoginPage(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image(
                image: AssetImage('assets/images/logo.png'),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Beatify',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF1DB954),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
