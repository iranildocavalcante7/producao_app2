import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DiferenceTimes extends StatefulWidget {
  String etapa;
  DiferenceTimes(this.etapa);
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
    final response = await http.get(Uri.parse('http://10.0.1.135:5000/fluxo_detail?codseq=${widget.etapa}'));
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
