import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:monta_triangle_selector/triangle_selector.dart';
import 'package:monta_triangle_selector/triangle_selector_value.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: _TriangleSelector(),
              ),
            ),
            Positioned(
              right: 15,
              bottom: -25,
              child: FlutterLogo(
                size: 110,
                style: FlutterLogoStyle.horizontal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TriangleSelector extends StatefulWidget {
  const _TriangleSelector();

  @override
  State<_TriangleSelector> createState() => __TriangleSelectorState();
}

class __TriangleSelectorState extends State<_TriangleSelector> {
  var _value = const TriangleSelectorValue(
    aValue: 1,
    bValue: 0,
    cValue: 0,
  );

  int _convertToPercent(double value) {
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Label(
            label: 'Save money',
            percentage: _convertToPercent(_value.aValue),
            icon: Symbols.attach_money,
            iconColor: const Color(0xFF393746),
          ),
          TriangleSelector(
            value: _value,
            onChanged: (value) {
              setState(() {
                _value = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: _Label(
                  label: 'Low CO2',
                  percentage: _convertToPercent(_value.bValue),
                  icon: Symbols.eco,
                  iconColor: const Color(0xFF11A581),
                ),
              ),
              const SizedBox(width: 20),
              Flexible(
                child: _Label(
                  label: 'Renewable',
                  percentage: _convertToPercent(_value.cValue),
                  icon: Symbols.autorenew,
                  iconColor: const Color(0xFF11A581),
                  textAlign: TextAlign.end,
                  reverseOrder: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.percentage,
    required this.icon,
    required this.iconColor,
    this.textAlign = TextAlign.start,
    this.reverseOrder = false,
  });

  final String label;

  final TextAlign textAlign;

  final int percentage;

  final IconData icon;

  final Color iconColor;

  final bool reverseOrder;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      color: iconColor,
      size: 24,
      weight: 300,
      grade: 0,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!reverseOrder) iconWidget,
        Flexible(
          child: Text(
            '$label ($percentage%)',
            textAlign: textAlign,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Color(0xFF393746),
              fontSize: 15,
              height: 0,
              letterSpacing: 0.225,
            ),
          ),
        ),
        if (reverseOrder) iconWidget,
      ],
    );
  }
}
