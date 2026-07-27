import 'package:flutter/material.dart';
import '../widgets/buttons.dart' show MenuButton;

class MenuScreen extends StatelessWidget {
  final List<(String, VoidCallback)> menuItems;
  const MenuScreen({required this.menuItems, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: GridView.count(
              padding: EdgeInsets.all(12),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              children: <Widget>[
                for (var (text, onPressed) in menuItems)
                  MenuButton(text: text, onPressed: onPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
