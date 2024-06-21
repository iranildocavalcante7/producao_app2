import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:producao_app/Components/CurrentTimes.dart';
import 'package:producao_app/Components/DiferenceTimes.dart';
import 'package:producao_app/Components/Temperatura.dart';
import 'package:producao_app/screens/Fim.dart';
//import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:producao_app/screens/centrotrab_screen.dart';
import '../Components/dropdown_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:xml/xml.dart' as xml;

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

class FluxoAlyne extends StatefulWidget {
  var produto;
  var etapa;
  var operador;
  var cod_produto;
  var cod_ordem;
  var cod_centro;
  var nome;
  var idiatv;
  var ip;

  FluxoAlyne(this.produto, this.etapa, this.operador, this.cod_produto,
      this.cod_ordem, this.cod_centro, this.nome, this.idiatv, this.ip);

  @override
  _FluxoAlyneState createState() => _FluxoAlyneState();
}

class _FluxoAlyneState extends State<FluxoAlyne> {
  late int _valor;
  List<dynamic> _fluxo = [];
  List<dynamic> _detalhe = [];
  String _tempo = '00:00:00';
  String _tempoEsperado = '10:00:00';
  String _instrucao = '';
  int _segundo = 999;
  Stopwatch _stopwatch = Stopwatch();
  String _tempoDecorrido = '00:00:00';
  int _status = 0;
  Color _corFundo = Color(0xffEDEDED);
  String _tempo_total = '';
  String _NUAPO = '';

