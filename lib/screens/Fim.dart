import 'package:flutter/material.dart';
//import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'centrotrab_screen.dart';

class FimFluxo extends StatefulWidget {
  var produto;
  var etapa;
  var operador;
  var cod_ordem;
  var cod_produto;
  var cod_centro;
  var nome;
  var idiatv;
  FimFluxo(this.produto, this.etapa, this.operador, this.cod_ordem,
      this.cod_produto, this.cod_centro, this.nome, this.idiatv);

  @override
  _FimFluxoState createState() => _FimFluxoState();
}

class _FimFluxoState extends State<FimFluxo> {
  List<dynamic> _ordem = [];
  String _cod_ordem = '';
  dynamic _tim = DateTime.now();
  dynamic _timEsperado = DateTime.now();
  String _cod_produto = '';
  String _desc_produto = '';
  String _processo = '';
  String _lote = '';
  String _local_origem = '';
  String _local_destino = '';
  String _data_emissao = '';
  String _data_inclusao = '';
  String _hora_inclusao = '';

  Future<dynamic> fetchData() async {
    String apiFunc = 'http://10.0.1.135/api/GetOrdensDetail.php';
    var data = {'id': '1'};
    http.Response response =
        await http.post(Uri.parse(apiFunc), body: json.encode(data));
    setState(() {
      _ordem = json.decode(response.body);
      _cod_ordem = _ordem[0]["cod_ordem"].toString();
      _cod_produto = _ordem[0]["cod_produto"].toString();
      _desc_produto = _ordem[0]["desc_produto"].toString();
      _processo = _ordem[0]["processo"].toString();
      _lote = _ordem[0]["lote"].toString();
      _local_origem = _ordem[0]["local_origem"].toString();
      _local_destino = _ordem[0]["local_destino"].toString();
      _data_emissao = _ordem[0]["data_emissao"].toString();
      _data_inclusao = _ordem[0]["data_inclusao"].toString();
      _hora_inclusao = _ordem[0]["hora_inclusao"].toString();
    });
  }

  List<dynamic> _fluxo = [];
  List<dynamic> _timop = [];

  Future<dynamic> fetchFluxo() async {
    String apiFunc = 'http://10.0.1.135/api/GetFluxoInit.php';
    var data = {'codigo': ""};
    http.Response response =
        await http.post(Uri.parse(apiFunc), body: json.encode(data));
    setState(() {
      _fluxo = json.decode(response.body);
    });
  }

  Future<dynamic> fetchTim() async {
    String apiFunc = 'http://10.0.1.135/api/GetTimOp.php';
    var data = {'codigo': "${widget.cod_ordem}"};
    http.Response response =
        await http.post(Uri.parse(apiFunc), body: json.encode(data));
    setState(() {
      _timop = json.decode(response.body);
      _tim = _timop[0]['tempo_decorrido'];
      _timEsperado = _timop[0]['tempo_esperado'];
    });
    print(_timop);
  }

  String formatarDuracao(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String horas = twoDigits(duration.inHours);
    String minutos = twoDigits(duration.inMinutes.remainder(60));
    String segundos = twoDigits(duration.inSeconds.remainder(60));

    return "$horas:$minutos:$segundos";
  }

