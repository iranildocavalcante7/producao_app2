import 'dart:async';
import 'package:flutter/material.dart';

class CurrentTimes extends StatefulWidget {
  const CurrentTimes({Key? key}) : super(key: key);

  @override
  _CurrentTimesState createState() => _CurrentTimesState();

}

class _CurrentTimesState extends State<CurrentTimes> {
  Stopwatch _stopwatchFluxo = Stopwatch();
  String _tempoDecorridoFluxo = '00:00:00';
  String _tempoFluxo = '00:00:00';
  void _startStopwatch() {
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
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitHours = twoDigits(duration.inHours);
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }
  @override
  void initState() {
    _startStopwatch();
    super.initState();
  }
  void dispose() {
    super.dispose();
  }
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }
}
