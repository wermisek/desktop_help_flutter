// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'package:http/http.dart' as http;
import 'problemtemp.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpDesk Admin',
      theme: ThemeData.light().copyWith(
        primaryColor: Color(0xFFFFFFFF),
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
        buttonTheme: ButtonThemeData(buttonColor: Colors.white),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      home: AdminHomePage(),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String searchQuery = '';
  List<dynamic> problems = [];
  List<dynamic> filteredProblems = [];
  List<dynamic> users = [];  // New list for users
  Timer? _refreshTimer;
  bool showUsers = false;
  bool showProblems = true;
  final PageController _pageController = PageController();
  int currentPage = 0;
  final int itemsPerPage = 12;
  DateTime? selectedDate;  // Variable to hold the selected date for filtering

  Future<void> getProblems() async {
    try {
      var response =
      await HttpClient().getUrl(Uri.parse('http://192.168.10.188:8080/get_problems'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      setState(() {
        problems = jsonDecode(content);
      });
    } catch (e) {
      _showErrorDialog(context, 'Błąd połączenia', 'Nie udało się pobrać danych z serwera.');
    }
  }

  @override
  void initState() {
    super.initState();
    getProblems().then((_) {
      _resetFilter(); // Wywołanie resetowania filtra, gdy dane są już załadowane
    });
    getUsers();  // Pobierz użytkowników
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      getProblems();
      getUsers();  // Odświeżaj użytkowników co sekundę
    });
  }


  void _resetFilter() {
    setState(() {
      filteredProblems = problems;  // Reset do wszystkich zgłoszeń
    });
  }



  Future<void> getUsers() async {
    try {
      var response =
      await HttpClient().getUrl(Uri.parse('http://192.168.10.188:8080/get_users'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      setState(() {
        users = jsonDecode(content);
      });
    } catch (e) {
      _showErrorDialog(context, 'Błąd połączenia', 'Nie udało się pobrać danych użytkowników.');
    }
  }

  // Metoda do załadowania zgłoszeń (przykładowo)

  Widget _buildProblemList() {
    List<List<dynamic>> paginatedProblems = [];
    for (int i = 0; i < filteredProblems.length; i += itemsPerPage) {
      paginatedProblems.add(filteredProblems.sublist(
        i,
        i + itemsPerPage > filteredProblems.length
            ? filteredProblems.length
            : i + itemsPerPage,
      ));
    }

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: Column(
          children: [
            // Pasek wyszukiwania i przycisk kalendarza
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zgłoszenia',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4.0,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: TextField(
                          style: TextStyle(color: Colors.black), // Ustawienie koloru tekstu na czarny
                          decoration: InputDecoration(
                            hintText: 'Wyszukaj...',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Color(0xFFF49402)),
                            ),
                          ),
                          onChanged: _filterProblems,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_today, color: Colors.black),
                      onPressed: () async {
                        // Otwórz DatePicker
                        DateTime? selectedDateTemp = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: Colors.black,
                                colorScheme: ColorScheme.light(primary: Colors.black),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  // Dodajemy przycisk czyszczenia daty w formularzu
                                  Expanded(child: child!),
                                ],
                              ),
                            );
                          },
                        );
                        if (selectedDateTemp != null) {
                          setState(() {
                            selectedDate = selectedDateTemp;
                          });
                          _filterByDate(selectedDate!); // Filtrujemy według daty
                        }
                      },
                    ),
                    // Przycisk "X" do usuwania filtra daty
                    if (selectedDate != null)
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                            filteredProblems = problems;  // Reset to original list
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 3.0),
            // Sprawdzenie, czy są zgłoszenia
            filteredProblems.isEmpty
                ? Expanded(
              child: Center(
                child: Text(
                  'Brak zgłoszeń pasujących do wyszukiwania.',
                  style: TextStyle(fontSize: 16.0, color: Colors.black),
                ),
              ),
            )
                : Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: paginatedProblems.length,
                onPageChanged: (pageIndex) {
                  setState(() {
                    currentPage = pageIndex;
                  });
                },
                itemBuilder: (context, pageIndex) {
                  var pageProblems = paginatedProblems[pageIndex];
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.87,
                    ),
                    itemCount: pageProblems.length,
                    itemBuilder: (context, index) {
                      var problem = pageProblems[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5.0),
                        elevation: 10,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 15.0, vertical: 10.0),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sala: ${problem['room'] ?? 'Nieznana'}',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Nauczyciel: ${problem['username'] ?? 'Nieznany'}',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Treść: ${problem['problem'] ?? 'Brak opisu'}',
                                style: TextStyle(
                                  color: Colors.black,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      final response = await http.put(
                                        Uri.parse(
                                            'http://192.168.10.188:8080/mark_as_read/${problem['id']}'),
                                      );

                                      if (response.statusCode == 200) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProblemTempPage(problem: problem),
                                          ),
                                        );
                                      } else {
                                        _showErrorDialog(context, 'Błąd', 'Nie udało się oznaczyć zgłoszenia jako przeczytane.');
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      minimumSize: Size(120, 36),
                                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                                    ),
                                    child: Text(
                                      'Rozwiń',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (filteredProblems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          size: 20, color: Color(0xFFF49402)),
                      onPressed: currentPage > 0
                          ? () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                    ),
                    Text(
                      '${currentPage + 1} / ${paginatedProblems.length}',
                      style: TextStyle(fontSize: 14.0, color: Colors.black),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios,
                          size: 20, color: Color(0xFFF49402)),
                      onPressed: currentPage < paginatedProblems.length - 1
                          ? () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Funkcja do filtrowania zgłoszeń po dacie
  void _filterByDate(DateTime selectedDate) {
    setState(() {
      filteredProblems = problems.where((problem) {
        if (problem['timestamp'] != null) {
          DateTime problemDate = DateTime.parse(problem['timestamp']);
          return problemDate.year == selectedDate.year &&
              problemDate.month == selectedDate.month &&
              problemDate.day == selectedDate.day;
        }
        return false;
      }).toList();
    });
  }

  // Funkcja filtrowania zgłoszeń
  void _filterProblems(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredProblems = problems;
      } else if (int.tryParse(query) != null) {
        filteredProblems = problems
            .where((problem) => problem['room']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
            .toList();
      } else {
        filteredProblems = problems
            .where((problem) => problem['username']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
            .toList();
      }
    });
  }








  Widget _buildUserList() {
    List<List<dynamic>> paginatedUsers = [];
    for (int i = 0; i < users.length; i += 12) {
      paginatedUsers.add(users.sublist(i, i + 12 > users.length ? users.length : i + 12));
    }

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zarządzanie użytkownikami',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4.0,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF000000).withOpacity(0.3),
                        blurRadius: 10.0,
                        spreadRadius: 0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      _showAddUserDialog(context); // Wywołanie funkcji do wyświetlenia popupu
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Dodaj użytkownika',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              ],
            ),

            SizedBox(height: 10.0),
            Expanded(
              child: paginatedUsers.isEmpty
                  ? Center(
                child: Text(
                  'Brak użytkowników.',
                  style: TextStyle(fontSize: 16.0, color: Colors.black),
                ),
              )
                  : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: paginatedUsers.length,
                      onPageChanged: (pageIndex) {
                        setState(() {
                          currentPage = pageIndex;
                        });
                      },
                      itemBuilder: (context, pageIndex) {
                        var pageUsers = paginatedUsers[pageIndex];
                        return GridView.builder(
                          padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 1.87,
                          ),
                          itemCount: pageUsers.length,
                          itemBuilder: (context, index) {
                            var user = pageUsers[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 5.0),
                              elevation: 10,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Użytkownik: ${user['username'] ?? 'Nieznany użytkownik'}',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Rola: ${user['role'] ?? 'Brak roli'}',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Tooltip(
                                          message: 'Zmień login',
                                          child: IconButton(
                                            icon: Icon(Icons.edit, color: Colors.black),
                                            onPressed: () {
                                              _changeUsername(user);
                                            },
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Zmień hasło',
                                          child: IconButton(
                                            icon: Icon(Icons.lock, color: Colors.black),
                                            onPressed: () {
                                              _changePassword(user);
                                            },
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Usuń użytkownika',
                                          child: IconButton(
                                            icon: Icon(Icons.delete, color: Colors.black),
                                            onPressed: () {
                                              _deleteUser(user);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFFF49402)),
                          onPressed: currentPage > 0
                              ? () {
                            _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                              : null,
                        ),
                        Text(
                          '${currentPage + 1} / ${paginatedUsers.length}',
                          style: TextStyle(fontSize: 14.0, color: Colors.black),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFFF49402)),
                          onPressed: currentPage < paginatedUsers.length - 1
                              ? () {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _changeUsername(dynamic user) {
    TextEditingController usernameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Zaokrąglone rogi
          ),
          backgroundColor: Colors.white, // Tło dopasowane do motywu
          title: Text(
            'Zmień login',
            style: TextStyle(color: Colors.black), // Kolor tekstu nagłówka
          ),
          content: TextField(
            controller: usernameController,
            style: TextStyle(color: Colors.black), // Kolor tekstu w polu input
            decoration: InputDecoration(
              labelText: 'Nowy login',
              labelStyle: TextStyle(color: Colors.black), // Kolor etykiety
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF49402)), // Kolor obramowania po zaznaczeniu
              ),
            ),
          ),
          actions: <Widget>[
            // Przycisk "Anuluj"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Zamknięcie okna dialogowego
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Kolor tła przycisku "Anuluj"
                foregroundColor: Colors.black, // Kolor tekstu przycisku
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Wewnętrzne odstępy
              ),
              child: Text('Anuluj'),
            ),
            // Przycisk "Zapisz"
            TextButton(
              onPressed: () async {
                String newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty) {
                  var response = await http.put(
                    Uri.parse('http://192.168.10.188:8080/change_username'),
                    body: json.encode({
                      'oldUsername': user['username'], // Stary login użytkownika
                      'newUsername': newUsername, // Nowy login
                    }),
                    headers: {
                      'Content-Type': 'application/json',
                      'role': 'admin', // Nagłówek potwierdzający rolę admina
                    },
                  );

                  if (response.statusCode == 200) {
                    print('Login został zmieniony');
                    Navigator.of(context).pop(); // Zamknięcie okna dialogowego
                  } else {
                    print('Błąd zmiany loginu: ${response.body}');
                    Navigator.of(context).pop(); // Zamknięcie okna dialogowego
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Kolor tła przycisku "Zapisz"
                foregroundColor: Colors.black, // Kolor tekstu przycisku
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Wewnętrzne odstępy
              ),
              child: Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }





  void _changePassword(dynamic user) {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Zaokrąglone rogi
          ),
          backgroundColor: Colors.white, // Tło dopasowane do motywu
          title: Text(
            'Zmień hasło',
            style: TextStyle(color: Colors.black), // Kolor tekstu nagłówka
          ),
          content: TextField(
            controller: passwordController,
            style: TextStyle(color: Colors.black),
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Nowe hasło',
              labelStyle: TextStyle(color: Colors.black), // Kolor etykiety
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF49402)), // Kolor obramowania po zaznaczeniu
              ),
            ),
          ),
          actions: <Widget>[
            // Przycisk "Anuluj"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Zamknięcie okna dialogowego
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Kolor tła przycisku "Anuluj"
                foregroundColor: Colors.black, // Kolor tekstu przycisku
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Wewnętrzne odstępy
              ),
              child: Text('Anuluj'),
            ),
            // Przycisk "Zapisz"
            TextButton(
              onPressed: () async {
                String newPassword = passwordController.text.trim();
                if (newPassword.isNotEmpty) {
                  var response = await http.put(
                    Uri.parse('http://192.168.10.188:8080/change_password'),
                    body: json.encode({
                      'username': user['username'], // Nazwa użytkownika
                      'newPassword': newPassword, // Nowe hasło
                    }),
                    headers: {
                      'Content-Type': 'application/json',
                      'role': 'admin', // Nagłówek potwierdzający rolę admina
                    },
                  );

                  if (response.statusCode == 200) {
                    print('Hasło zostało zmienione');
                    Navigator.of(context).pop(); // Zamknięcie okna dialogowego
                  } else {
                    print('Błąd zmiany hasła: ${response.body}');
                    Navigator.of(context).pop(); // Zamknięcie okna dialogowego
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Kolor tła przycisku "Zapisz"
                foregroundColor: Colors.black, // Kolor tekstu przycisku
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Wewnętrzne odstępy
              ),
              child: Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }


  void _deleteUser(dynamic user) {
    // Wyświetlenie okna dialogowego potwierdzenia w stylu kafelków
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Zaokrąglone rogi dla dialogu
          ),
          backgroundColor: Colors.white, // Tło okna dialogowego dopasowane do ciemnego motywu
          title: Text(
            'Potwierdź usunięcie',
            style: TextStyle(color: Colors.black), // Kolor tekstu nagłówka
          ),
          content: Text(
            'Czy na pewno chcesz usunąć użytkownika ${user['username']}?',
            style: TextStyle(color: Colors.black), // Kolor tekstu w treści
          ),
          actions: <Widget>[
            // Przycisk "Tak"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Zamknięcie okna dialogowego
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Kolor tła przycisku "Anuluj"
                foregroundColor: Colors.black, // Kolor tekstu przycisku
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Wewnętrzne odstępy przycisku
              ),
              child: Text('Anuluj'),
            ),
            TextButton(
              onPressed: () async {
                var response = await http.delete(
                  Uri.parse('http://192.168.10.188:8080/delete_user'),
                  headers: {
                    'Content-Type': 'application/json',
                    'role': 'admin', // Nagłówek z rolą admina
                  },
                  body: json.encode({
                    'username': user['username'], // Nazwa użytkownika do usunięcia
                  }),
                );

                if (response.statusCode == 200) {
                  print('Użytkownik został usunięty');
                  Navigator.of(context).pop(); // Zamknięcie okna dialogowego
                } else {
                  print('Błąd usuwania użytkownika: ${response.body}');
                  Navigator.of(context).pop(); // Zamknięcie okna dialogowego
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Kolor tła przycisku "Tak"
                foregroundColor: Colors.black, // Kolor tekstu przycisku
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Wewnętrzne odstępy przycisku
              ),
              child: Text('Usun'),
            ),


          ],
        );
      },
    );
  }








  void _showErrorDialog(BuildContext context, String title, String message) {
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
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HelpDesk Admin Panel',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            // tooltip: '', // Usunięcie tooltipa, bo nie jest to wspierane
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              SizedBox(
                height: 80.0, // Wysokość nagłówka
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Wyśrodkowanie pionowe
                    crossAxisAlignment: CrossAxisAlignment.center, // Wyśrodkowanie poziome
                    children: [
                      Text(
                        'Helpdesk Admin',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 19.0, // Ustalony rozmiar czcionki
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.0), // Przestrzeń między tekstem a linią
                      Divider( // Linia pod napisem
                        color: Color(0xFFF49402),
                        thickness: 1.0, // Grubość linii
                        indent: 0, // Brak wcięcia po lewej stronie
                        endIndent: 0, // Brak wcięcia po prawej stronie
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.report_problem, color: Colors.black),
                title: Text('Zgłoszenia', style: TextStyle(color: Colors.black)),
                onTap: () {
                  setState(() {
                    showProblems = true;
                    showUsers = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.group, color: Colors.black),
                title: Text('Użytkownicy', style: TextStyle(color: Colors.black)),
                onTap: () {
                  setState(() {
                    showProblems = false;
                    showUsers = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.black),
                title: Text('Ustawienia', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Divider(
            color: Color(0xFFF49402),
            thickness: 1.0,
            height: 1.0,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (showProblems) _buildProblemList(),
                  if (showUsers) _buildUserList(), // Show users
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();//push
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,  // Ciemne tło (dopasowane do reszty)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),  // Zaokrąglone rogi
          ),
          title: Text(
            'Dodaj użytkownika',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18.0,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Login',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF49402)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: TextStyle(color: Colors.black),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Hasło',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF49402)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: roleController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Rola',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF49402)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Zamknij popup
              },
              child: Text(
                'Anuluj',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                final username = usernameController.text;
                final password = passwordController.text;
                final role = roleController.text;

                // Tutaj wywołaj funkcję do utworzenia użytkownika
                _createUser(username, password, role);
                Navigator.of(context).pop();  // Zamknij popup po stworzeniu użytkownika
              },
              child: Text(
                'Stwórz',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
  void _createUser(String username, String password, String role) async {
    var newUser = {
      "username": username,
      "password": password,
      "role": role,
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.10.188:8080/register'),  // Upewnij się, że adres jest poprawny
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(newUser),
      );

      if (response.statusCode == 201) {
        // Jeśli użytkownik został pomyślnie utworzony
        print("Użytkownik stworzony: ${response.body}");
      } else {
        // Jeśli wystąpił błąd przy tworzeniu użytkownika
        final responseBody = json.decode(response.body);
        print("Błąd tworzenia użytkownika: ${responseBody['message']}");
      }
    } catch (e) {
      print("Błąd podczas wysyłania zapytania: $e");
    }
  }
}