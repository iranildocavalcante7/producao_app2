import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/database_helper.dart';

class UsuarioScreen extends StatefulWidget {
  @override
  _UsuarioScreenState createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<Usuario> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    final usuarios = await _dbHelper.getUsuarios();
    setState(() {
      _usuarios.clear();
      _usuarios.addAll(usuarios);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuários'),
      ),
      body: ListView.builder(
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final usuario = _usuarios[index];
          return ListTile(
            title: Text(usuario.nome),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Implementar edição
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => UsuarioFormScreen(usuario: usuario),
                    )).then((value) => _loadUsuarios());
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await _dbHelper.deleteUsuario(usuario.id!);
                    _loadUsuarios();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => UsuarioFormScreen(),
          )).then((value) => _loadUsuarios());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;

  UsuarioFormScreen({this.usuario});

  @override
  _UsuarioFormScreenState createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _nome;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.usuario != null) {
      _nome = widget.usuario!.nome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.usuario == null ? 'Adicionar Usuário' : 'Editar Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.usuario?.nome,
                decoration: InputDecoration(labelText: 'Nome'),
                onSaved: (value) => _nome = value!,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final usuario = Usuario(
                      id: widget.usuario?.id,
                      nome: _nome,
                    );
                    if (widget.usuario == null) {
                      await _dbHelper.insertUsuario(usuario);
                    } else {
                      await _dbHelper.updateUsuario(usuario);
                    }
                    Navigator.pop(context);
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
