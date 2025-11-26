import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../pages/Customer/booking_screen.dart';
import '../pages/Customer/home_screen.dart';
import '../pages/Customer/search_screen.dart';
import '../pages/Customer/profile_screen.dart';
import '../pages/Provider/provide_profile_screen.dart';
import '../pages/Provider/provider_analytics_screen.dart';
import '../pages/Provider/provider_bookings_screen.dart';
import '../pages/Provider/provider_home_screen.dart';

class BottomNavBar extends StatefulWidget {
  final String userType;
  final int initialIndex;
  final String userId;

  const BottomNavBar({
    super.key,
    required this.userType,
    required this.initialIndex,
    required this.userId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;
  late final String _userType = widget.userType.toString();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  late final List<Widget> _customerPages = [
    HomeScreen(userId: widget.userId),
    SearchScreen(),
    BookingScreen(),
    ProfileScreen(),
  ];

  late final List<Widget> _providerPages = [
    ProviderHomeScreen(providerId: widget.userId),
    ProviderAnalyticsScreen(),
    ProviderBookingsScreen(),
    ProviderProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _userType == "provider"
              ? _providerPages[_selectedIndex]
              : _customerPages[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
        height: MediaQuery.of(context).size.height * 0.067,
        backgroundColor: Colors.white,
        activeColor: Colors.orange,
        color: Colors.black87,
        style: TabStyle.react,
        curveSize: 100,
        items:
            _userType == "provider"
                ? [
                  TabItem(icon: Icons.home, title: 'Home'),
                  TabItem(icon: Icons.bar_chart, title: 'Analytics'),
                  TabItem(icon: Icons.calendar_today, title: 'Bookings'),
                  TabItem(icon: Icons.person, title: 'Profile'),
                ]
                : [
                  TabItem(icon: Icons.home, title: 'Home'),
                  TabItem(icon: Icons.search, title: 'Search'),
                  TabItem(icon: Icons.calendar_today, title: 'Bookings'),
                  TabItem(icon: Icons.person, title: 'Profile'),
                ],
        initialActiveIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
