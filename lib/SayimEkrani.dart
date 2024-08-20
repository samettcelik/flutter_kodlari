import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Lokasyon.dart';
import 'PersonelSec.dart';
import 'package:honeywell_scanner/honeywell_scanner.dart';

class SayimEkrani extends StatefulWidget {
  final String username;
  final String? selectedPersonelAdSoyad;
  final int? selectedPersonelId;
  final String? selectedRoomNum;
  final int? selectedRoomId;

  SayimEkrani({
    required this.username,
    this.selectedPersonelAdSoyad,
    this.selectedPersonelId,
    this.selectedRoomNum,
    this.selectedRoomId,
  });

  @override
  _SayimEkraniState createState() => _SayimEkraniState();
}

class _SayimEkraniState extends State<SayimEkrani> {
  String? selectedRoomNum;
  int? selectedRoomId;
  String? selectedPersonelAdSoyad;
  int? selectedPersonelId;

  int totalEnvanter = 0;
  int bulunanEnvanter = 0;
  int bulunmayanEnvanter = 0;
  int farkliLokasyonEnvanter = 0;

  bool isLocationSelected = false;
  HoneywellScanner honeywellScanner = HoneywellScanner();
  String? scannedBarcode;

  @override
  void initState() {
    super.initState();
    selectedRoomId = widget.selectedRoomId;
    selectedRoomNum = widget.selectedRoomNum;
    selectedPersonelId = widget.selectedPersonelId;
    selectedPersonelAdSoyad = widget.selectedPersonelAdSoyad;
    isLocationSelected = widget.selectedPersonelId == null;
    _fetchEnvanterSayisi();

    // Honeywell tarayıcıyı başlat ve dinleyicileri ayarla
    honeywellScanner.startScanner();
    honeywellScanner.onScannerDecodeCallback = (scannedData) {
      setState(() {
        scannedBarcode = scannedData?.code;
      });
      _checkBarcode();
    };

    honeywellScanner.onScannerErrorCallback = (error) {
      print('Tarayıcı hatası: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarayıcı hatası oluştu.')),
      );
    };
  }

  @override
  void dispose() {
    honeywellScanner.stopScanner();
    super.dispose();
  }

  void _navigateAndSelectLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Lokasyon(username: widget.username),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        isLocationSelected = true;
        selectedRoomId = result['roomId'];
        selectedRoomNum = result['roomNum'];
        selectedPersonelAdSoyad = null;
        selectedPersonelId = null;
        _fetchEnvanterSayisi();
      });
    }
  }

  void _navigateAndSelectPersonel(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonelSec(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        isLocationSelected = false;
        selectedPersonelAdSoyad = result['adSoyad'];
        selectedPersonelId = result['perId'];
        selectedRoomNum = result['roomNum'];
        selectedRoomId = result['roomId'];
        _fetchEnvanterSayisi();
      });
    }
  }

  Future<void> _fetchEnvanterSayisi() async {
    if (selectedRoomId == null) return;

    try {
      final totalResponse = await http.get(Uri.parse(
        isLocationSelected
            ? 'http://192.168.218.230:8083/api/materials/total/$selectedRoomId'
            : 'http://192.168.218.230:8083/api/materials/total/${selectedPersonelId!}/$selectedRoomId',
      ));
      final totalData = json.decode(totalResponse.body);

      final foundResponse = await http.get(Uri.parse(
        isLocationSelected
            ? 'http://192.168.218.230:8083/api/materials/found/$selectedRoomId'
            : 'http://192.168.218.230:8083/api/materials/found/${selectedPersonelId!}/$selectedRoomId',
      ));
      final foundData = json.decode(foundResponse.body);

      if (!isLocationSelected) {
        final otherLocationsResponse = await http.get(Uri.parse(
          'http://192.168.218.230:8083/api/materials/other-locations/${selectedPersonelId!}/$selectedRoomId',
        ));
        final otherLocationsData = json.decode(otherLocationsResponse.body);

        setState(() {
          farkliLokasyonEnvanter = otherLocationsData;
        });
      }

      setState(() {
        totalEnvanter = totalData;
        bulunanEnvanter = foundData;
        bulunmayanEnvanter = totalEnvanter - bulunanEnvanter;
      });
    } catch (e) {
      print('Envanter bilgisi alınırken hata oluştu: $e');
    }
  }

  void _checkBarcode() async {
    if (scannedBarcode != null && scannedBarcode!.isNotEmpty) {
      try {
        final url = isLocationSelected
            ? 'http://192.168.218.230:8083/api/materials/update-status?barkodNo=$scannedBarcode&found=true'
            : 'http://192.168.218.230:8083/api/personel/update-material-status';

        final body = {
          'roomId': selectedRoomId.toString(),
          if (!isLocationSelected) 'perId': selectedPersonelId!.toString(),
          'barkodNo': scannedBarcode!,
          'found': 'true',
        };

        final response = await http.post(Uri.parse(url), body: body);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Barkod başarıyla güncellendi.')),
          );
          _fetchEnvanterSayisi();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Barkod farklı bir odaya aittir.')),
          );
        }
      } catch (e) {
        print('Barkod güncellenirken hata oluştu: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir barkod numarası girin')),
      );
    }
  }

  void _saveFoundMaterials() async {
    if (!isLocationSelected &&
        selectedPersonelId != null &&
        selectedRoomId != null) {
      try {
        final materialsResponse = await http.get(Uri.parse(
            'http://192.168.218.230:8083/api/personel/materials?perId=$selectedPersonelId'));
        final List<dynamic> materials = jsonDecode(materialsResponse.body);

        if (materials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bulunan malzeme yok.')),
          );
          return;
        }

        final List<dynamic> foundMaterials =
            materials.where((m) => m['bulduMu'] == true).toList();

        if (foundMaterials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bulunan malzeme yok.')),
          );
          return;
        }

        for (var material in foundMaterials) {
          final matId = material['matId'];
          final sicilNo = material['personel']['sicilNo'];

          final url = 'http://192.168.218.230:8083/api/found-materials/save';

          final body = jsonEncode({
            'material': {
              'matId': matId,
            },
            'room': {
              'id': selectedRoomId,
            },
            'personel': {
              'per_id': selectedPersonelId,
            },
            'sicilNo': sicilNo,
            'foundDate': DateTime.now().toIso8601String(),
          });

          final headers = {"Content-Type": "application/json"};

          final response =
              await http.post(Uri.parse(url), body: body, headers: headers);

          if (response.statusCode == 200) {
            print('Malzeme $matId başarıyla kaydedildi.');
          } else {
            print('Malzeme $matId kaydedilemedi: ${response.body}');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sayım başarıyla kaydedildi.')),
        );
      } catch (e) {
        print('Sayım kaydı yapılırken hata oluştu: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Geçersiz işlem: Personel ve Oda seçili olmalı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sayım Ekranı'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _navigateAndSelectLocation(context),
                  child: Text(
                    'LOKASYON SEÇ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _navigateAndSelectPersonel(context),
                  child: Text(
                    'PERSONEL SEÇ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                if (!isLocationSelected && selectedPersonelAdSoyad != null)
                  Text(
                    'Personel: $selectedPersonelAdSoyad',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (selectedRoomNum != null)
                  Text(
                    'Oda Numarası: $selectedRoomNum',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                else
                  Text(
                    'Henüz Lokasyon veya Personel Seçmediniz.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                SizedBox(height: 10),
                if (scannedBarcode != null)
                  Text(
                    'Taranan Barkod: $scannedBarcode',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: 10),
                _buildEnvanterInfo(
                    'TOPLAM SAYILMASI GEREKEN ENVANTER', totalEnvanter),
                SizedBox(height: 10),
                _buildEnvanterInfo(
                    'BULUNMAYAN ENVANTERLER', bulunmayanEnvanter),
                SizedBox(height: 10),
                _buildEnvanterInfo('BULUNAN ENVANTERLER', bulunanEnvanter),
                if (!isLocationSelected)
                  Column(
                    children: [
                      SizedBox(height: 10),
                      _buildEnvanterInfo('FARKLI LOKASYONDAKİ ENVANTERLER',
                          farkliLokasyonEnvanter),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _saveFoundMaterials,
                        child: Text(
                          'SAYIM KAYDET',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnvanterInfo(String title, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
          Container(
            width: 55,
            height: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
