class Centrotrab {
  int? id;
  String nome;

  Centrotrab({this.id, required this.nome});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
    };
  }

  factory Centrotrab.fromMap(Map<String, dynamic> map) {
    return Centrotrab(
      id: map['id'],
      nome: map['nome'],
    );
  }

  factory Centrotrab.fromJson(Map<String, dynamic> json) {
    return Centrotrab(
      id: json['id'],
      nome: json['nome'],
    );
  }


}
