import 'package:flutter/material.dart';

class ProgressDialog {
  static Future<void> show(BuildContext context, {String? message}) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // Usuário não pode fechar o diálogo tocando fora dele
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevenir o fechamento do diálogo ao pressionar o botão de voltar
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(message ?? 'Processando...'),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop(); // Fecha o diálogo
  }
}