  int priority = 1;
  List<List<dynamic>> etapas = [];
  int etapaIndex = 0;

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  bool isScanning = false;

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.resumeCamera();
    controller.scannedDataStream.listen((scanData) {
      Navigator.of(context).pop();
      sendDataQr("${scanData.code}");
      controller.dispose();
    });
  }

  void fetchEtapas() async {
    //final Uri apiUrl = Uri.parse(
    //  "http://${widget.ip}:5000/fluxo?codprod=${widget.cod_produto}");

    String vsql = '''
                SELECT PRO.CODPROD as codProduto, pre.descpre as etapa, PRE.SEQPRE as prioridade
                  , isnull(Convert(Time(0),pre.TEMPO,0),'00:00:00')  as tempoAgitacao
                  , isnull(PRE.TEMPERATURA,0) as temperatura 
                FROM AD_MODPRE PRE 
                JOIN TGFPRO PRO ON PRO.CODPROD = PRE.CODPROD  
                WHERE PRO.CODPROD = ${widget.cod_produto} 
                  AND PRE.SEQPRE = ${widget.etapa} 
                order by 1,3
            ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data["responseBody"] != null) {
        etapas = List<List<dynamic>>.from(data["responseBody"]["rows"]);

        if (etapas.isNotEmpty) {
          etapaIndex = 0;
        } else {
          etapas = [];
        }
      } else {
        etapas = [];
      }

      setState(() {});
    } else {
      etapas = [];
    }

    await ApiService.closeSession();
  }

  void nextEtapa() {
    if (etapas.isNotEmpty && etapaIndex < etapas.length - 1) {
      etapaIndex++;
    } else if (etapaIndex == etapas.length - 1) {
      showCompletionDialog();
    }
    setState(() {});
  }

  void nextEtapa2() {
    if (etapas.isNotEmpty && widget.etapa + 1 <= etapas.length) {
      var route = MaterialPageRoute(
          builder: (BuildContext context) => FluxoAlyne(
              '${widget.produto}',
              widget.etapa + 1,
              '${widget.operador}',
              '${widget.cod_produto}',
              '${widget.cod_ordem}',
              '${widget.cod_centro}',
              widget.nome,
              widget.idiatv,
              widget.ip));
      Navigator.of(context).push(route);
    } else {
      var route = MaterialPageRoute(
          builder: (BuildContext context) => FimFluxo(
              '${widget.produto}',
              '${widget.etapa}',
              '${widget.operador}',
              '${widget.cod_ordem}',
              '${widget.cod_produto}',
              '${widget.cod_centro}',
              widget.nome,
              widget.idiatv,
              widget.ip));
      Navigator.of(context).push(route);
    }
    setState(() {});
  }

  void showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Parabéns! Todas as etapas foram concluídas."),
          actions: <Widget>[
            TextButton(
              child: Text("Fechar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Stopwatch _stopwatchFluxo = Stopwatch();
  String _tempoDecorridoFluxo = '00:00:00';
  String _tempoFluxo = '00:00:00';

  void _startStopwatchFluxo() {
    _stopwatchFluxo.start();
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _tempoDecorridoFluxo = _formatDuration(_stopwatchFluxo.elapsed);
      });
    });
  }

  void stoper() {
    _stopwatchFluxo.stop();
  }

  void _startStopwatch() {
    _stopwatch.start();
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _tempoDecorrido = _formatDuration(_stopwatch.elapsed);
        if (_stopwatch.elapsed > Duration(seconds: _segundo)) {
          _corFundo = Colors.redAccent;
        }
        DateTime startDate = DateFormat("hh:mm:ss").parse(_tempo);
        DateTime endDate = DateFormat("hh:mm:ss").parse(_tempoDecorrido);
        Duration _dif = endDate.difference(startDate);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitHours = twoDigits(duration.inHours);
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _temperaturaHw = '';
  String _pesoHw = '';
  List<dynamic> _hardware = [];

  Future<dynamic> fetchHardware() async {
    String apiFunc = 'http://${widget.ip}/api/GetAuto.php';
    var data = {'codigo': widget.cod_centro};
    http.Response response =
        await http.post(Uri.parse(apiFunc), body: json.encode(data));
    setState(() {
      _hardware = json.decode(response.body);
      _pesoHw = _hardware[0]['peso'].toString();
      _temperaturaHw = _hardware[0]['temperatura'].toString();
    });
  }

  List<dynamic> _auto = [];
  dynamic _temperatura = '';
  dynamic _temperatura2 = '';

  Future<dynamic> fetchAuto() async {
    String apiFunc = 'http://${widget.ip}/api/GetAuto.php';
    var data = {'codigo': widget.cod_centro};
    http.Response response =
        await http.post(Uri.parse(apiFunc), body: json.encode(data));
    setState(() {
      _auto = json.decode(response.body);
      _temperatura = _auto[0]['temperatura'];
    });
  }

  Future<void> _confirmacao() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Deseja ir para a proxima etapa?"),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "SIM",
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                if (etapas.isNotEmpty && widget.etapa + 1 <= etapas.length) {
                  setState(() {
                    mudanca = 0;
                  });
                  //FlutterRingtonePlayer.stop();
                  var route = MaterialPageRoute(
                      builder: (BuildContext context) => FluxoAlyne(
                          '${widget.produto}',
                          widget.etapa + 1,
                          '${widget.operador}',
                          '${widget.cod_produto}',
                          '${widget.cod_ordem}',
                          '${widget.cod_centro}',
                          '${widget.nome}',
                          '${widget.idiatv}',
                          widget.ip));
                  Navigator.of(context).pushReplacement(route);
                } else {
                  //FlutterRingtonePlayer.stop();
                  var route = MaterialPageRoute(
                      builder: (BuildContext context) => FimFluxo(
                          '${widget.produto}',
                          '${widget.etapa}',
                          '${widget.operador}',
                          '${widget.cod_ordem}',
                          '${widget.cod_produto}',
                          '${widget.cod_centro}',
                          widget.nome,
                          '${widget.idiatv}',
                          widget.ip));
                  Navigator.of(context).push(route);
                }
                setState(() {});
                sendData();
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

  String tempoVariavel = "00:01:00";
  late DateTime inicio;

  bool error = false;
  bool sending = false;
  bool success = false;
  String msg = "";

  Future<void> sendData() async {
    var res = await http
        .post(Uri.parse("http://${widget.ip}/api/InsertMudEtapa.php"), body: {
      "cod_ordem": "${widget.cod_produto.toString()}",
      "cod_produto": "${widget.cod_ordem.toString()}",
      "etapa": "${widget.etapa}",
      "hora_mudanca": "${DateTime.now()}",
      "operador": "${widget.operador}",
      "temperatura": "${_temperaturaHw}",
      "tempo_cronometro": "${_tempoDecorrido}",
      "prioridade_etapa": "${widget.etapa.toString()}",
      "cod_centro": "${widget.cod_centro}",
      "tempo_esperado": "${_tempoEsperado}",
      "nome_operador": "${widget.nome}",
      "etapa_total": "${etapas.length}",
      "peso": "${_pesoHw}",
      "tempo_decorrido": "${_tempoDecorridoFluxo}"
    });

    if (res.statusCode == 200) {
      var data = json.decode(res.body);
      if (data["error"]) {
        final snackBar = SnackBar(
          content: const Text("Erro ao salvar dados. Vefifique conexão!"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          sending = false;
          error = true;
          msg = data["message"];
        });
      } else {
        final snackBar = SnackBar(
          content: const Text("Dados salvos com sucesso!"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          sending = false;
          success = true;
        });
      }
    } else {
      final snackBar = SnackBar(
        content: const Text("Erro ao salvar dados. Vefifique comexão!"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      setState(() {
        error = true;
        msg = "Error during sendign data.";
        sending = false;
      });
    }
  }

  Future<void> sendDataQr(String qr) async {
    var res = await http
        .post(Uri.parse("http://${widget.ip}/api/InsertQr.php"), body: {
      "cod_ordem": "${widget.cod_ordem}",
      "cod_produto": "${widget.cod_produto}",
      "cod_centro": "${widget.cod_centro}",
      "qrcode": "${qr}",
      "operador": "${widget.operador}",
      "tim": "${DateTime.now()}",
      "etapa": "${widget.etapa}"
    });

    if (res.statusCode == 200) {
      var data = json.decode(res.body);
      if (data["error"]) {
        final snackBar = SnackBar(
          content: const Text("Erro ao salvar dados."),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          sending = false;
          error = true;
          msg = data["message"];
        });
      } else {
        final snackBar = SnackBar(
          content: const Text("Dados salvos com sucesso!"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          sending = false;
          success = true;
        });
      }
    } else {
      final snackBar = SnackBar(
        content: const Text("Erro ao salvar dados. Vefifique comexão!"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      setState(() {
        error = true;
        msg = "Error during sendign data.";
        sending = false;
      });
    }
  }

  String _codProduto = '';
  String _etapa = '';
  int _prioridade = 999;
  List<dynamic> rowsData = [];
  String _tempoEsperadoData = '00:00:00';
  int mudanca = 1;
  final CurrentTimes _currentTimesStop = CurrentTimes();

  Future<void> fetchData2() async {
    //final response = await http.get(Uri.parse(
    //'http://${widget.ip}:5000/fluxo_detail?codseq=${widget.etapa}&codprod=${widget.cod_produto}'));

    String vsql = '''
              SELECT PRO.CODPROD as codProduto, pre.descpre as etapa, PRE.SEQPRE as prioridade
                  , isnull(Convert(Time(0),pre.TEMPO,0),'00:00:00')  as tempoAgitacao
                  ,  isnull(PRE.TEMPERATURA,0) as temperatura 
              FROM AD_MODPRE PRE 
              join TGFPRO PRO ON PRO.CODPROD = PRE.CODPROD  
              WHERE PRO.CODPROD = ${widget.cod_produto} 
                AND PRE.SEQPRE = ${widget.etapa} 
              order by 1,3  
            ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsData = rows;
        _codProduto = rowsData[0][0].toString();
        _etapa = rowsData[0][1].toString();
        _prioridade = rowsData[0][2];
        _tempoEsperado = rowsData[0][3];
        _temperatura2 = rowsData[0][4];
      });

      inicio = DateTime.now();
      inicio = DateTime.now();

      Duration duracaoVariavel = parseTempo(rowsData[0][3]);
      Timer.periodic(Duration(seconds: 1), (timer) {
        DateTime agora = DateTime.now();
        Duration diferenca = agora.difference(inicio);
        setState(() {
          _tempoEsperadoData = diferenca.toString();
        });
        if (mudanca == 1) {
          if (diferenca >= duracaoVariavel) {
            setState(() {
              _corFundo = Colors.redAccent;
            });
            //FlutterRingtonePlayer.playAlarm();
            timer.cancel();
          }
        }
      });
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }
    await ApiService.closeSession();
  }

  Duration parseTempo(String tempo) {
    List<String> partes = tempo.split(":");
    int horas = int.parse(partes[0]);
    int minutos = int.parse(partes[1]);
    int segundos = int.parse(partes[2]);

    return Duration(hours: horas, minutes: minutos, seconds: segundos);
  }

  Future<void> criarApontamento() async {
    //final String url =
    //'http://${widget.ip}:5000/post_apontar?idiatv=${widget.idiatv}';

    String _servidor = '';
    String jsessionid = await ApiService.openSession();
    jsessionid = jsessionid.split('=')[1];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mgeprod/service.sbr?serviceName=OperacaoProducaoSP.criarApontamento&application=OperacaoProducao&mgeSession=$jsessionid&resourceID=br.com.sankhya.producao.cad.OperacaoProducao';

    String Body = '''
                  <serviceRequest serviceName="OperacaoProducaoSP.criarApontamento">
                    <requestBody>
                      <params IDIATV="${widget.idiatv}" QTDAPONTADA="1"/>
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
        //final statusMessage = serviceResponse.getAttribute('statusMessage').tost;

        // Encontre o elemento apontamento
        var apontamentoElement = document.findAllElements('apontamento').first;

        // Extraia o valor do atributo NUAPO
        String NUAPO = apontamentoElement.getAttribute('NUAPO').toString();
        String LISTAPENDENTES =
            apontamentoElement.getAttribute('LISTAPENDENTES').toString();

        setState(() {
          //_NUAPO = data['NUAPO'];
          _NUAPO = apontamentoElement.getAttribute('NUAPO').toString();
        });

        String decodedString = "";
        if (NUAPO == "") {
          decodedString =
              "Apontamento esta pendente para confirmar. Produto.: $LISTAPENDENTES";
        } else {
          decodedString = "Apontamento criado com Sucesso!!! NuApo.: $NUAPO";
        }

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
                    Text('Mensagem: $decodedString'),
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }

    await ApiService.closeSession();
  }

  Future<void> liberarCentro() async {
    //final String url =
    //  'http://${widget.ip}:5000/post_liberarcentro?idiatv=${widget.idiatv}';

    String _servidor = '';
    String jsessionid = await ApiService.openSession();
    jsessionid = jsessionid.split('=')[1];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mgeprod/service.sbr?serviceName=OperacaoProducaoSP.liberarCentroDeTrabalho&counter=4040370301&application=OperacaoProducao&mgeSession=$jsessionid&resourceID=br.com.sankhya.producao.cad.OperacaoProducao';

    String Body = '''
                 <serviceRequest serviceName="OperacaoProducaoSP.liberarCentroDeTrabalho">
                  <requestBody>
                      <instancias>
                          <instancia>
                              <IDIATV>${widget.idiatv}</IDIATV>
                          </instancia>
                      </instancias>
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
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => CentroTrabScreen(
                      widget.operador, widget.nome, widget.ip)));
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
                      Text(
                        'Resposta Sankhya (Finalizar Atividade)',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.0),
                      Text('Status: $status'),
                      Text('Mensagem: $decodedString'),
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

    await ApiService.closeSession();
  }

  TextEditingController _textController = TextEditingController();

  void qntApontada() {
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
                TextFormField(
                  controller: _textController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Digite a quantidade produzida',
                  ),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
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

  Future<void> salvarApontamento() async {
    //final String url =
    //  'http://${widget.ip}:5000/post_salvarapontamento?qnt=${_textController.text}&nuapo=${nuapo}&seqapa=${seqapa}';

    String _servidor = '';
    String jsessionid = await ApiService.openSession();
    //jsessionid = jsessionid.split('=')[1];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mge/service.sbr?serviceName=CRUDServiceProvider.saveRecord&application=OperacaoProducao&resourceID=br.com.sankhya.producao.cad.OperacaoProducao';

    String Body = '''
        <serviceRequest serviceName="CRUDServiceProvider.saveRecord" ><requestBody>
          <dataSet rootEntity="ApontamentoPA" includePresentationFields="S" datasetid="1658322435343_10">
          <entity path=""><fieldset list="*"/><field name="CONTROLEPA"/></entity>
          <entity path="Produto"><fieldset list="DECQTD,TIPCONTEST"/></entity>
          <entity path="MotivosPerda"><field name="DESCRICAO"/></entity>
              <dataRow>
                  <localFields>
                      <QTDAPONTADA>${_textController.text}</QTDAPONTADA>
                  </localFields>
                  <key>
                      <NUAPO>${nuapo}</NUAPO>
                      <SEQAPA>${seqapa}</SEQAPA>
                  </key>
              </dataRow>
          </dataSet>
        </requestBody></serviceRequest>
             ''';

    final headers = {'Content-Type': 'application/xml', 'Cookie': jsessionid};

    final response = await http.post(
      Uri.parse(_url),
      headers: headers,
      body: utf8.encode(Body),
    );

    try {
      String decodedString = "";
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final serviceResponse =
            document.findAllElements('serviceResponse').first;

        final status = serviceResponse.getAttribute('status');
        if (status == "1") {
          decodedString = "Apontamento alterado com sucesso!!!";
        } else {
          final statusMessage = document.findAllElements('statusMessage').first;
          final cdataContent = statusMessage.text.trim();
          // limpa a string para BASE64
          final cleanedContent =
              cdataContent.replaceAll('\n', '').replaceAll(' ', '');
          // Decodifique a string BASE64
          final decodedBytes = base64Decode(cleanedContent);
          decodedString = String.fromCharCodes(decodedBytes);
        }
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
                    Text('Mensagem: $decodedString'),
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }

    await ApiService.closeSession();
  }

  bool _isLoading = false;

  Future<void> confirmarApontamento() async {
    //final String url =
    //'http://${widget.ip}:5000/post_confirmarapontamento?nuapo=${nuapo}&idiatv=${widget.idiatv}';

    String _servidor = '';
    String jsessionid = await ApiService.openSession();
    jsessionid = jsessionid.split('=')[1];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mgeprod/service.sbr?serviceName=OperacaoProducaoSP.confirmarApontamento&application=OperacaoProducao&mgeSession=${jsessionid}&resourceID=br.com.sankhya.producao.cad.OperacaoProducao';

    String Body = '''
        <serviceRequest serviceName="mgeprod@OperacaoProducaoSP.confirmarApontamento">
            <requestBody>
                <params NUAPO="${nuapo}" IDIATV="${widget.idiatv}" ACEITARQTDMAIOR="false" ULTIMOAPONTAMENTO="false" RESPOSTA_ULTIMO_APONTAMENTO="false"/>
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
      String decodedString = "";
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final serviceResponse =
            document.findAllElements('serviceResponse').first;

        final status = serviceResponse.getAttribute('status');
        if (status == "1") {
          decodedString = "Apontamento confirmado com sucesso!!!";
        } else {
          final statusMessage = document.findAllElements('statusMessage').first;
          final cdataContent = statusMessage.text.trim();
          // limpa a string para BASE64
          final cleanedContent =
              cdataContent.replaceAll('\n', '').replaceAll(' ', '');
          // Decodifique a string BASE64
          final decodedBytes = base64Decode(cleanedContent);
          decodedString = String.fromCharCodes(decodedBytes);
        }
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
                    Text('Mensagem: $decodedString'),
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }

    await ApiService.closeSession();
  }

  double _QTD_APRODUZ = 0.0;
  double _QTD_PRODUZ = 0.0;
  List<dynamic> rowsOP = [];

  Future<void> fetchOP() async {
    //final response = await http.get(Uri.parse(
    //  'http://${widget.ip}:5000/ordem_producao_detail?codordem=${widget.cod_ordem}'));

    String vsql = '''
              SELECT codOrdem, codProduto, descProduto, codCentro, descCentro
                , processo, lote, localOrigem, localDestino, DHINICIO, DHFINAL
                , DATASEQ, QTD_APRODUZ, QTD_PRODUZ, STATUSOP, IDIATV, IDPROC, IDEFX 
              FROM sankhya.AD_VAPP_OPS_SMART 
              WHERE codOrdem = ${widget.cod_ordem}
            ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
      var _resp = json.decode(response.body);
      final _status = _resp['status'];
      if (_status == "1") {
        final respBody = _resp['responseBody'];
        final rows = respBody['rows'];
        setState(() {
          rowsOP = rows;
          _QTD_APRODUZ = rowsOP[0][12];
          _QTD_PRODUZ = rowsOP[0][13];
        });
      } else {
        final _statusMessage = _resp['statusMessage'];
        var _mensage = _statusMessage;
        print('Failed mensagem: ${_mensage}');
      }
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }
    await ApiService.closeSession();
  }

  dynamic nuapo;
  dynamic seqapa;
  dynamic situacao;

  Future<void> fetchApontamentos() async {
    //final response = await http.get(Uri.parse(
    // 'http://${widget.ip}:5000/apontamentos?idiatv=${widget.idiatv}'));

    String vsql = '''
              Select APO.NUAPO, APA.SEQAPA, isnull(APO.SITUACAO,'') 
              from TPRAPO APO 
              left join TPRAPA APA ON APA.NUAPO = APO.NUAPO 
              WHERE IDIATV = ${widget.idiatv} AND SITUACAO = 'P'
            ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsData = rows;
      });
      if (rowsData.isNotEmpty) {
        nuapo = rowsData[0][0];
        seqapa = rowsData[0][1];
        situacao = rowsData[0][2];
      } else {}
    } else {
      throw Exception('Falha ao carregar os dados da API de apontamentos');
    }
    await ApiService.closeSession();
  }

  @override
  void initState() {
    fetchEtapas();
    fetchData2();
    fetchHardware();
    _startStopwatchFluxo();
    fetchOP();
    Timer.periodic(Duration(seconds: 5), (timer) {
      fetchHardware();
    });
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
    final centroDataFetcher = TemperaturaFetcher(
        'http://${widget.ip}/api/GetAuto.php', widget.cod_centro);

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Padding(
            padding: EdgeInsets.all(60),
            child: Text("${widget.produto}"),
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
                    "OP: ${widget.cod_ordem} | Cod Centro: ${widget.cod_centro}",
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
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                  decoration: BoxDecoration(color: _corFundo),
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                        ),
                        if (etapas.isNotEmpty && etapaIndex < etapas.length)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Container(
                                      margin:
                                          EdgeInsets.only(top: 20, bottom: 20),
                                      padding: EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                          top: 10,
                                          bottom: 10),
                                      width: 800,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Color(0xFF2A53A1),
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Center(
                                        child: Text(
                                          "Etapa ${widget.etapa}: ${_etapa}",
                                          style: TextStyle(
                                              color: Color(0xFF2A53A1),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )),
                                  Container(
                                    padding:
                                        EdgeInsets.only(top: 10, bottom: 10),
                                    child: Text(
                                      _tempoDecorrido,
                                      style: TextStyle(
                                          fontSize: 130,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(30),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            _startStopwatch();
                                            setState(() {
                                              _status = 1;
                                            });
                                          },
                                          child: Container(
                                            height: 70,
                                            width: 300,
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey),
                                                color: _status == 0
                                                    ? Colors.green
                                                    : Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Iniciar Timer",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Icon(
                                                  Icons.play_circle_outline,
                                                  color: Colors.white,
                                                  size: 35,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _confirmacao();
                                          },
                                          child: Container(
                                            height: 70,
                                            width: 300,
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey),
                                                color: Color(0xFF2A53A1),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Proxima Etapa",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  color: Colors.white,
                                                  size: 35,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        color: Colors.blueGrey,
                                        borderRadius:
                                            BorderRadius.circular(40)),
                                    margin:
                                        EdgeInsets.only(top: 10, bottom: 10),
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              AlertDialog(
                                            content: SizedBox(
                                              width: 800,
                                              height: 400,
                                              child: QRView(
                                                key: qrKey,
                                                onQRViewCreated:
                                                    _onQRViewCreated,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(5),
                                        child: Icon(
                                          Icons.api_rounded,
                                          size: 60,
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: 10, bottom: 10),
                                        padding:
                                            EdgeInsets.fromLTRB(30, 10, 30, 10),
                                        decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Text(
                                          "${_pesoHw} KG",
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
                                      Padding(
                                        padding: EdgeInsets.all(5),
                                        child: Icon(
                                          Icons.thermostat,
                                          size: 60,
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                30, 10, 30, 10),
                                            decoration: BoxDecoration(
                                                color: Color(0xFF2A53A1),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Text(
                                              "${_temperaturaHw}ºC",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 50,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(5),
                                            child: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 30,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                30, 10, 30, 10),
                                            decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Text(
                                              "${_temperatura2}ºC",
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
                              ),
                            ],
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
                                      "Situação: ${situacao == null ? '-' : situacao}",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
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
                                            fontSize: 16),
                                        textAlign: TextAlign.center,
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
                                        child: Text("Alterar Qtd. apontamento",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            textAlign: TextAlign.center),
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
                                      child: Text("Confirmar Apontamento",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                          textAlign: TextAlign.center),
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
                                              fontSize: 18),
                                          textAlign: TextAlign.center),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Tempo Extimado",
                                      style: TextStyle(
                                          color: Colors.blue, fontSize: 22),
                                    ),
                                    Text(
                                      "${_tempoEsperado}",
                                      style: TextStyle(
                                          color: Colors.blue, fontSize: 22),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Tempo Atual",
                                      style: TextStyle(
                                          color: Colors.orange, fontSize: 22),
                                    ),
                                    Text(
                                      "${_tempoDecorridoFluxo}",
                                      style: TextStyle(
                                          color: Colors.orange, fontSize: 22),
                                    ),
                                  ],
                                ),
                              ),
                              DiferenceTimes("${widget.etapa}", widget.ip,
                                  widget.cod_produto),
                              GestureDetector(
                                onTap: () async {
                                  final selectedItem =
                                      await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return DropdownPopup(
                                          widget.cod_centro,
                                          widget.cod_ordem,
                                          widget.operador,
                                          widget.etapa,
                                          widget.idiatv,
                                          widget.ip);
                                    },
                                  );
                                  if (selectedItem != null) {}
                                },
                                child: Container(
                                  height: 70,
                                  width: 400,
                                  padding: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Informar Parada",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 22),
                                      ),
                                      Icon(
                                        Icons.warning_amber,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
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
        ),
      ),
    );
  }
}
