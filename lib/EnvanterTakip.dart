import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_5/MalzemeBul.dart';
import 'package:http/http.dart' as http;
import 'SayimEkrani.dart';
import 'main.dart';  // Main sayfasına yönlendirme için ekledim

class EnvanterTakip extends StatefulWidget {
  final String username;

  EnvanterTakip({required this.username});

  @override
  _EnvanterTakipState createState() => _EnvanterTakipState();
}

class _EnvanterTakipState extends State<EnvanterTakip> {
  int totalMaterials = 0;
  bool isLoading = false; // Yüklenme durumu

  @override
  void initState() {
    super.initState();
    _fetchTotalMaterialCount();
  }

  Future<void> _fetchTotalMaterialCount() async {
    setState(() {
      isLoading = true; // Yükleme başlıyor
    });

    try {
      // location_id'yi username üzerinden alıyoruz.
      final locationIdResponse = await http.get(Uri.parse('http://192.168.218.230:8083/api/location/${widget.username}'));
      final locationId = json.decode(locationIdResponse.body);

      // location_id'ye göre tüm malzeme sayısını alıyoruz.
      final response = await http.get(Uri.parse('http://192.168.218.230:8083/api/materials/location/$locationId/total'));
      final count = json.decode(response.body);

      setState(() {
        totalMaterials = count;
      });

      // AlertDialog kaldırıldı, sadece ekran güncellenecek.
    } catch (e) {
      print('Error fetching total material count: $e');
    } finally {
      setState(() {
        isLoading = false; // Yükleme bitti
      });
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyApp()), // main.dart'a yönlendiriyoruz
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Envanter Takip Sistemi'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 40),
              Text(
                'Envanter Takip Sistemi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      '$totalMaterials',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'TOPLAM MALZEME SAYISI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SayimEkrani(username: widget.username)),
                  );
                },
                child: Text(
                  'SAYIM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MalzemeBul()), // MalzemeBul sayfasına yönlendiriyoruz
                  );
                },
                child: Text(
                  'MALZEME BUL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : () {
                  _fetchTotalMaterialCount(); // Malzeme sayısını yeniden alıyoruz
                },
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              strokeWidth: 2.0,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'GÜNCELLENİYOR...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'VERİLERİ GÜNCELLE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout,
                child: Text(
                  'ÇIKIŞ YAP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
