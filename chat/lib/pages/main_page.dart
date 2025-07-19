import 'package:flutter/material.dart';
import 'package:chat/pages/chat_list_page.dart';
import 'package:chat/pages/home_info_page.dart';
import 'package:chat/constant.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.payload});

  final dynamic payload;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1;
  List<StatefulWidget>? _pages;
  dynamic _pendingPayload;

  @override
  void initState() {
    super.initState();
    _pendingPayload = widget.payload;

    _pages = [
      const HomeInfoPage(),
      ChatListPage(payload: _pendingPayload),
    ];

    if (_pendingPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _pendingPayload = null;
          _pages![1] = const ChatListPage();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.watch<ThemeColorProvider>().theme;

    return Scaffold(
      body: _pages?[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: color.colorShade3,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: color.colorShade1,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
