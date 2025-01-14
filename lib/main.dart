import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/call_screen.dart';
import 'services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configService = ConfigService();
  await configService.loadConfig();
  try {
    await configService.loadConfig(); // Загружаем конфигурацию
    runApp(MyApp());
  } catch (e) {
    print('Failed to load config: $e');
    // runApp(ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Chat App',
      initialRoute: '/',
      routes: {
        '/': (context) => AuthScreen(),
        '/friends': (context) => FriendsScreen(
          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>)['myId'],
          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>)['token'],
        ),
        '/call': (context) => WebRTCVideoChat(
          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>)['myId'],
          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>)['friendId'],
        ),
      },
    );
  }
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: WebRTCVideoChat(),
//     );
//   }
// }

