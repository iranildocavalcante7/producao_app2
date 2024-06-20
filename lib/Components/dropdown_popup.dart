import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:producao_app/screens/centrotrab_screen.dart';

class DropdownPopup extends StatefulWidget {
  var cod_centro;
  var cod_ordem;
  var operador;
  var etapa;
  var idiatv;
  DropdownPopup(
      this.cod_centro, this.cod_ordem, this.operador, this.etapa, this.idiatv);
  @override
  _DropdownPopupState createState() => _DropdownPopupState();
}

class _DropdownPopupState extends State<DropdownPopup> {
  List<Map<String, dynamic>> _dropdownItems = [];
  Map<String, dynamic>? _selectedItem;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final response =
        await http.get(Uri.parse('http://10.0.1.135:5000/motivo_paradas'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'] as List<dynamic>;

      setState(() {
        _dropdownItems = rows.map<Map<String, dynamic>>((row) {
          return {
            'id': row[0] as int,
            'motivoParada': row[1] as String,
          };
        }).toList();
      });
    }
  }

  Future<void> pararMaquina(int id) async {
    final String url =
        'http://10.0.1.135:5000/post_parar_maquina?idiatv=${widget.idiatv}&codmtp=${id}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String status = data['status'];
        String statusMessage = data['statusMessage'];
        String transactionId = data['transactionId'];
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
                      'Resposta Sankhya (Parar Reator)',
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
                        enviarDadosParaAPI();
                        Navigator.of(context).pop();
                        /*
                        var route = MaterialPageRoute(
                            builder: (BuildContext context) =>
                                Centro(widget.operador, ''));
                                
                        Navigator.of(context).push(route);
                        */
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
      }
    } catch (e) {
      print('Erro durante a requisição: $e');
    }
  }

  Future<void> enviarDadosParaAPI() async {
    String minhaString = "${_selectedItem}";

    // Use uma expressão regular para encontrar o valor de motivoParada
    RegExp regex = RegExp(r"motivoParada: ([^,}]+)");
    Match? match = regex.firstMatch(minhaString);
    String motivoParada = '';
    if (match != null) {
      setState(() {
        motivoParada = match.group(1)!;
      });
      print(motivoParada);
    } else {
      print("motivoParada não encontrado na string.");
    }
    final String apiUrl = 'http://10.0.1.135:3000/postParada';

    final Map<String, String> data = {
      "cod_centro": "${widget.cod_centro}",
      "cod_ordem": "${widget.cod_ordem}",
      "motivo": "${motivoParada.toString()}",
      "operador": "${widget.operador}",
      "tim": "${DateTime.now()}",
      "etapa": "${widget.etapa}"
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Dados enviados com sucesso
      print('Dados enviados com sucesso');
    } else {
      // Algo deu errado
      print('Erro ao enviar dados para a API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('MOTIVO DE PARADA | IDIATV: ${widget.idiatv}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedItem,
            onChanged: (newValue) {
              setState(() {
                _selectedItem = newValue;
              });
            },
            items: _dropdownItems.map((item) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: item,
                child: Text(item['motivoParada'].toString() as String),
              );
            }).toList(),
            decoration:
                InputDecoration(labelText: 'Selecione um motivo de parada'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_selectedItem != null) {
              pararMaquina(_selectedItem!['id']);
            } else {
              // Adicione aqui o código que você deseja executar caso nenhum item seja selecionado.
              print('Nenhum item selecionado');
            }
          },
          child: Text('SALVAR'),
        ),
      ],
    );
  }
}
