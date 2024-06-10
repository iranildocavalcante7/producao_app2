class Confconn {
  int? id;
  String endereco;
  String usuario;
  String senha;
  String codven;

  Confconn({this.id, required this.endereco, required this.usuario, required this.senha, required this.codven});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endereco': endereco,
      'usuario': usuario,
      'senha': senha,
      'codven': codven,
    };
  }

  factory Confconn.fromMap(Map<String, dynamic> map) {
    return Confconn(
      id: map['id'],
      endereco: map['endereco'],
      usuario: map['usuario'],
      senha: map['senha'],
      codven: map['codven'],
    );
  }
}
