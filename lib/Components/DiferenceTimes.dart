import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:xml/xml.dart' as xml;
import 'package:convert/convert.dart';

class DiferenceTimes extends StatefulWidget {
  String etapa;
  var ip;
  var cod_produto;
  DiferenceTimes(this.etapa, this.ip, this.cod_produto);
  @override
  _DiferenceTimesState createState() => _DiferenceTimesState();
}

class _DiferenceTimesState extends State<DiferenceTimes> {
  Stopwatch _stopwatch = Stopwatch();
  String _tempoDecorrido = '00:00:00';

  @override
  void initState() {
    _fetchDelayTimeFromAPI(); // Chama a função para buscar o tempo de delay da API
    super.initState();
  }

  Future<void> _fetchDelayTimeFromAPI() async {
    //final response = await http.get(Uri.parse(
    //'http://${widget.ip}:5000/fluxo_detail?codseq=${widget.etapa}&codprod=${widget.cod_produto}'));

    String vsql = '''
              SELECT PRO.CODPROD as codProduto, pre.descpre as etapa, PRE.SEQPRE as prioridade
                , isnull(Convert(Time(0),pre.TEMPO,0),'00:00:00')  as tempoAgitacao,  isnull(PRE.TEMPERATURA,0) as temperatura 
              FROM AD_MODPRE PRE 
              join TGFPRO PRO ON PRO.CODPROD = PRE.CODPROD  
              WHERE PRO.CODPROD = ${widget.cod_produto} 
                AND PRE.SEQPRE = ${widget.etapa} order by 1,3
            ''';

    var response = await ApiService.DbExplorer(vsql);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rows = data['responseBody']['rows'];
      setState(() {
        rowsData = rows;
        _tempoEsperado = rowsData[0][3];
      });
      _startStopwatchAfterDelay(_tempoEsperado);
    } else {
      throw Exception('Falha ao carregar os dados da API');
    }

    await ApiService.closeSession();
  }

  List<dynamic> rowsData = [];
  String _tempoEsperado = '00:00:00';

  void _startStopwatch() {
    _stopwatch.start();
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _tempoDecorrido = _formatDuration(_stopwatch.elapsed);
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

  void _startStopwatchAfterDelay(String tempo) {
    final desiredDuration = _parseDuration(tempo);

    Future.delayed(desiredDuration, () {
      if (!mounted) return;
      setState(() {
        _startStopwatch();
      });
    });
  }

  Duration _parseDuration(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } else {
      throw Exception('Formato de tempo inválido');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Tempo em Atraso",
            style: TextStyle(
              color: Colors.red,
              fontSize: 22,
            ),
          ),
          Text(
            "${_tempoDecorrido}",
            style: TextStyle(
              color: Colors.red,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
