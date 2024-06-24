import 'package:flutter/material.dart';
import '../models/confconn.dart';
import '../services/database_helper.dart';
import 'package:producao_app/screens/Login.dart';

class ConfconnScreen extends StatefulWidget {
  @override
  _ConfconnScreenState createState() => _ConfconnScreenState();
}

class _ConfconnScreenState extends State<ConfconnScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<Confconn> _confconn = [];

  @override
  void initState() {
    super.initState();
    _loadConfconn();
  }

  Future<void> _loadConfconn() async {
    final confconn = await _dbHelper.getConfconn();
    setState(() {
      _confconn.clear();
      _confconn.addAll(confconn);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conf. Conexão'),
      ),
      body: ListView.builder(
        itemCount: _confconn.length,
        itemBuilder: (context, index) {
          final confconn = _confconn[index];
          return ListTile(
            title: Text(confconn.endereco),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Implementar edição
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ConfconnFormScreen(confconn: confconn),
                        )).then((value) => _loadConfconn());
                  },
                ),
                /*
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await _dbHelper.deleteConfconn(confconn.id!);
                    _loadConfconn();
                  },
                ),
                 */
              ],
            ),
          );
        },
      ),
      /*
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ConfconnFormScreen(),
          )).then((value) => _loadConfconn());
        },
        child: Icon(Icons.add),
      ),
       */
    );
  }
}

class ConfconnFormScreen extends StatefulWidget {
  final Confconn? confconn;

  ConfconnFormScreen({this.confconn});

  @override
  _ConfconnFormScreenState createState() => _ConfconnFormScreenState();
}

class _ConfconnFormScreenState extends State<ConfconnFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _endereco;
  late String _usuario;
  late String _senha;
  late String _codven;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.confconn != null) {
      _endereco = widget.confconn!.endereco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.confconn == null ? 'Adicionar Conexão' : 'Editar Conexão'),
        backgroundColor: Color(0xFF2A53A1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.confconn?.endereco,
                decoration: InputDecoration(labelText: 'Endereço'),
                onSaved: (value) => _endereco = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                initialValue: widget.confconn?.usuario,
                decoration: InputDecoration(labelText: 'Usuário'),
                onSaved: (value) => _usuario = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                initialValue: widget.confconn?.senha,
                decoration: InputDecoration(labelText: 'Senha'),
                onSaved: (value) => _senha = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                initialValue: widget.confconn?.codven,
                decoration: InputDecoration(labelText: 'Cod. Vendedor'),
                onSaved: (value) => _codven = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final confconn = Confconn(
                        id: widget.confconn?.id,
                        endereco: _endereco,
                        usuario: _usuario,
                        senha: _senha,
                        codven: _codven);
                    if (widget.confconn == null) {
                      await _dbHelper.insertConfconn(confconn);
                    } else {
                      await _dbHelper.updateConfconn(confconn);
                    }
                    var route = MaterialPageRoute(
                        builder: (BuildContext context) => LoginScreen());
                    Navigator.of(context).pushReplacement(route);
                    //Navigator.pop(context);
                  }
                },
                child: Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