  String _codOrdem = '';
  String _codProduto = '';
  String _descProduto = '';
  String _codCentro = '';
  String _descCentro = '';
  String _localOrigem = '';
  String _localDestino = '';
  String _DHINICIO = '';
  String _DHFINAL = '';
  String _DATASEQ = '';
  double _QTD_APRODUZ = 0.0;
  double _QTD_PRODUZ = 0.0;
  String _STATUSOP = '';
  String _IDIATV = '';
  String _IDPROC = '';
  String _IDEFX = '';
  List<dynamic> rowsData = [];
  Future<void> fetchData2() async {
    final response = await http.get(Uri.parse(
        'http://10.0.1.135:5000/ordem_producao_detail?codordem=${widget.cod_ordem}'));

    if (response.statusCode == 200) {
      ;
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsData = rows;
        _codOrdem = rowsData[0][0].toString();
        _codProduto = rowsData[0][1].toString();
        _descProduto = rowsData[0][2].toString();
        _codCentro = rowsData[0][3].toString();
        _descCentro = rowsData[0][4].toString();
        _processo = rowsData[0][5].toString();
        _lote = rowsData[0][6].toString();
        _localOrigem = rowsData[0][7].toString();
        _localDestino = rowsData[0][8].toString();
        _DHINICIO = rowsData[0][9].toString();
        _DHFINAL = rowsData[0][10].toString();
        _DATASEQ = rowsData[0][11].toString();
        _QTD_APRODUZ = rowsData[0][12];
        _QTD_PRODUZ = rowsData[0][13];
        _STATUSOP = rowsData[0][14].toString();
        _IDIATV = rowsData[0][15].toString();
        _IDPROC = rowsData[0][16].toString();
        _IDEFX = rowsData[0][17].toString();
      });
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }
  }

  Future<void> finalizarOP(GlobalKey<ScaffoldState> _scaffoldKey) async {
    final String url =
        'http://10.0.1.135:5000/post_finalizarop?idiatv=${_IDIATV}&idefx=${_IDEFX}&idiproc=${_cod_produto}&idproc=${_IDPROC}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String status = data['status'];
        String statusMessage = data['statusMessage'];
        String transactionId = data['transactionId'];
        if (status == "1") {
          /*
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Centro(widget.operador, widget.nome)));
                  */
          _scaffoldKey.currentContext;
        } else {
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
                      Text(
                        'Resposta Sankhya (Finalizar Atividade)',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.0),
                      Text('Status: $status'),
                      Text('Mensagem: $statusMessage'),
                      SizedBox(height: 12.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          //sendData();
                        },
                        child: Text('Fechar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } else {
        print('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro durante a requisição: $e');
    }
  }

  bool _isLoading = false;
  Future<void> confirmarApontamento() async {
    final String url =
        'http://10.0.1.135:5000/post_confirmarapontamento?nuapo=${nuapo}&idiatv=${widget.idiatv}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String status = data['status'];
        String statusMessage = data['statusMessage'];

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
                    Text(
                      'Resposta Sankhya (Confirmar Apontamento)',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text('Status: $status'),
                    Text('Mensagem: $statusMessage'),
                    SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Ao fechar o diálogo, encerra a indicação de progresso
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: Text('Fechar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        print('Erro na requisição: ${response.statusCode}');
        // Em caso de erro, encerra a indicação de progresso
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro durante a requisição: $e');
      // Em caso de erro, encerra a indicação de progresso
      setState(() {
        _isLoading = false;
      });
    }
  }

  TextEditingController _textController = TextEditingController();
  void qntApontada() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Controller para armazenar o valor digitado no TextFormField
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
                // TextFormField para inserção de valores numéricos
                TextFormField(
                  controller: _textController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Digite a quantidade produzida',
                  ),
                ),
                SizedBox(
                    height: 16.0), // Espaço entre o TextFormField e o botão

                ElevatedButton(
                  onPressed: () {
                    // Você pode acessar o valor digitado usando _textController.text
                    Navigator.of(context).pop();
                    salvarApontamento();
                  },
                  child: Text('Salvar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _NUAPO = '';
  Future<void> criarApontamento() async {
    final String url =
        'http://10.0.1.135:5000/post_apontar?idiatv=${widget.idiatv}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String status = data['status'];
        String statusMessage = data['statusMessage'];
        String NUAPO = data['NUAPO'];
        String LISTAPENDENTES = data['LISTAPENDENTES'];
        setState(() {
          _NUAPO = data['NUAPO'];
        });
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
                    Text(
                      'Resposta Sankhya (Apontar Atividade)',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text('Status: $status'),
                    Text('Mensagem: $statusMessage'),
                    Text('NUAPO: $NUAPO'),
                    Text('LISTAPENDENTES: $LISTAPENDENTES'),
                    SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: Text('Fechar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        print('Erro na requisição: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro durante a requisição: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> liberarCentro() async {
    final String url =
        'http://10.0.1.135:5000/post_liberarcentro?idiatv=${widget.idiatv}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String status = data['status'];
        String statusMessage = data['statusMessage'];
        if (status == "1") {
        } else {
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
                      Text(
                        'Resposta Sankhya (Finalizar Atividade)',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.0),
                      Text('Status: $status'),
                      Text('Mensagem: $statusMessage'),
                      SizedBox(height: 12.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          //sendData();
                        },
                        child: Text('Fechar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> rowsOP = [];
  Future<void> fetchOP() async {
    final response = await http.get(Uri.parse(
        'http://10.0.1.135:5000/ordem_producao_detail?codordem=${widget.cod_ordem}'));

    if (response.statusCode == 200) {
      ;
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsOP = rows;
        _QTD_APRODUZ = rowsOP[0][12];
        _QTD_PRODUZ = rowsOP[0][13];
      });
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }
  }

  Future<void> salvarApontamento() async {
    final String url =
        'http://10.0.1.135:5000/post_salvarapontamento?qnt=${_textController.text}&nuapo=${nuapo}&seqapa=${seqapa}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String status = data['status'];
        String statusMessage = data['statusMessage'];
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
                    Text(
                      'Resposta Sankhya (Salvar Apontamento)',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text('Status: $status'),
                    Text('Mensagem: $statusMessage'),
                    SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: Text('Fechar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        print('Erro na requisição: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro durante a requisição: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  dynamic nuapo;
  dynamic seqapa;
  Future<void> fetchApontamentos() async {
    final response = await http.get(Uri.parse(
        'http://10.0.1.135:5000/apontamentos?idiatv=${widget.idiatv}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsData = rows;
      });
      if (rowsData.isNotEmpty) {
        nuapo = rowsData[0][0];
        seqapa = rowsData[0][1];
      } else {}
    } else {
      throw Exception('Falha ao carregar os dados da API de apontamentos');
    }
  }

  @override
  void initState() {
    //FlutterRingtonePlayer.stop();
    fetchData2();
    fetchFluxo();
    fetchTim();
    Timer.periodic(Duration(seconds: 1), (timer) {
      fetchOP();
      fetchApontamentos();
    });
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            automaticallyImplyLeading: false,
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
            actions: [],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(left: 50, right: 50),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(
                              top: 20, bottom: 50, left: 30, right: 30),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Painel Informativo",
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2A53A1)),
                                      ),
                                      Text(
                                        "ORDEM DE PRODUÇÃO: ${widget.cod_ordem}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Color(0xFF2A53A1),
                                            width: 3)),
                                    child: Text(
                                      "${widget.cod_produto} - ${widget.produto}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.only(top: 30),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      padding: EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "TEMPO TOTAL DA OPERAÇÃO",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "${_tim}",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      padding: EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "TEMPO ESPERADO DA OPERAÇÃO",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "${_timEsperado}",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      padding: EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "PERFORMANCE DA OPERAÇÃO",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "--%",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "PROCESSO",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_processo}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "LOTE",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_lote}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "DATA | EMISSÃO",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_DHINICIO}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ORDEM DE PRODUÇÃO",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_codOrdem}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "LOCAL DE ORIGEM",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_localOrigem}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "DATA | INCLUSÃO",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_DHINICIO}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "OPERADOR",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${widget.operador}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "LOCAL DE DESTINO",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_localDestino}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(right: 20, left: 20),
                                width: 300,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "HORA | INCLUSÃO",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_hora_inclusao}",
                                      style: TextStyle(
                                          color: Color(0xFF2A53A1),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(left: 30, right: 30),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color(0xFF2A53A1), width: 2),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(left: 5, right: 10),
                                    child: Text(
                                      "A Produzir: ${_QTD_APRODUZ - _QTD_PRODUZ}",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 10, right: 5),
                                    child: Text(
                                      "Produzido: ${_QTD_PRODUZ}",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      criarApontamento();
                                    },
                                    child: Container(
                                      height: 60,
                                      width: 150,
                                      padding: EdgeInsets.all(5),
                                      margin:
                                          EdgeInsets.only(left: 5, right: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Criar Apontamento",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                      onTap: () {
                                        qntApontada();
                                      },
                                      child: Container(
                                        height: 60,
                                        width: 150,
                                        padding: EdgeInsets.all(5),
                                        margin:
                                            EdgeInsets.only(left: 5, right: 5),
                                        decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(
                                          "Alterar Qtd. apontamento",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22),
                                        ),
                                      )),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      confirmarApontamento();
                                      fetchOP();
                                    },
                                    child: Container(
                                      height: 60,
                                      width: 150,
                                      padding: EdgeInsets.all(5),
                                      margin:
                                          EdgeInsets.only(left: 5, right: 5),
                                      decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text(
                                        "Confirmar Apontamento",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      liberarCentro();
                                    },
                                    child: Container(
                                      height: 60,
                                      width: 150,
                                      padding: EdgeInsets.all(5),
                                      margin:
                                          EdgeInsets.only(left: 5, right: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text("Liberar Centro",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22),
                                          textAlign: TextAlign.center),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        GestureDetector(
                          child: Container(
                              margin: EdgeInsets.only(top: 10),
                              height: 55,
                              width: 280,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Color(0xFF3B9955),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "FINALIZAR OPERAÇÃO",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  )
                                ],
                              )),
                          onTap: () {
                            finalizarOP(_scaffoldKey);
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
              _isLoading
                  ? Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Container(),
            ],
          )),
    );
  }
}
