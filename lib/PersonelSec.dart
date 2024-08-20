import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'SayimEkrani.dart';

class PersonelSec extends StatefulWidget {
  @override
  _PersonelSecState createState() => _PersonelSecState();
}

class _PersonelSecState extends State<PersonelSec> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> personelList = [];
  List<Map<String, dynamic>> roomList = [];
  bool isLoading = false;
  String errorMessage = '';
  Map<String, dynamic>? selectedPersonel;

  void _searchPersonel() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      personelList.clear();
      selectedPersonel = null;
      roomList.clear();
    });

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Lütfen bir arama terimi girin.';
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(
          'http://192.168.218.230:8083/api/personel/search?query=$query'));

      if (response.statusCode == 200) {
        setState(() {
          personelList =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          if (personelList.isEmpty) {
            errorMessage = 'Aradığınız kriterlere uygun personel bulunamadı.';
          }
        });
      } else {
        setState(() {
          errorMessage = 'Bir hata oluştu: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _selectPersonel(Map<String, dynamic> personel) async {
    setState(() {
      selectedPersonel = personel;
      roomList.clear();
      isLoading = true;
    });

    final personelId = personel['per_id'];

    try {
      final response = await http.get(Uri.parse(
          'http://192.168.218.230:8083/api/personel/rooms-by-personel?perId=$personelId'));

      if (response.statusCode == 200) {
        setState(() {
          roomList =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          if (roomList.isEmpty) {
            errorMessage = 'Bu personelin kayıtlı malzemesi bulunmamaktadır.';
          } else {
            _showRoomSelection(); // Odalar listesini göster
          }
        });
      } else {
        setState(() {
          errorMessage = 'Bir hata oluştu: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showRoomSelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: roomList.map((room) {
            return ListTile(
              title: Text('Oda: ${room['odaNum'] ?? 'Oda numarası yok'}'),
              onTap: () {
                Navigator.pop(context);
                _selectRoom(room);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _selectRoom(Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SayimEkrani(
          username: 'Kullanıcı Adı',
          selectedPersonelId: selectedPersonel!['per_id'],
          selectedPersonelAdSoyad: selectedPersonel!['adSoyad'],
          selectedRoomId: room['id'],
          selectedRoomNum: room['odaNum'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personel Seç'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Personel Adı veya Sicil No',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchPersonel,
                ),
              ),
            ),
            SizedBox(height: 10),
            if (isLoading)
              CircularProgressIndicator()
            else if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              )
            else if (selectedPersonel == null)
              Expanded(
                child: ListView.builder(
                  itemCount: personelList.length,
                  itemBuilder: (context, index) {
                    final personel = personelList[index];
                    return ListTile(
                      title: Text(personel['adSoyad']),
                      subtitle: Text('Sicil No: ${personel['sicilNo']}'),
                      onTap: () {
                        _selectPersonel(personel);
                      },
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
