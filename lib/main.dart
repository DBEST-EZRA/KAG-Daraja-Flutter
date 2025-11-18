import 'pages/bible_page.dart';
import 'package:flutter/material.dart';
import 'pages/notices_page.dart';
import 'pages/sermons_page.dart';
import 'pages/live_page.dart';
import 'pages/notes_page.dart';
// import 'pages/sliding_cards_widget.dart'; // REMOVED (or commented out) to fix carousel error

void main() {
  runApp(const MyApp());
}

// Global Theme Manager using ValueNotifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder listens to themeNotifier for changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'KAG DARAJA',
          themeMode: currentMode,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const LivePage(),
    const NotesPage(),
  ];

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper function to toggle the theme mode
  void _toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    // Determine the current icon based on the theme
    final isDarkMode = themeNotifier.value == ThemeMode.dark;
    final icon = isDarkMode ? Icons.light_mode : Icons.dark_mode;

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.background, // Use theme background color
      appBar: AppBar(
        title: const Text(
          'KAG DARAJA',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(
          color: Colors.white, // Hamburger icon color
        ),
        actions: [
          IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: _toggleTheme,
            tooltip: isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'KAG DARAJA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(Icons.home, 'Dashboard', context),
          _buildDrawerItem(Icons.notifications, 'Notices', context),
          _buildDrawerItem(Icons.mic, 'Sermons', context),
          _buildDrawerItem(Icons.people, 'Attendance', context),
          _buildDrawerItem(Icons.payment, 'Giving', context),
          _buildDrawerItem(Icons.chat, 'Chat', context),
          _buildDrawerItem(Icons.work, 'Project', context),
          const Divider(),
          _buildDrawerItem(Icons.login, 'Sign In', context),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // close the drawer
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label tapped!')));
      },
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Back
            Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary, // Use theme primary color
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Glad to see you again.',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // Daily Devotion Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: theme
                  .colorScheme
                  .primaryContainer, // Use a container color for card background
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Devotion',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verse of the day:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"Trust in the Lord with all your heart and lean not on your own understanding." - Proverbs 3:5',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.6),
                          ),
                        ),
                        Text(
                          'Day: ${_getWeekday(DateTime.now())}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Grid of items
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildDashboardItem(
                  context,
                  Icons.notifications,
                  'Notices',
                  Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NoticesPage(),
                      ),
                    );
                  },
                ),
                _buildDashboardItem(
                  context,
                  Icons.mic,
                  'Sermons',
                  Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SermonsPage()),
                    );
                  },
                ),
                _buildDashboardItem(
                  context,
                  Icons.people,
                  'Bible',
                  Colors.pink,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BiblePage()),
                    );
                  },
                ),
                _buildDashboardItem(
                  context,
                  Icons.payment,
                  'Giving',
                  Colors.green,
                ),
                _buildDashboardItem(context, Icons.chat, 'Chat', Colors.purple),
                _buildDashboardItem(
                  context,
                  Icons.work,
                  'Project',
                  Colors.brown,
                ),
              ],
            ),

            // The carousel component is now commented out below
            // const SizedBox(height: 24),
            // const SlidingEventCards(),
            // const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap, // Add optional onTap parameter
  }) {
    return InkWell(
      onTap:
          onTap ??
          () {
            // Default action if no onTap provided
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$label tapped!')));
          },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  static String _getWeekday(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }
}
