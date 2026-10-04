import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'db.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  ThemeData _theme(Brightness b) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E), brightness: b),
    );
    return base.copyWith(
        textTheme: GoogleFonts.vazirmatnTextTheme(base.textTheme));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خلاصه‌یار کتاب',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (c, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeScreen(),
    );
  }
}
