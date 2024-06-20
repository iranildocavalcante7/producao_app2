import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Fluxo extends StatefulWidget {
  const Fluxo({Key? key}) : super(key: key);

  @override
  _FluxoState createState() => _FluxoState();
}

class _FluxoState extends State<Fluxo> {

  List<dynamic> _fluxo = [];

  Future<dynamic> fetchOrdens() async {
    String apiFunc = 'http://10.0.1.135/api/GetFluxoInit.php';
    var data = {'codigo': ""};
    http.Response response =
    await http.post(Uri.parse(apiFunc), body: json.encode(data));
    setState(() {
      _fluxo = json.decode(response.body);
    });
  }

  @override
  void initState() {
    fetchOrdens();
    super.initState();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.all(60),
          child: Image.asset(
            "assets/logoalynebranco.png",
            height: 50,
          ),
        ),
        backgroundColor: Color(0xFF2A53A1),
        centerTitle: true,
        elevation: 15,
        actions: [
          Container(
            padding: EdgeInsets.only(left: 170, right: 170),
            decoration: BoxDecoration(color: Colors.white),
            child: Center(
                child: Row(
                  children: [
                    Text(
                      "Fluxo",
                      style: TextStyle(
                          color: Color(0xFF2A53A1),
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                )),
          )
        ],
      ),
      body: Container(
        child: Center(
          child: Column(
            children: [
              Text("Fluxo"),
              GestureDetector(
                onTap: (){
                  print(_fluxo[0]["etapa"]);
                  Navigator.of(context).pushNamed("${_fluxo[0]["etapa"]}");
                },
                child: Text("Iniciar"),
              )
            ],
          )
        ),
      ),
    );
  }
}
