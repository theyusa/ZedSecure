import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/theme_service.dart';
import 'package:zedsecure/services/app_settings_service.dart';
import 'package:zedsecure/services/update_checker_service.dart';
import 'package:zedsecure/services/mmkv_manager.dart';
import 'package:zedsecure/widgets/update_dialog.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:zedsecure/screens/home_screen.dart';
import 'package:zedsecure/screens/servers_screen.dart';
import 'package:zedsecure/screens/subscriptions_screen.dart';
import 'package:zedsecure/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await MmkvManager.initialize();
  
  await MmkvManager.migrateFromSharedPreferences();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => V2RayService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AppSettingsService()..loadSettings()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          final themeData = themeService.getThemeData(context);
          final isDark = themeData.brightness == Brightness.dark;
          
          return MaterialApp(
            title: 'ZedSecure VPN',
            themeMode: themeService.themeMode,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            home: const MainNavigation(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AnimatedTheme(
                data: themeData,
                duration: const Duration(milliseconds: 400),
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                  ),
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ServersScreen(),
    SubscriptionsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final updateInfo = await UpdateCheckerService.checkForUpdates();
    if (updateInfo != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(updateInfo: updateInfo),
      );
    }
  }

  Future<void> _initializeApp() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    await service.initialize();
  }

  void _onTabTapped(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: theme.scaffoldBackgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildGlassTabBar(isDark),
      ),
    );
  }

  Widget _buildGlassTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark 
                ? Colors.black.withOpacity(0.7)
                : Colors.white.withOpacity(0.85),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(0, CupertinoIcons.house_fill, 'Home', isDark),
              _buildTabItem(1, CupertinoIcons.rectangle_stack_fill, 'Servers', isDark),
              _buildTabItem(2, CupertinoIcons.cloud_fill, 'Subs', isDark),
              _buildTabItem(3, CupertinoIcons.gear_solid, 'Settings', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isSelected ? 8 : 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? AppTheme.primaryBlue.withOpacity(0.15)
                      : Colors.transparent,
                ),
                child: Icon(
                  icon,
                  size: isSelected ? 24 : 22,
                  color: isSelected 
                      ? AppTheme.primaryBlue 
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? AppTheme.primaryBlue 
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
