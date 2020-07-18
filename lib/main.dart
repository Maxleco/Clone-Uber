import 'package:flutter/material.dart';
import 'package:uber/views/Home.dart';
import 'package:uber/RouteGenerator.dart';

void main() {
  runApp(MyApp());
}

final ThemeData defaultTheme = ThemeData(
  primaryColor: Color(0xFF37474f),
  accentColor: Color(0xFF546e7a),
);

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber',
      debugShowCheckedModeBanner: false,
      theme: defaultTheme,
      home: Home(),
      initialRoute: "/",
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}