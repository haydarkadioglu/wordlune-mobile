import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WordLuneApp());
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere((e) => e.toString() == 'ThemeMode.$theme');
    notifyListeners();
  }

  void setTheme(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString().split('.').last);
    notifyListeners();
  }
}

class WordLuneApp extends StatelessWidget {
  const WordLuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'WordLune',
            debugShowCheckedModeBanner: false,
            routes: {
              '/login': (context) => LoginScreen(onRegisterTap: () => Navigator.pushReplacementNamed(context, '/register')),
              '/register': (context) => RegisterScreen(onLoginTap: () => Navigator.pushReplacementNamed(context, '/login')),
              '/dashboard': (context) => const DashboardScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.light(
                primary: Color(0xFF4FC3F7),
                secondary: Color(0xFF64B5F6),
                surface: Colors.white,
                surfaceContainerHighest: Color(0xFFF8F9FA),
              ),
              textTheme: GoogleFonts.poppinsTextTheme(),
              scaffoldBackgroundColor: Color(0xFFF8F9FA),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.dark(
                primary: Color(0xFF4FC3F7),
                secondary: Color(0xFF64B5F6),
                surface: Color(0xFF1E1E2E),
                surfaceContainerHighest: Color(0xFF181825),
                onSurface: Color(0xFFCDD6F4),
                outline: Color(0xFF313244),
              ),
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
                bodyLarge: GoogleFonts.poppins(color: Color(0xFFCDD6F4)),
                bodyMedium: GoogleFonts.poppins(color: Color(0xFFCDD6F4)),
                titleLarge: GoogleFonts.poppins(color: Color(0xFFCDD6F4)),
                titleMedium: GoogleFonts.poppins(color: Color(0xFFCDD6F4)),
              ),
              scaffoldBackgroundColor: Color(0xFF181825),
              cardColor: Color(0xFF1E1E2E),
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFF181825),
                surfaceTintColor: Colors.transparent,
              ),
            ),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('tr'),
            ],
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showLogin = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        return showLogin
            ? LoginScreen(onRegisterTap: () => setState(() => showLogin = false))
            : RegisterScreen(onLoginTap: () => setState(() => showLogin = true));
      },
    );
  }
}
