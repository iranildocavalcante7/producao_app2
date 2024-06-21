import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:http/http.dart' as http;
import '../Data/Dado.dart';
import 'DetalhesOp.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:xml/xml.dart' as xml;
import 'package:convert/convert.dart';

class OrdemProducao {
  final dynamic codOrdem;
  final dynamic codProduto;
  final dynamic descProduto;
  final dynamic codCentro;
  final dynamic descCentro;
  final dynamic processo;
  final dynamic lote;
  final dynamic localOrigem;
  final dynamic localDestino;
  final dynamic dhInicio;
  final dynamic dhFinal;
  final dynamic dataSeq;
  final dynamic qtdAProduz;
  final dynamic qtdProduz;
  final dynamic statusOP;
  final dynamic CODMTP;
  final dynamic MOTPARADA;
  final dynamic IDIATV;
  final dynamic IDPROC;
  final dynamic IDEFX;

  OrdemProducao(
      {required this.codOrdem,
      required this.codProduto,
      required this.descProduto,
      required this.codCentro,
      required this.descCentro,
      required this.processo,
      required this.lote,
      required this.localOrigem,
      required this.localDestino,
      required this.dhInicio,
      required this.dhFinal,
      required this.dataSeq,
      required this.qtdAProduz,
      required this.qtdProduz,
      required this.statusOP,
      required this.CODMTP,
      required this.MOTPARADA,
      required this.IDIATV,
      required this.IDPROC,
      required this.IDEFX});
}

class SelectOrdens extends StatefulWidget {
  var operador;
  var centro;
  var cod_centro;
  var nome;
  final String ip;

  SelectOrdens(this.operador, this.centro, this.cod_centro, this.nome, this.ip,
      {Key? key})
      : super(key: key);

  @override
  _SelectOrdensState createState() => _SelectOrdensState();
}

class _SelectOrdensState extends State<SelectOrdens> {
  List<OrdemProducao> ordensProducao = [];
  List<OrdemProducao> ordensProducaoCentro = [];

  Future<void> fetchOrdensProducaoCentro() async {
    /*
      Procura dentro da lista de Ordens de Produção a OP 
      que tem o centro de resultado selecionado "widget.cod_centro"
    */
    List<OrdemProducao> ordens = [];
    for (var i = 0; i < ordensProducao.length; i++) {
      if (ordensProducao[i].codCentro == widget.cod_centro) {
        ordens.add(OrdemProducao(
            codOrdem: ordensProducao[i].codOrdem,
            codProduto: ordensProducao[i].codProduto,
            descProduto: ordensProducao[i].descProduto,
            codCentro: ordensProducao[i].codOrdem,
            descCentro: ordensProducao[i].descCentro,
            processo: ordensProducao[i].processo,
            lote: ordensProducao[i].lote,
            localOrigem: ordensProducao[i].localOrigem,
            localDestino: ordensProducao[i].localDestino,
            dhInicio: ordensProducao[i].dhInicio,
            dhFinal: ordensProducao[i].dhFinal,
            dataSeq: ordensProducao[i].dataSeq,
            qtdAProduz: ordensProducao[i].qtdAProduz,
            qtdProduz: ordensProducao[i].qtdProduz,
            statusOP: ordensProducao[i].statusOP,
            CODMTP: ordensProducao[i].CODMTP,
            MOTPARADA: ordensProducao[i].MOTPARADA,
            IDIATV: ordensProducao[i].IDIATV,
            IDPROC: ordensProducao[i].IDPROC,
            IDEFX: ordensProducao[i].IDEFX));
      }
    }
    setState(() {
      ordensProducaoCentro = ordens;
    });
  }

