import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/usuario.dart';
import '../models/confconn.dart';
import '../models/centrotrab.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE confconn(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endereco TEXT,
        usuario TEXT,
        senha TEXT,
        codven TEXT
      )
    ''');

    await db.execute('''
      INSERT INTO confconn(id,endereco,usuario,senha,codven) VALUES
                  (1,'http://10.0.0.254:8280','ADMIN','123456','14766')
    ''');

    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE centrotrab(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT
      )
    ''');
    
  }

  Future<int> insertConfconn(Confconn confconn) async {
    final db = await database;
    return await db.insert('confconn', confconn.toMap());
  }

  Future<int> updateConfconn(Confconn confconn) async {
    final db = await database;
    return await db.update('confconn', confconn.toMap(), where: 'id = ?', whereArgs: [confconn.id]);
  }

  Future<int> deleteConfconn(int id) async {
    final db = await database;
    return await db.delete('confconn', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Confconn>> getConfconn() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('confconn');
    return List.generate(maps.length, (i) {
      return Confconn.fromMap(maps[i]);
    });
  }

  Future<String?> getEndereco() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('confconn');
    if (result.isNotEmpty) {
      return result.first['endereco'];
    }
    return null;
  }




  Future<int> insertUsuario(Usuario usuario) async {
    final db = await database;
    return await db.insert('usuarios', usuario.toMap());
  }

  Future<int> updateUsuario(Usuario usuario) async {
    final db = await database;
    return await db.update('usuarios', usuario.toMap(), where: 'id = ?', whereArgs: [usuario.id]);
  }

  Future<int> deleteUsuario(int id) async {
    final db = await database;
    return await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  

  Future<int> deleteUsuarioAll() async {
    final db = await database;
    return await db.delete('usuarios', where: 'id != 0');
  }

  


  Future<List<Usuario>> getUsuarios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('usuarios');
    return List.generate(maps.length, (i) {
      return Usuario.fromMap(maps[i]);
    });
  }


 // Nova função para encontrar um Usuario pelo ID
  Future<Usuario?> findUsuarioById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    } else {
      return null;
    }
  }


  Future<int> insertCentrotrab(Centrotrab centrotrab) async {
    final db = await database;
    return await db.insert('centrotrab', centrotrab.toMap());
  }

  Future<int> updateCentrotrab(Centrotrab centrotrab) async {
    final db = await database;
    return await db.update('centrotrab', centrotrab.toMap(), where: 'id = ?', whereArgs: [centrotrab.id]);
  }

  Future<int> deleteCentrotrab(int id) async {
    final db = await database;
    return await db.delete('centrotrab', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCentrotrabAll() async {
    final db = await database;
    return await db.delete('centrotrab', where: 'id != 0');
  }


  Future<List<Centrotrab>> getCentrotrab() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('centrotrab');
    return List.generate(maps.length, (i) {
      return Centrotrab.fromMap(maps[i]);
    });
  }

  Future<List<Centrotrab>> getCentrotrabs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('centrotrab');
    return List.generate(maps.length, (i) {
      return Centrotrab(
        id: maps[i]['id'],
        nome: maps[i]['nome'],
      );
    });
  }

 



}
