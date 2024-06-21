import 'package:flutter/material.dart';
//import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:producao_app/screens/Fim.dart';
import 'package:producao_app/screens/FluxoAlyne.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:xml/xml.dart' as xml;
import 'package:convert/convert.dart';

class DetalhesOp extends StatefulWidget {
  var id_ordem;
  var operador;
  var cod_centro;
  var nome;
  var ip;
  DetalhesOp(this.id_ordem, this.operador, this.cod_centro, this.nome, this.ip);

  @override
  _DetalhesOpState createState() => _DetalhesOpState();
}

class _DetalhesOpState extends State<DetalhesOp> {
  List<dynamic> _paradas = [];
  int _etapaParada = 1;

  Future<void> fetchDataParadas() async {
    String apiFunc = 'http://${widget.ip}/api/GetParadas.php';
    var data = {'codigo': widget.id_ordem};
    http.Response response =
        await http.post(Uri.parse(apiFunc), body: json.encode(data));
    setState(() {
      _paradas = json.decode(response.body);
      _etapaParada = _paradas[0]["etapa"];
    });
  }

  String _codOrdem = '';
  String _codProduto = '';
  String _descProduto = '';
  String _codCentro = '';
  String _descCentro = '';
  String _processo = '';
  String _lote = '';
  String _localOrigem = '';
  String _localDestino = '';
  String _DHINICIO = '';
  String _DHFINAL = '';
  String _DATASEQ = '';
  String _QTD_APRODUZ = '';
  String _QTD_PRODUZ = '';
  String _STATUSOP = '';
  String _IDIATV = '';
  String _IDPROC = '';
  String _IDEFX = '';
  List<dynamic> rowsData = [];

