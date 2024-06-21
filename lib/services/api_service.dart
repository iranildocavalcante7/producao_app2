import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:producao_app/models/centrotrab.dart';
import 'package:xml/xml.dart' as xml;
import 'database_helper.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:cookie_store/cookie_store.dart';
import 'package:producao_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String jsessionid = '';
  static String _servidor = '';
  static String _usuario = '';
  static String _senha = '';
  static String cookieHe = '';

  static Future<void> SyncDados() async {
    //final dbService = DatabaseHelper();
    //final confconn  = await dbService.getConfconn();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';
    _usuario = prefs.getString('api_usuario') ?? 'iranildo';
    _senha = prefs.getString('api_senha') ?? '123456';

    String _url =
        '${_servidor}/mge/service.sbr?serviceName=MobileLoginSP.login';

    String xmlBody = '''<?xml version="1.0" encoding="UTF-8"?>
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
        final serviceResponse =
            document.findAllElements('serviceResponse').first;
        final status = serviceResponse.getAttribute('status');
        if (status == "1") {
          jsessionid =
              'JSESSIONID=${document.findAllElements('jsessionid').first.text}';
          CentroSync();
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

  static Future<void> CentroSync() async {
    final DatabaseHelper _dbHelper = DatabaseHelper();

    var _url = '';
    _url =
        '${_servidor}/mge/service.sbr?serviceName=DbExplorerSP.executeQuery&outputType=json';

    var _sql = '''
              select CODWCP
                , NOME 
                , COUNT(DISTINCT codOrdem) QTDOP
              FROM TPRWCP WCP 
              JOIN TPRCWC CWC ON CWC.CODCWC = WCP.CODCWC 
              LEFT JOIN (
                select codOrdem 
                  , codCentro
                from AD_VAPP_OPS_SMART 
                group by codOrdem
                  , codCentro
              ) OP on (OP.codCentro = WCP.CODWCP)
              WHERE CODWCP <> 0 
              AND WCP.CODCWC = 5
              group by CODWCP
                , NOME 
          ''';

    String Body = '''
                  {"serviceName":"DbExplorerSP.executeQuery",
                     "requestBody": {
                       "sql": "${_sql}"
                     }
                  }    
                 ''';

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': jsessionid
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

          await _dbHelper.deleteCentrotrabAll();

          for (var i = 0; i < _rows.length; i++) {
            print('Centro: ${_rows[i][1]}');
            print('Qtd. Op: ${_rows[i][2]}');

            // limpa todos os Parceiros
            final _centro = Centrotrab(
                id: _rows[i][0], nome: _rows[i][1], qtdop: _rows[i][2]);

            // incluir o Centro trabalho
            await _dbHelper.insertCentrotrab(_centro);
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

  static Future<String> openSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';
    _usuario = prefs.getString('api_usuario') ?? 'iranildo';
    _senha = prefs.getString('api_senha') ?? '123456';

    String _url =
        '${_servidor}/mge/service.sbr?serviceName=MobileLoginSP.login';

    String xmlBody = '''<?xml version="1.0" encoding="UTF-8"?>
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
        final serviceResponse =
            document.findAllElements('serviceResponse').first;
        final status = serviceResponse.getAttribute('status');
        if (status == "1") {
          jsessionid =
              'JSESSIONID=${document.findAllElements('jsessionid').first.text}';
        } else {
          print('Usuário ou senha invalido!!!');
        }
      } else {
        print('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
    return jsessionid;
  }

  static Future<void> closeSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';
    _usuario = prefs.getString('api_usuario') ?? 'iranildo';
    _senha = prefs.getString('api_senha') ?? '123456';

    String _url =
        '${_servidor}/mge/service.sbr?serviceName=MobileLoginSP.logout&outputType=json';

    String Body = '''
                     {
                       "serviceName":"MobileLoginSP.logout",
                       "status": "1",
                       "pendingPrinting":"false"  
                     }    
                  ''';

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: utf8.encode(Body),
      );

      if (response.statusCode == 200) {
        print('Conn. Close...');
      } else {
        print('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  static Future<http.Response> DbExplorer(String vsql) async {
    String _servidor = '';
    String jsessionid = await ApiService.openSession();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _servidor = prefs.getString('api_servidor') ?? 'http://10.0.0.254';

    var _url =
        '${_servidor}/mge/service.sbr?serviceName=DbExplorerSP.executeQuery&outputType=json';

    String Body = '''
                 {"serviceName":"DbExplorerSP.executeQuery",
                     "requestBody": {
                     "sql": "${vsql}"
                       }
                  }    
                  ''';

    final headers = {'Content-Type': 'application/json', 'Cookie': jsessionid};

    final response = await http.post(
      Uri.parse(_url),
      headers: headers,
      body: utf8.encode(Body),
    );
    return response;
  }
}
