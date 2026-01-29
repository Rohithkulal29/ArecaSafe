import 'package:flutter/material.dart';
import 'services/auth_services.dart';
import 'screens/login_screen.dart';
import 'screens/live_sensor_screen.dart';
import 'screens/history_screen.dart';
import 'screens/image_prediction.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthServices.init();
  runApp(const ArecaSafeApp());
}

class ArecaSafeApp extends StatefulWidget {
  const ArecaSafeApp({super.key});
  @override
  State<ArecaSafeApp> createState() => _ArecaSafeAppState();
}

class _ArecaSafeAppState extends State<ArecaSafeApp> {
  int _index = 0;

  final screens = const [
    LiveSensorScreen(),
    HistoryScreen(),
    ImagePredictionScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthServices.currentUser();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "ArecaSafe",
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF5F1FA),
      ),

      // 🚀 ONLY ONE ENTRY POINT — NO ROUTES DEFINED
      home: user == null
          ? const LoginScreen()
          : Scaffold(
              appBar: AppBar(
                title: const Text("ArecaSafe"),
                backgroundColor: Colors.deepPurple,
              ),
              body: screens[_index],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _index,
                onTap: (v) => setState(() => _index = v),
                backgroundColor: Colors.deepPurple,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sensors),
                    label: "Live",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: "History",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.image),
                    label: "Predict",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: "Profile",
                  ),
                ],
              ),
            ),
    );
  }
}
