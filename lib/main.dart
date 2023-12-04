import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Adicione essa linha para inicializar a databaseFactory
  // databaseFactory = databaseFactoryFfi;
  sqfliteFfiInit();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMC Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IMC Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Height (cm)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                calculateIMC(context); // Adicionando o contexto como parâmetro
              },
              child: Text('Calculate IMC'),
            ),
          ],
        ),
      ),
    );
  }

  void calculateIMC(BuildContext context) {
    double weight = double.parse(weightController.text);
    double height =
        double.parse(heightController.text) / 100; // Convert to meters
    double imc = weight / (height * height);

    saveToDatabase(context, imc); // Adicionando o contexto como parâmetro
  }

  // ...

  // Ajuste na função saveToDatabase para aceitar o contexto
  void saveToDatabase(BuildContext context, double imc) async {
    Database database = await openDatabase(
      join(await getDatabasesPath(), 'imc_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE imc_data(id INTEGER PRIMARY KEY, imc REAL)',
        );
      },
      version: 1,
    );

    await database.insert('imc_data', {'imc': imc});

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPage()),
    );
  }
}

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IMC History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No IMC data available'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('IMC: ${snapshot.data![index]['imc']}'),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    Database database = await openDatabase(
      join(await getDatabasesPath(), 'imc_database.db'),
      version: 1,
    );

    return await database.query('imc_data');
  }
}
