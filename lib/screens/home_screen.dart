import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/utils/constants.dart';
import 'fridge_list_screen.dart';
import 'donation_requests_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget{
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context){
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role ?? rolePersonal;

    List<Widget> screens = [];
    List<BottomNavigationBarItem> navItems = [];

    screens.add(const FridgeListScreen());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Fridges'));

    if(userRole == rolePersonal || userRole == roleCompany){
      screens.add(const InventoryScreen());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Inventory'));

      screens.add(const DonationRequestsScreen());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Requests'));  
    }

    if(userRole == roleInNeed){
      screens.add(const DonationRequestsScreen());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Requests'));
    }

    screens.add(const ProfileScreen());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index){
          setState(() {
            _selectedIndex = index;
          });
        }, ),
    );

  }
}