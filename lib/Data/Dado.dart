class Dado {
  final int id;
  final String cod_ordem;
  var cod_produto;
  final String produto;

  Dado({required this.id, required this.cod_ordem, required this.cod_produto, required this.produto});

  factory Dado.fromJson(Map<String, dynamic> json) {
    return Dado(
      id: json['id'],
      cod_ordem: json['cod_ordem'],
      cod_produto: json['cod_produto'],
      produto: json['produto'],
    );
  }
}