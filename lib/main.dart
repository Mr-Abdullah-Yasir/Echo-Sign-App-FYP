import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';


import 'providers/auth_provider.dart';
//import 'services/offline_asr_service.dart';
import 'screens/backup_restore_screen.dart';
import 'screens/edit_profile.dart';
import 'screens/email_verification_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/history_screen.dart';
//import 'screens/avatar_result.dart';

import 'screens/get_started_screen.dart';
//import 'screens/gloss_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/practics_videos.dart';
import 'screens/profile.dart';
import 'screens/secure_screen.dart';
import 'screens/settings_screen.dart';
//import 'screens/sign_animation.dart';

import 'screens/demo_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/skip_continue_screen.dart';
import 'screens/speak_listening.dart';
import 'screens/speak_to_sign.dart';
import 'screens/sign_to_speak.dart';
import 'screens/splash_screen.dart';
import 'screens/text_to_gloss.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());

  // Start preparing Whisper base.en in the background while the user is on
  // Splash/Login. Do not await it: authentication UI should open immediately.
  // unawaited(
  //   OfflineAsrService.instance.prepareModel().catchError((_) {
  //     // Speak -> Sign will show the user-friendly error if warm-up failed.
  //   }),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Echo Sign',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: SplashScreen.routeName,
        routes: {
          DemoScreen.routeName:(_) => const DemoScreen(), 
          SplashScreen.routeName: (_) => const SplashScreen(),
          SecureScreen.routeName: (_) => const SecureScreen(),
          SkipContinueScreen.routeName: (_) => const SkipContinueScreen(),
          GetStartedScreen.routeName: (_) => const GetStartedScreen(),
          LoginScreen.routeName: (_) => const LoginScreen(),
          SignupScreen.routeName: (_) => const SignupScreen(),
          EmailVerificationScreen.routeName: (_) =>
          
              const EmailVerificationScreen(),
          MainScreen.routeName: (_) => const MainScreen(),
          TypeToGlossScreen.routeName: (_) => const TypeToGlossScreen(),
          SpeakToSignScreen.routeName: (_) => const SpeakToSignScreen(),
          SpeakListeningScreen.routeName: (_) => const SpeakListeningScreen(),

          // AvatarResultScreen receives speech text/gloss through MaterialPageRoute.
          SignToSpeakScreen.routeName: (_) => const SignToSpeakScreen(),
          PracticeScreen.routeName: (_) => const PracticeScreen(),
          ProfileScreen.routeName: (_) => const ProfileScreen(),
          EditProfileScreen.routeName: (_) => const EditProfileScreen(),
          BackupRestoreScreen.routeName: (_) => const BackupRestoreScreen(),
          HistoryScreen.routeName: (_) => const HistoryScreen(),
          FavoritesScreen.routeName: (_) => const FavoritesScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),

        },
      ),
    );
  }
}


