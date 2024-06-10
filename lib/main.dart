import 'package:flutter/material.dart';
import 'package:producao_app/screens/centrotrab_screen.dart';
import 'screens/login_screen.dart';
import 'screens/usuario_screen.dart';
import 'screens/confconn_screen.dart';


void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter CRUD App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/usuarios': (context) => UsuarioScreen(),
        '/confconn': (context) => ConfconnScreen(),
      },
    );
  }
}
