import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'problemy.dart';

class AddProblemPage extends StatefulWidget {
  final String username;

  AddProblemPage({required this.username});

  @override
  _AddProblemPageState createState() => _AddProblemPageState();
}

class _AddProblemPageState extends State<AddProblemPage> {
  final _roomController = TextEditingController();
  final _problemController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showForm = false;
  bool _isOtherButtonVisible = true;
  bool _isDarkTheme = false;

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  Future<void> _submitProblem(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String room = _roomController.text;
      String problem = _problemController.text;

      // Problem data with 'read' set to 0 (unread)
      Map<String, dynamic> problemData = {
        'username': widget.username,
        'room': room,
        'problem': problem,
        'read': 0,
      };

      try {
        final request = await HttpClient()
            .postUrl(Uri.parse('http://192.168.10.188:8080/add_problem'));

        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(problemData));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 201) {
          _showDialog(
            context,
            title: 'Problem wysłany',
            message: 'Dziękujemy, ${widget.username}. Twój problem został przesłany.',
          );
        } else {
          _showDialog(
            context,
            title: 'Błąd',
            message: 'Nie udało się wysłać problemu. Serwer zwrócił: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        _showDialog(
          context,
          title: 'Błąd połączenia',
          message: 'Nie udało się połączyć z serwerem. Sprawdź połączenie sieciowe.',
        );
      }
    }
  }

  void _showDialog(BuildContext context,
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Dodaj Problem'),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      isDarkMode: _isDarkTheme,
                      toggleTheme: _toggleTheme,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showForm = !_showForm;
                      _isOtherButtonVisible = !_isOtherButtonVisible;
                    });
                  },
                  child: Text(_showForm ? 'Anuluj' : 'Dodaj Problem'),
                ),
                SizedBox(height: 20),
                if (_isOtherButtonVisible)
                  ElevatedButton(
                    onPressed: () {
                      print("Kliknięto przycisk Moje zgłoszenia.");
                    },
                    child: Text('Moje zgłoszenia (nie działa)'),
                  ),
                SizedBox(height: 20),
                if (_showForm)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _roomController,
                          decoration: InputDecoration(
                            labelText: 'Numer Sali',
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(color: Colors.black),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Proszę podać numer sali';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _problemController,
                          decoration: InputDecoration(
                            labelText: 'Opis Problemu',
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(color: Colors.black),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Proszę podać opis problemu';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _submitProblem(context),
                          child: Text('Wyślij problem'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
