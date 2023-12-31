import 'package:flutter/material.dart';
import 'package:navigation/layout/main_layout.dart';
import 'package:navigation/screen/route_two_screen.dart';

class RouteOneScreen extends StatelessWidget {
  final int? number;

  const RouteOneScreen({
    this.number,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Route One',
      children: [
        Text(
          'arguments : ${number.toString()}',
          textAlign: TextAlign.center,
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Can Pop'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          child: const Text('Maybe Pop'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(456);
          },
          child: const Text('Pop'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RouteTwoScreen(),
                settings: const RouteSettings(
                  arguments: 789,
                ),
              ),
            );
          },
          child: const Text('Push'),
        ),
      ],
    );
  }
}