  Future<void> fetchOrdensProducao() async {
    String vsql = '''
              SELECT codOrdem,codProduto,descProduto,codCentro,descCentro,processo,lote
                , localOrigem , localDestino,dhInicio,dhFinal,dataSeq,qtd_AProduz,qtd_Produz,
                statusOP,CODMTP,MOTPARADA,IDIATV,IDPROC,IDEFX 
                FROM sankhya.AD_VAPP_OPS_SMART
            ''';

    var response = await ApiService.DbExplorer(vsql);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      List<dynamic> rows = json['responseBody']['rows'];
      List<OrdemProducao> ordens = [];
      for (var row in rows) {
        ordens.add(OrdemProducao(
            codOrdem: row[0],
            codProduto: row[1],
            descProduto: row[2],
            codCentro: row[3],
            descCentro: row[4],
            processo: row[5],
            lote: row[6],
            localOrigem: row[7],
            localDestino: row[8],
            dhInicio: row[9],
            dhFinal: row[10],
            dataSeq: row[11],
            qtdAProduz: row[12].toDouble(),
            qtdProduz: row[13].toDouble(),
            statusOP: row[14],
            CODMTP: row[15],
            MOTPARADA: row[16],
            IDIATV: row[17],
            IDPROC: row[18],
            IDEFX: row[19]));
      }

      setState(() {
        ordensProducao = ordens;
      });

      fetchOrdensProducaoCentro();
    } else {
      throw Exception('Failed to load data');
    }
    await ApiService.closeSession();
  }

  Future<void> realocaCentro(String idiatv, String idiproc) async {
    String _servidor = '';
    String jsessionid = await ApiService.openSession();
    jsessionid = jsessionid.split('=')[1];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mgeprod/service.sbr?application=OperacaoProducao&mgeSession=$jsessionid&serviceName=OperacaoProducaoSP.realocarCentroDeTrabalhoPorCategoria';

    String Body = '''
                    <serviceRequest serviceName="OperacaoProducaoSP.realocarCentroDeTrabalhoPorCategoria">
                        <requestBody>
                            <params idiproc="$idiproc" idiatv="$idiatv" codwcp="${widget.cod_centro}" isWorkCenterPadrao="true"/>
                        </requestBody>
                    </serviceRequest>
                  ''';

    final headers = {'Content-Type': 'application/xml', 'Cookie': jsessionid};

    final response = await http.post(
      Uri.parse(_url),
      headers: headers,
      body: utf8.encode(Body),
    );

    try {
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final serviceResponse =
            document.findAllElements('serviceResponse').first;
        final status = serviceResponse.getAttribute('status');

        if (status == "1") {
          Navigator.of(context).pop();
          var route = MaterialPageRoute(
              builder: (BuildContext context) => SelectOrdens(widget.operador,
                  widget.centro, widget.cod_centro, widget.nome, widget.ip));
          Navigator.of(context).push(route);
        } else {
          final statusMessage = document.findAllElements('statusMessage').first;
          final cdataContent = statusMessage.text.trim();
          // limpa a string para BASE64
          final cleanedContent =
              cdataContent.replaceAll('\n', '').replaceAll(' ', '');
          // Decodifique a string BASE64
          final decodedBytes = base64Decode(cleanedContent);
          final decodedString = String.fromCharCodes(decodedBytes);

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 0.0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Resposta Sankhya (Iniciar Atividade)',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Text('Status: $status'),
                      Text('Mensagem: $decodedString'),
                      const SizedBox(height: 12.0),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } else {
        if (kDebugMode) {}
      }
    } catch (e) {
      if (kDebugMode) {}
    }

    await ApiService.closeSession();
  }

  Future<void> _confirmacao(String idiatv, String idiproc) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Deseja transferir a OP para o reator?"),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "SIM",
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                realocaCentro(idiatv, idiproc);
              },
            ),
            TextButton(
              child: const Text(
                "NÃO",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    //FlutterRingtonePlayer.stop();
    fetchOrdensProducao();
  }

  void dispose() {
    super.dispose();
  }

  @override
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  " ${widget.cod_centro} - ${widget.centro}",
                  style: TextStyle(
                      color: Color(0xFF2A53A1),
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 20,
                ),
                GestureDetector(
                  child: Icon(
                    Icons.exit_to_app,
                    color: Colors.black,
                  ),
                  onTap: () {
                    var route = MaterialPageRoute(
                        builder: (BuildContext context) => LoginScreen());
                    Navigator.of(context).pushReplacement(route);
                  },
                )
              ],
            )),
          )
        ],
      ),
      body: Container(
          decoration: BoxDecoration(color: Color(0xffEDEDED)),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      width: 300,
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 30, top: 30),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Color(0xFF2A53A1), width: 3)),
                      child: Text(
                        "Ordem de Produção",
                        style: TextStyle(
                            color: Color(0xFF2A53A1),
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ),
                    Container(
                      width: 700,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.all(20),
                            margin: EdgeInsets.only(bottom: 10),
                            child: Text(
                              "Ordens disponiveis para o reator",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              physics: ScrollPhysics(),
                              itemCount: ordensProducaoCentro.length,
                              itemBuilder: (BuildContext context, int index) {
                                OrdemProducao ordem =
                                    ordensProducaoCentro[index];
                                return GestureDetector(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 10),
                                        padding: EdgeInsets.only(
                                            left: 20, right: 20),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: (ordem.statusOP ==
                                                    "Em Andamento")
                                                ? Colors.redAccent
                                                : Colors.green),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.only(
                                                  top: 5, bottom: 5),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "OP: ${ordem.codOrdem}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Cod. Produto: ${ordem.codProduto}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Produto: ${ordem.descProduto}"
                                                        .substring(0, 40),
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Status: ${ordem.statusOP}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Parada: ${ordem.MOTPARADA}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_right,
                                              size: 28,
                                              color: Colors.white,
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    var route = MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            DetalhesOp(
                                                ordem.codOrdem,
                                                widget.operador,
                                                widget.cod_centro,
                                                widget.nome,
                                                widget.ip));
                                    Navigator.of(context).push(route);
                                  },
                                );
                              },
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 10, top: 30),
                            decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "Selecione a ordem para transferir",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              physics: ScrollPhysics(),
                              itemCount: ordensProducao.length,
                              itemBuilder: (BuildContext context, int index) {
                                OrdemProducao ordem = ordensProducao[index];
                                return GestureDetector(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 10),
                                        padding: EdgeInsets.only(
                                            left: 20, right: 20),
                                        decoration: BoxDecoration(
                                            color: (ordem.statusOP ==
                                                    "Em Andamento")
                                                ? Colors.redAccent
                                                : Colors.green),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.only(
                                                  top: 5, bottom: 5),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "OP: ${ordem.codOrdem}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Cod. Produto: ${ordem.codProduto}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Produto: ${ordem.descProduto}"
                                                        .substring(0, 40),
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Reator: ${ordem.codCentro} - ${ordem.descCentro}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Status: ${ordem.statusOP}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Parada: ${ordem.MOTPARADA}",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_right,
                                              size: 28,
                                              color: Colors.white,
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    _confirmacao(ordem.IDIATV.toString(),
                                        ordem.codOrdem.toString());
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
