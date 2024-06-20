import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CentroData {
  final int codCentro;
  final String centro;
  final String mac;
  final dynamic corrente1;
  final dynamic temperatura;
  final dynamic peso;
  final String dataInsert;

  CentroData({
    required this.codCentro,
    required this.centro,
    required this.mac,
    required this.corrente1,
    required this.temperatura,
    required this.peso,
    required this.dataInsert,
  });

  factory CentroData.fromJson(Map<String, dynamic> json) {
    return CentroData(
      codCentro: json['cod_centro'],
      centro: json['centro'],
      mac: json['mac'],
      corrente1: json['corrente1'],
      temperatura: json['temperatura'],
      peso: json['peso'],
      dataInsert: json['data_insert'],
    );
  }
}

class TemperaturaFetcher {
  var cod_centro;
  final String apiUrl;
  TemperaturaFetcher(this.apiUrl, this.cod_centro);

  Stream<List<CentroData>> fetchData() async* {
    while (true) {
      await Future.delayed(Duration(seconds: 5)); // Espera 10 segundos
      var data = {'codigo': cod_centro};
      http.Response response =
      await http.post(Uri.parse(apiUrl), body: json.encode(data));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<CentroData> data = jsonData
            .map((json) => CentroData.fromJson(json))
            .toList();

        yield data;
      }
    }
  }
}

class TemperaturaWidget extends StatelessWidget {
  final TemperaturaFetcher dataFetcher;


  TemperaturaWidget({required this.dataFetcher});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CentroData>>(
      stream: dataFetcher.fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Erro: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('Nenhum dado disponível.');
        } else {
          final data = snapshot.data!;
          return Column(
            children: data.map((centro) {
              return Column(
                children: [
                  Row(
                    children: [
                      Padding(padding: EdgeInsets.all(5), child: Icon(Icons.thermostat, size: 60,),),
                      Container(
                        margin: EdgeInsets.only(top: 10, bottom: 10),
                        padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                        decoration: BoxDecoration(
                            color: Color(0xFF2A53A1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          "${centro.peso!} KG",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                    decoration: BoxDecoration(
                        color: Color(0xFF2A53A1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "${centro.temperatura!}ºC",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.bold),
                    ),
                  ),Container(
                    padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                    decoration: BoxDecoration(
                        color: Color(0xFF2A53A1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "${centro.temperatura!}ºC",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }).toList(),

          );
        }
      },
    );
  }
}

class TemperaturaWidget2 extends StatelessWidget {
  final TemperaturaFetcher dataFetcher;
  final temperatura;


  TemperaturaWidget2({required this.dataFetcher, required this.temperatura});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CentroData>>(
      stream: dataFetcher.fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Erro: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('Nenhum dado disponível.');
        } else {
          final data = snapshot.data!;
          return Column(
            children: data.map((centro) {
              return Column(
                children: [
                  Row(
                    children: [
                      Padding(padding: EdgeInsets.all(5), child: Icon(Icons.expand, size: 60,),),
                      Container(
                        margin: EdgeInsets.only(top: 10, bottom: 10),
                        padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                        decoration: BoxDecoration(
                            color: Color(0xFF2A53A1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          "${centro.peso!} KG",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Padding(padding: EdgeInsets.all(5), child: Icon(Icons.thermostat, size: 60,),),
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                            decoration: BoxDecoration(
                                color: Color(0xFF2A53A1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              "${centro.temperatura!}ºC",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(5), child: Icon(Icons.keyboard_arrow_down_rounded, size: 60,),),
                          Container(
                            padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                            decoration: BoxDecoration(
                                color: Color(0xFF2A53A1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              "${temperatura}ºC",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              );
            }).toList(),

          );
        }
      },
    );
  }
}