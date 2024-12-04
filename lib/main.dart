import 'package:chat_app/fibaseapi.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/providers/ai_chat_image_provider.dart';
import 'package:chat_app/providers/chat_provider.dart';
import 'package:chat_app/providers/status_provider.dart';
import 'package:chat_app/providers/user_provider.dart';
import 'package:chat_app/screens/SignInPages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  Gemini.init(apiKey: dotenv.env['api_Key']!);
  FirebaseApi firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();
  firebaseApi.handleReceivedMessages();
  firebaseApi.initBackgroundSettings();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
    ),
    ChangeNotifierProvider(
      create: (context) => ChatProvider(),
    ),
    ChangeNotifierProvider(
      create: (context) => StatusProvider(),
    ),
    ChangeNotifierProvider(
      create: (context) => AiChatImageProvider(),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'chatJet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
