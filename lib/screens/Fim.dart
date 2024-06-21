import 'package:flutter/material.dart';
//import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'centrotrab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:xml/xml.dart' as xml;

class FimFluxo extends StatefulWidget {
  var produto;
  var etapa;
  var operador;
  var cod_ordem;
  var cod_produto;
  var cod_centro;
  var nome;
  var idiatv;
  var ip;
  FimFluxo(this.produto, this.etapa, this.operador, this.cod_ordem,
      this.cod_produto, this.cod_centro, this.nome, this.idiatv, this.ip);

  @override
  _FimFluxoState createState() => _FimFluxoState();
}

class _FimFluxoState extends State<FimFluxo> {
  dynamic _tim = DateTime.now();
  dynamic _timEsperado = DateTime.now();
  String _cod_produto = '';
  String _processo = '';
  String _lote = '';
  String _hora_inclusao = '';
  List<dynamic> _timop = [];

  Future<dynamic> fetchTim() async {
    String apiFunc = 'http://${widget.ip}/api/GetTimOp.php';
    var data = {'codigo': "${widget.cod_ordem}"};
    http.Response response =
        await http.post(Uri.parse(apiFunc), body: json.encode(data));
    setState(() {
      _timop = json.decode(response.body);
      _tim = _timop[0]['tempo_decorrido'];
      _timEsperado = _timop[0]['tempo_esperado'];
    });
  }

  String formatarDuracao(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String horas = twoDigits(duration.inHours);
    String minutos = twoDigits(duration.inMinutes.remainder(60));
    String segundos = twoDigits(duration.inSeconds.remainder(60));

    return "$horas:$minutos:$segundos";
  }

  String _codOrdem = '';
  String _localOrigem = '';
  String _localDestino = '';
  String _DHINICIO = '';
  double _QTD_APRODUZ = 0.0;
  double _QTD_PRODUZ = 0.0;
  String _IDIATV = '';
  String _IDPROC = '';
  String _IDEFX = '';
  List<dynamic> rowsData = [];

  Future<void> fetchData2() async {
    //final response = await http.get(Uri.parse(
    //  'http://${widget.ip}:5000/ordem_producao_detail?codordem=${widget.cod_ordem}'));

    String vsql = '''
              SELECT codOrdem, codProduto, descProduto, codCentro, descCentro, processo, lote, localOrigem, localDestino, DHINICIO, DHFINAL, DATASEQ
                , QTD_APRODUZ, QTD_PRODUZ, STATUSOP, IDIATV, IDPROC, IDEFX 
              FROM SANKHYA_TEST.sankhya.AD_VAPP_OPS_SMART 
              WHERE STATUSOP <> 'Finalizado' AND codOrdem = ${widget.cod_ordem}
          ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
      ;
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsData = rows;
        _codOrdem = rowsData[0][0].toString();
        _processo = rowsData[0][5].toString();
        _lote = rowsData[0][6].toString();
        _localOrigem = rowsData[0][7].toString();
        _localDestino = rowsData[0][8].toString();
        _DHINICIO = rowsData[0][9].toString();
        _QTD_APRODUZ = rowsData[0][12];
        _QTD_PRODUZ = rowsData[0][13];
        _IDIATV = rowsData[0][15].toString();
        _IDPROC = rowsData[0][16].toString();
        _IDEFX = rowsData[0][17].toString();
      });
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }
    await ApiService.closeSession();
  }

  Future<void> finalizarOP(GlobalKey<ScaffoldState> _scaffoldKey) async {
    //final String url =
    //  'http://${widget.ip}:5000/post_finalizarop?idiatv=${_IDIATV}&idefx=${_IDEFX}&idiproc=${_cod_produto}&idproc=${_IDPROC}';

    String _servidor = '';
    String jsessionid = await ApiService.openSession();
    jsessionid = jsessionid.split('=')[1];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mgeprod/service.sbr?serviceName=OperacaoProducaoSP.finalizarInstanciaAtividades&mgeSession=${jsessionid}';

    String Body = '''
                <serviceRequest serviceName="OperacaoProducaoSP.finalizarInstanciaAtividades">
                <requestBody>
                    <instancias confirmarApontamentosDivergentes="false">
                        <instancia>
                            <IDIATV>${_IDIATV}</IDIATV>
                            <IDEFX>${_IDEFX}</IDEFX>
                            <IDIPROC>${_cod_produto}</IDIPROC>
                            <IDPROC>${_IDPROC}</IDPROC>
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
          _scaffoldKey.currentContext;
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
      } else {}
    } catch (e) {}
    await ApiService.closeSession();
  }

  bool _isLoading = false;
  Future<void> confirmarApontamento() async {
    //final String url =
    //  'http://${widget.ip}:5000/post_confirmarapontamento?nuapo=${nuapo}&idiatv=${widget.idiatv}';

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
    //final String url =
    //  'http://${widget.ip}:5000/post_apontar?idiatv=${widget.idiatv}';

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
      //final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //final Map<String, dynamic> data = json.decode(response.body);
        //String status = data['status'];
        //String statusMessage = data['statusMessage'];
        //String NUAPO = data['NUAPO'];
        //String LISTAPENDENTES = data['LISTAPENDENTES'];
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
                    Text('Status: $status'),
                    Text('Mensagem: $decodedString'),
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
    //  'http://${widget.ip}:5000/post_liberarcentro?idiatv=${_IDIATV}';

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
      //final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //final Map<String, dynamic> data = json.decode(response.body);
        //String status = data['status'];
        //String statusMessage = data['statusMessage'];

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
      } else {}
    } catch (e) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    await ApiService.closeSession();
  }

  List<dynamic> rowsOP = [];

  Future<void> fetchOP() async {
    //final response = await http.get(Uri.parse(
    //'http://${widget.ip}:5000/ordem_producao_detail?codordem=${widget.cod_ordem}'));

    String vsql = '''
        SELECT codOrdem, codProduto, descProduto, codCentro, descCentro
          , processo, lote, localOrigem, localDestino, DHINICIO, DHFINAL
          , DATASEQ, QTD_APRODUZ, QTD_PRODUZ, STATUSOP, IDIATV, IDPROC, IDEFX 
        FROM sankhya.AD_VAPP_OPS_SMART 
        WHERE codOrdem = ${widget.cod_ordem}
          ''';

    var response = await ApiService.DbExplorer(vsql);

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

    await ApiService.closeSession();
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
        //final Map<String, dynamic> data = json.decode(response.body);
        //String status = data['status'];
        //String statusMessage = data['statusMessage'];

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

  dynamic nuapo;
  dynamic seqapa;
  Future<void> fetchApontamentos() async {
    //final response = await http.get(Uri.parse(
    //  'http://${widget.ip}:5000/apontamentos?idiatv=${widget.idiatv}'));

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
      } else {}
    } else {
      throw Exception('Falha ao carregar os dados da API de apontamentos');
    }
    await ApiService.closeSession();
  }

  @override
  void initState() {
    //FlutterRingtonePlayer.stop();
    fetchData2();
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
                              borderRadius: BorderRadius.circular(15)),
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
                                      height: 75,
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
                                            fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                      onTap: () {
                                        qntApontada();
                                      },
                                      child: Container(
                                        height: 75,
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
                                              fontSize: 20),
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
                                      height: 75,
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
                                            fontSize: 20),
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
                                      height: 75,
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
                                              fontSize: 20),
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
