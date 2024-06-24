import 'package:flutter/material.dart';
import 'package:producao_app/screens/SelectCentro.dart';
import 'screens/Login.dart';
import 'screens/Usuario.dart';
import 'screens/ConfConn.dart';

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
