import 'package:chat/components/set_preference_sheet.dart';
import 'package:chat/services/chat_firestore.dart';
import 'package:chat/services/socket.dart';
import 'package:chat/services/user_firestore.dart';
import 'package:chat/userPref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ThemeColors {
  final Color colorShade1;
  final Color colorShade2;
  final Color colorShade3;
  final Color colorShade4;

  const ThemeColors({
    required this.colorShade1,
    required this.colorShade2,
    required this.colorShade3,
    required this.colorShade4,
  });
}

const allThemeColors = [
  ThemeColors(
    colorShade1: Color(0xFF003285),
    colorShade2: Color(0xFF578FCA),
    colorShade3: Color(0xFFA1E3F9),
    colorShade4: Color(0xFFD1F8EF),
  ),
  ThemeColors(
    colorShade1: Color(0xFF3E5F44),
    colorShade2: Color(0xFF5E936C),
    colorShade3: Color(0xFF93DA97),
    colorShade4: Color(0xFFE8FFD7),
  ),
  ThemeColors(
    colorShade1: Color(0xFFB53791),
    colorShade2: Color(0xFFC062AF),
    colorShade3: Color(0xFFDB8DD0),
    colorShade4: Color(0xFFFEC5F6),
  ),
  ThemeColors(
    colorShade1: Color(0xFF7B4019),
    colorShade2: Color(0xFFFF7D29),
    colorShade3: Color(0xFFFFBF78),
    colorShade4: Color(0xFFFFEEA9),
  ),
  ThemeColors(
    colorShade1: Color(0xFF2D336B),
    colorShade2: Color(0xFF7886C7),
    colorShade3: Color(0xFFA9B5DF),
    colorShade4: Color(0xFFFFF2F2),
  ),
  ThemeColors(
    colorShade1: Color(0xFF222831),
    colorShade2: Color(0xFF393E46),
    colorShade3: Color(0xFF948979),
    colorShade4: Color(0xFFDFD0B8),
  ),
];

class ThemeColorProvider extends ChangeNotifier {
  ThemeColors _color = allThemeColors[0];

  ThemeColors get theme => _color;

  ThemeColorProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final index = await UserPrefs.getThemeColor();
    _color = allThemeColors[index];
    notifyListeners();
  }

  Future<void> setThemeByIndex(int index) async {
    _color = allThemeColors[index];
    await UserPrefs.saveThemeColor(index);
    notifyListeners();
  }
}

class Pair<A, B> {
  final A first;
  final B second;

  Pair(this.first, this.second);
}

String formatTime(DateTime time) {
  final now = DateTime.now();
  if (now.difference(time).inDays == 0) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  } else {
    return "${time.month}/${time.day}";
  }
}

// For set user UI preference in home info and chat list page
Future<void> showPreferencesSheet({
  required BuildContext context,
  required double currentFontSize,
  required void Function(double newFontSize) onFontSizeChanged,
}) async {
  const double smallSize = -2;
  const double largeSize = 4;

  FontSizeOption currentSetting = switch (currentFontSize) {
    smallSize => FontSizeOption.small,
    largeSize => FontSizeOption.large,
    _ => FontSizeOption.medium,
  };

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SetPreferenceSheet(
      initialFontSize: currentSetting,
      onSave: (selected) async {
        double newSize;
        switch (selected) {
          case FontSizeOption.small:
            newSize = smallSize;
            break;
          case FontSizeOption.medium:
            newSize = 0;
            break;
          case FontSizeOption.large:
            newSize = largeSize;
            break;
        }
        await UserPrefs.saveFontSize(newSize);
        onFontSizeChanged(newSize);
      },
    ),
  );
}

// For notify app state change in each page
class AppStateNotifier extends ValueNotifier<bool> {
  AppStateNotifier() : super(false);

  void refresh() {
    value = !value; // toggle to notify listeners
  }
}

final appStateNotifier = AppStateNotifier();

final FirebaseAuth auth = FirebaseAuth.instance;
final UserFirestoreService userFirestoreService = UserFirestoreService();
final ChatFirestoreService chatFirestoreService = ChatFirestoreService();
String get currentUid => auth.currentUser!.uid;
final socketService = SocketService();