  Future<void> fetchData2() async {
    String vsql = '''
              SELECT codOrdem, codProduto, descProduto, codCentro, descCentro
                , processo, lote, localOrigem, localDestino, DHINICIO, DHFINAL
                , DATASEQ, QTD_APRODUZ, QTD_PRODUZ, STATUSOP, IDIATV, IDPROC, IDEFX 
              FROM sankhya.AD_VAPP_OPS_SMART 
              WHERE codOrdem = ${widget.id_ordem}
            ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
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
        _QTD_APRODUZ = rowsData[0][12].toString();
        _QTD_PRODUZ = rowsData[0][13].toString();
        _STATUSOP = rowsData[0][14].toString();
        _IDIATV = rowsData[0][15].toString();
        _IDPROC = rowsData[0][16].toString();
        _IDEFX = rowsData[0][17].toString();
      });
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }
    await ApiService.closeSession();
  }

  Future<void> fetchDataFluxo() async {
    //final response = await http
    // .get(Uri.parse('http://${widget.ip}:5000/fluxo?codprod=$_codProduto'));

    String vsql = '''
            SELECT PRO.CODPROD as codProduto, pre.descpre as etapa, PRE.SEQPRE as prioridade
              , pre.TEMPO as tempoAgitacao 
            FROM AD_MODPRE PRE 
            LEFT JOIN TGFPRO PRO ON PRO.CODPROD = PRE.CODPROD 
            WHERE PRO.CODPROD = ${_codProduto}            
            ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsData = rows;
      });
      if (rowsData.isNotEmpty) {
        iniciarOP();
      } else {
        final snackBar = SnackBar(
          content: const Text("Fluxo não cadastrado"),
          action: SnackBarAction(
            label: 'Ok',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }

    await ApiService.closeSession();
  }

  Future<void> fetchDataFluxoReiniciar() async {
    //final response = await http
    //  .get(Uri.parse('http://${widget.ip}:5000/fluxo?codprod=$_codProduto'));

    String vsql = '''
            SELECT PRO.CODPROD as codProduto, pre.descpre as etapa
                , PRE.SEQPRE as prioridade, pre.TEMPO as tempoAgitacao 
            FROM AD_MODPRE PRE  
            LEFT JOIN TGFPRO PRO ON PRO.CODPROD = PRE.CODPROD 
            WHERE PRO.CODPROD = ${_codProduto}
            ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsData = rows;
      });
      if (rowsData.isNotEmpty) {
        reiniciarOP();
      } else {
        final snackBar = SnackBar(
          content: const Text("Fluxo não cadastrado"),
          action: SnackBarAction(
            label: 'Ok',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }

    await ApiService.closeSession();
  }

  Future<void> iniciarOP() async {
    //final String url =
    //'http://${widget.ip}:5000/post_iniciarop?idiatv=$_IDIATV';

    String _servidor = '';
    String jsessionid = await ApiService.openSession();
    jsessionid = jsessionid.split('=')[1];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mgeprod/service.sbr?serviceName=OperacaoProducaoSP.iniciarInstanciaAtividades&application=OperacaoProducao&mgeSession=$jsessionid&resourceID=br.com.sankhya.producao.cad.OperacaoProducao';

    String Body = '''
                  <serviceRequest serviceName="OperacaoProducaoSP.iniciarInstanciaAtividades">
                          <requestBody>
                              <instancias>
                                  <instancia>
                                      <IDIATV>${_IDIATV}</IDIATV>
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
        if (status == '1') {
          sendData();
        } else {
          final statusMessage = document.findAllElements('statusMessage').first;
          final cdataContent = statusMessage.text.trim();
          // limpa a string para BASE64
          final cleanedContent =
              cdataContent.replaceAll('\n', '').replaceAll(' ', '');
          // Decodifique a string BASE64
          final decodedBytes = base64Decode(cleanedContent);
          final decodedString = String.fromCharCodes(decodedBytes);

          _showDialog(context, 'Resposta Sankhya (Iniciar Atividade)',
              'Status: $status\nMensagem: $decodedString');
        }
      } else {
        throw Exception('Failed to initiate OP');
      }
    } catch (e) {
      throw Exception('Failed to initiate OP');
    }

    await ApiService.closeSession();
  }

  Future<void> reiniciarOP() async {
    //final String url =
    //'http://${widget.ip}:5000/post_continuar_op?idiatv=$_IDIATV';

    String _servidor = '';
    String jsessionid = await ApiService.openSession();
    jsessionid = jsessionid.split('=')[1];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mgeprod/service.sbr?serviceName=OperacaoProducaoSP.continuarInstanciaAtividades&application=OperacaoProducao&mgeSession=$jsessionid&resourceID=br.com.sankhya.producao.cad.OperacaoProducao';

    String Body = '''
                  <serviceRequest serviceName="OperacaoProducaoSP.iniciarInstanciaAtividades">
                          <requestBody>
                              <instancias>
                                  <instancia>
                                      <IDIATV>${_IDIATV}</IDIATV>
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
          sendDataReiniciar(_etapaParada);
        } else {
          final statusMessage = document.findAllElements('statusMessage').first;
          final cdataContent = statusMessage.text.trim();
          // limpa a string para BASE64
          final cleanedContent =
              cdataContent.replaceAll('\n', '').replaceAll(' ', '');
          // Decodifique a string BASE64
          final decodedBytes = base64Decode(cleanedContent);
          final decodedString = String.fromCharCodes(decodedBytes);

          _showDialog(context, 'Resposta Sankhya (Reiniciar Atividade)',
              'Status: $status\nMensagem: $decodedString');
        }
      } else {
        throw Exception('Failed to restart OP');
      }
    } catch (e) {
      throw Exception('Failed to restart OP');
    }

    await ApiService.closeSession();
  }

  Future<void> liberarCentro() async {
    //final String url =
    //  'http://${widget.ip}:5000/post_liberarcentro?idiatv=$_IDIATV';

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
                                  <IDIATV>${_IDIATV}</IDIATV>
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
          final snackBar = SnackBar(
            content: const Text("Centro de trabalho liberado com sucesso"),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          final statusMessage = document.findAllElements('statusMessage').first;
          final cdataContent = statusMessage.text.trim();
          // limpa a string para BASE64
          final cleanedContent =
              cdataContent.replaceAll('\n', '').replaceAll(' ', '');
          // Decodifique a string BASE64
          final decodedBytes = base64Decode(cleanedContent);
          final decodedString = String.fromCharCodes(decodedBytes);

          _showDialog(context, 'Resposta Sankhya (Finalizar Atividade)',
              'Status: $status\nMensagem: $decodedString');
        }
      } else {
        throw Exception('Failed to release center');
      }
    } catch (e) {
      throw Exception('Failed to release center');
    }

    await ApiService.closeSession();
  }

  void _showDialog(BuildContext context, String title, String content) {
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
                  title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.0),
                Text(content),
                SizedBox(height: 12.0),
                ElevatedButton(
                  onPressed: () {
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

  Future<void> sendData() async {
    var res = await http
        .post(Uri.parse('http://${widget.ip}/api/InsertMudOp.php'), body: {
      "op": _codOrdem,
      "status": _STATUSOP,
      "tim": DateTime.now().toString()
    });

    if (res.statusCode == 200) {
      var data = json.decode(res.body);
      if (data["error"]) {
        final snackBar = SnackBar(
          content: const Text("Erro ao salvar dados. Verifique conexão!"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        final snackBar = SnackBar(
          content: const Text("Dados salvos com sucesso!"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        var route = MaterialPageRoute(
            builder: (BuildContext context) => FluxoAlyne(
                _descProduto,
                1,
                widget.operador,
                _codProduto,
                _codOrdem,
                widget.cod_centro,
                widget.nome,
                _IDIATV,
                widget.ip));
        Navigator.of(context).push(route);
      }
    } else {
      final snackBar = SnackBar(
        content: const Text("Erro ao salvar dados. Verifique conexão!"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> sendDataReiniciar(int etapa) async {
    if (etapa > rowsData.length) {
      var route = MaterialPageRoute(
          builder: (BuildContext context) => FimFluxo(
              _descProduto,
              rowsData.length.toString(),
              widget.operador,
              _codOrdem,
              _codProduto,
              widget.cod_centro,
              widget.nome,
              _IDIATV,
              widget.ip));
      Navigator.of(context).push(route);
      final snackBar = SnackBar(
        content: const Text("Fluxo de produção já executado"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      var res = await http
          .post(Uri.parse('http://${widget.ip}/api/InsertMudOp.php'), body: {
        "op": _codOrdem,
        "status": _STATUSOP,
        "tim": DateTime.now().toString()
      });

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        if (data["error"]) {
          final snackBar = SnackBar(
            content: const Text("Erro ao salvar dados. Verifique conexão!"),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          final snackBar = SnackBar(
            content: const Text("Dados salvos com sucesso!"),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          var route = MaterialPageRoute(
              builder: (BuildContext context) => FluxoAlyne(
                  _descProduto,
                  etapa,
                  widget.operador,
                  _codProduto,
                  _codOrdem,
                  widget.cod_centro,
                  widget.nome,
                  _IDIATV,
                  widget.ip));
          Navigator.of(context).push(route);
        }
      } else {
        final snackBar = SnackBar(
          content: const Text("Erro ao salvar dados. Verifique conexão!"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  @override
  void initState() {
    //FlutterRingtonePlayer.stop();
    fetchData2();
    //fetchDataParadas();
    super.initState();
  }

  @override
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
                children: [
                  Text(
                    "DETALHES",
                    style: TextStyle(
                        color: Color(0xFF2A53A1),
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.only(left: 50, right: 50),
        child: Center(
          child: Column(
            children: [
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                margin:
                    EdgeInsets.only(top: 100, bottom: 50, left: 80, right: 80),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF2A53A1), width: 3)),
                child: Text(
                  "$_codProduto | $_descProduto",
                  style: TextStyle(
                      color: Color(0xFF2A53A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildInfoBox("PROCESSO", _processo),
                    _buildInfoBox("LOTE", _lote),
                    _buildInfoBox("DATA | EMISSÃO", _DATASEQ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildInfoBox("ORDEM DE PRODUÇÃO", _codOrdem),
                    _buildInfoBox("LOCAL DE ORIGEM", _localOrigem),
                    _buildInfoBox("DATA | INCLUSÃO", _DHINICIO),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildInfoBox(
                        "OPERADOR", "${widget.operador} - ${widget.nome}"),
                    _buildInfoBox("LOCAL DE DESTINO", _localDestino),
                    _buildInfoBox("HORA | INCLUSÃO", _DHFINAL),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildActionButton(
                      "LIBERAR CENTRO", Colors.blue, liberarCentro),
                  _buildActionButton("INICIAR PRODUÇÃO", Color(0xFF3B9955), () {
                    if (_STATUSOP == "Em Andamento") {
                      fetchDataFluxoReiniciar();
                    } else {
                      fetchDataFluxo();
                    }
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: EdgeInsets.only(right: 20, left: 20),
      width: 300,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Color(0xFF2A53A1), fontWeight: FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  color: Color(0xFF2A53A1), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      child: Container(
        height: 55,
        width: 280,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: color,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            if (label == "INICIAR PRODUÇÃO")
              Icon(Icons.check_circle_outline, color: Colors.white),
          ],
        ),
      ),
      onTap: onPressed,
    );
  }
}
