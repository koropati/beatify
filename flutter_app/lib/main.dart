import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_theme.dart';
import 'features/music_player/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.beatify.channel.audio',
    androidNotificationChannelName: 'Beatify',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
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
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => const LoginPage(),
      ),
    );
  }
}
