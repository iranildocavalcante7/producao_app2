import 'package:flutter/material.dart';
import 'package:producao_app/models/confconn.dart';
import 'package:producao_app/models/usuario.dart';
import 'package:producao_app/services/api_service.dart';
import 'package:producao_app/screens/centrotrab_screen.dart';
import 'dart:async';
import 'package:producao_app/services/api_usuario.dart';
import 'package:producao_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  final loading = ValueNotifier<bool>(false);
  
  TextEditingController _matriculaController = TextEditingController();
  
  TextEditingController _servidorController = TextEditingController();
  TextEditingController _usuarioController = TextEditingController();
  TextEditingController _senhaController = TextEditingController();
  
  String _servidor = 'http://10.0.0.254:8280'; // IP padrão
  String _usuario= 'iranildo'; // IP padrão
  String _senha= '123456'; // IP padrão

  String _appVersion  ="";
  
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadIp();
  }

  

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
    }
  
  Future<void> fetchData(context) async {
      final DatabaseHelper _db = DatabaseHelper();
      String vMat = _matriculaController.text;
      if (vMat == ""){
          _showDialog(context,"Matrícula invalida!!!");
          return;
      }
      int vCod = int.parse(vMat);
      //var vCodUsu = _db.findUsuarioById(vCod);
      Usuario? usuario = await _db.findUsuarioById(vCod);
      if (usuario != null){
        //print(usuario.id);
        //print(usuario.nome);
        var route = MaterialPageRoute(
            builder: (BuildContext context) => CentroTrabScreen(usuario.id,usuario.nome));
        Navigator.of(context).pushReplacement(route);
      }else{
          print('Usuário não encontrado!!!');
          _showDialog(context,"Usuário não encontrado!!!");
          return;
      }
  }

  void _showDialog(BuildContext context,String msg) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('App. Produção'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadIp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254:8280';
      _usuario  = prefs.getString('api_usuario') ?? 'iranildo';
      _senha    = prefs.getString('api_senha') ?? '123456';
    });
  }

  Future<void> _saveIp(String servidor,usuario,senha) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_servidor', servidor);
    await prefs.setString('api_usuario', usuario);
    await prefs.setString('api_senha', senha);

    ApiUsuario.SyncDados();
    await _startDataSync(3);
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

  }


  void _showParamServidorDialog() {
    _servidorController.text = _servidor; // Preenche o campo com o IP atual
    _usuarioController.text = _usuario; // Preenche o campo com o IP atual
    _senhaController.text = _senha; // Preenche o campo com o IP atual
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Informe o servidor de acesso'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _servidorController,
                  decoration: InputDecoration(
                    labelText: 'IP/Servidor(empresa.com.br,127.0.0.1)',
                  ),
                ),
                TextField(
                  controller: _usuarioController,
                  decoration: InputDecoration(
                    labelText: 'Usuário',
                  ),
                ),
                TextField(
                  controller: _senhaController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    //obscureText: true,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fechar o diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();                  
                setState(() {
                  // Fechar o diálogo de entrada
                  _servidor = _servidorController.text;
                  _usuario  = _usuarioController.text;
                  _senha    = _senhaController.text;
                  _saveIp(_servidor, _usuario, _senha); // Salvar IP no SharedPreferences
                });
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),

      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.fromLTRB(32, 150, 32, 32),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/backalyneweb.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(10),
                    width: 325,
                    height: 450,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withOpacity(0.95),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Image.asset("assets/logoalyne.png", fit: BoxFit.fill,),
                            ),
                          ),
                        ),
                        Text("Version: $_appVersion"),
                        SizedBox(
                          height: 20,
                        ),
                        TextField(
                          cursorColor: Colors.deepPurple,
                          controller: _matriculaController,
                          keyboardType: TextInputType.number,
                          onSubmitted: (srt) {
                            fetchData(context);
                          },
                          style: TextStyle(
                            color: Colors.blueGrey,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 0),
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                            labelText: "Insira sua Matrícula",
                            labelStyle: TextStyle(
                              fontSize: 20,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        
                        Container(
                          margin: EdgeInsets.only(top: 30),
                          height: 45,
                          width: 220,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(0xFF2A53A1),
                          ),
                          child: SizedBox.expand(
                            child: TextButton(
                              onPressed: () {
                                //ApiUsuario.SyncDados();
                                //ApiService.SyncDados();
                                //Navigator.pushReplacementNamed(context, '/centrotrab');
                                fetchData(context);
                              },
                              child: Text(
                                "Entrar",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                      SizedBox(
                          height: 10,
                        ),

                      Text(
                        "Alterar Servidor",
                        style: TextStyle(
                            color: Color(0xFF2A53A1),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        child: Icon(
                          Icons.sync_lock_rounded,
                          color: Colors.blue,
                          size: 28,
                        ),
                        onTap: () {
                          _showParamServidorDialog();
                        },
                      ),
                      
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
