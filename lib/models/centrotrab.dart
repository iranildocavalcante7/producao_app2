class Centrotrab {
  int? id;
  String nome;
  int qtdop;

  Centrotrab({this.id, required this.nome, required this.qtdop});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'qtdop': qtdop,
    };
  }

  factory Centrotrab.fromMap(Map<String, dynamic> map) {
    return Centrotrab(
      id: map['id'],
      nome: map['nome'],
      qtdop: map['qtdop'],
    );
  }

  factory Centrotrab.fromJson(Map<String, dynamic> json) {
    return Centrotrab(
      id: json['id'],
      nome: json['nome'],
      qtdop: json['qtdop'],
    );
  }
}
