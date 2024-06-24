import 'dart:async';
import 'package:flutter/material.dart';
import 'package:producao_app/models/usuario.dart';
import 'package:producao_app/screens/Login.dart';
import 'package:producao_app/services/database_helper.dart';
import 'package:producao_app/models/centrotrab.dart';
import 'package:producao_app/services/api_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:producao_app/screens/SelectOrdens.dart';

class CentroTrabScreen extends StatefulWidget {
  var operador;
  var nome;
  final String ip;

  CentroTrabScreen(this.operador, this.nome, this.ip);
  @override
  _CentroTrabScreenState createState() => _CentroTrabScreenState();
}

class _CentroTrabScreenState extends State<CentroTrabScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Centrotrab> _centrotrabs = [];
  String _appVersion = "";

  int _counter = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    //_startTimer();
    _refreshCentrotrabs();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        _counter++;
        _refreshCentrotrabs();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshCentrotrabs() async {
    final data = await _dbHelper.getCentrotrabs();
    setState(() {
      _centrotrabs = data;
    });
  }

  Future<void> _startDataSync(int vSec) async {
    // Exibir o diálogo de progresso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16.0),
                Text("Sincronizando Dados Aguarde..."),
              ],
            ),
          ),
        );
      },
    );

    // Simular uma chamada de API com um atraso
    await Future.delayed(Duration(seconds: vSec));

    // Fechar o diálogo de progresso
    Navigator.of(context).pop();

    // Exibir um diálogo de confirmação ou mensagem de sucesso/erro
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sincronização Completa'),
          content: Text('Os dados foram sincronizados com sucesso!!!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fechar o diálogo
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    _refreshCentrotrabs();
  }

  /*************************** 
   * Tela com a AppBar 
  ****************************/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.all(100),
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
            padding: EdgeInsets.only(left: 100, right: 100),
            decoration: BoxDecoration(color: Colors.white),
            child: Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Bem vindo(a) ${widget.nome}",
                  style: TextStyle(
                      color: Color(0xFF2A53A1),
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 50,
                ),
                Text(
                  "Version: $_appVersion",
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
                ),
                SizedBox(
                  width: 50,
                ),
                Text(
                  "Sync Dados: ",
                  style: TextStyle(
                      color: Color(0xFF2A53A1),
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.sync,
                    color: Colors.blue,
                  ),
                  onTap: () {
                    ApiService.SyncDados();
                    _startDataSync(3);
                    setState(() {
                      _refreshCentrotrabs();
                    });
                  },
                )
              ],
            )),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildGridView(),
        ),
      ),
    );
  }

  /*************************** 
   * Tela com a GridView 
  ****************************/
  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // Número máximo de colunas
        mainAxisExtent: 170,
      ),
      itemCount: _centrotrabs.length,
      itemBuilder: (context, index) {
        final centrotrab = _centrotrabs[index];
        return GestureDetector(
          onTap: () {
            var route = MaterialPageRoute(
                builder: (BuildContext context) => SelectOrdens(widget.operador,
                    centrotrab.nome, centrotrab.id, widget.nome, widget.ip));
            Navigator.of(context).push(route);
          },
          child: Container(
            height: 50,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipPath(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      //****************************/
                      // Faixa verde Centro de Trabalho
                      //****************************/
                      Container(
                        margin: EdgeInsets.all(8),
                        alignment: Alignment.topCenter,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color:
                              centrotrab.qtdop == 0 ? Colors.red : Colors.green,
                        ),
                        child: Center(
                          child: Text(
                            "Centro de Trabalho",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      //****************************/
                      // Primeiro texto com o nome Centro de Trabalho
                      //****************************/
                      Text(
                        centrotrab.nome,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('ID: ${centrotrab.id}'),

                      //****************************/
                      // Segundo texto com o nome Centro de Trabalho
                      //****************************/
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(5),
                        margin: EdgeInsets.only(left: 10, right: 10),
                        alignment: Alignment.center,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              //"TEMPERATURA",
                              "QUANTIDADE OP(s)",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              //'${'ºC'}',
                              '${centrotrab.qtdop}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color:
                              centrotrab.qtdop == 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
