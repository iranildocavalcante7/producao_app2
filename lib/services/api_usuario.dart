import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:producao_app/models/centrotrab.dart';
import 'package:producao_app/models/usuario.dart';
import 'package:xml/xml.dart' as xml;
import 'database_helper.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:cookie_store/cookie_store.dart';
import 'package:producao_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiUsuario {

  static String jsessionid = '';
  static String _servidor = '';
  static String _usuario = '';
  static String _senha = '';

  static String cookieHe = '';

  static Future<void> SyncDados() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';
    _usuario  = prefs.getString('api_usuario') ?? 'iranildo';
    _senha    = prefs.getString('api_senha') ?? '123456';

  /*
    final dbService = DatabaseHelper();
    final confconn  = await dbService.getConfconn();

    var _url = '';
    if (confconn == null) {} else{
      endereco = confconn[0].endereco;
      _url = '${endereco}/mge/service.sbr?serviceName=MobileLoginSP.login';
    }
    */
    String _url = '${_servidor}/mge/service.sbr?serviceName=MobileLoginSP.login';

    String xmlBody  = '''<?xml version="1.0" encoding="UTF-8"?>
                          <serviceRequest serviceName="MobileLoginSP.login">
                            <requestBody>
                              <NOMUSU>${_usuario}</NOMUSU>
                              <INTERNO>${_senha}</INTERNO>
                            </requestBody>
                          </serviceRequest>''';

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/xml',
        },
        body: utf8.encode(xmlBody),
      );


      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final serviceResponse = document.findAllElements('serviceResponse').first;
        final status = serviceResponse.getAttribute('status');
        if (status == "1") {
          jsessionid = 'JSESSIONID=${document.findAllElements('jsessionid').first.text}';
          ParceiroSync();
        } else {
          print('Usuário ou senha invalido!!!');
        }
      } else {
        print('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  static Future<void> ParceiroSync() async {
    final DatabaseHelper _dbHelper = DatabaseHelper();

    var _url = '';
    _url = '${_servidor}/mge/service.sbr?serviceName=DbExplorerSP.executeQuery&outputType=json';

    const String Body = '''
                        {"serviceName":"DbExplorerSP.executeQuery",
                            "requestBody": {
                            "sql": "SELECT CODUSU,NOMEUSU FROM TSIUSU WHERE CODUSU <> 0 AND ISNULL(DTLIMACESSO,'') = '' "
                            }
                          }    
                        ''';

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Cookie':jsessionid
      };

      final response = await http.post(
        Uri.parse(_url),
        headers: headers,
        body: utf8.encode(Body),
      );

      if (response.statusCode == 200) {
        var _resp = json.decode(response.body);
        final _status = _resp['status'];
        if (_status == "1") {
          final _respBody = _resp['responseBody'];
          final _rows = _respBody['rows'];

          // limpa todos os Parceiros
          await _dbHelper.deleteUsuarioAll();
          for (var i=0; i < _rows.length; i++) {
            print('Usuário: ${_rows[i][1]}');        
            final _centro = Usuario(id: _rows[i][0]
                                    , nome: _rows[i][1]
                                    );
            // incluir o Centro trabalho
            await _dbHelper.insertUsuario(_centro);
          }
          
        } else {
          var _mensage = _resp[0]['statusMessage'];
          print('Failed mensagem: ${_mensage}');
        }
      } else {
        print('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }





}


