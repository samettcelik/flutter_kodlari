import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:honeywell_scanner/honeywell_scanner.dart';

class MalzemeBul extends StatefulWidget {
  @override
  _MalzemeBulState createState() => _MalzemeBulState();
}

class _MalzemeBulState extends State<MalzemeBul> {
  Map<String, dynamic>? materialDetails;
  HoneywellScanner honeywellScanner = HoneywellScanner();
  String? scannedBarcode;

  @override
  void initState() {
    super.initState();

    // Honeywell tarayıcıyı başlat ve dinleyicileri ayarla
    honeywellScanner.startScanner();
    honeywellScanner.onScannerDecodeCallback = (scannedData) {
      setState(() {
        scannedBarcode = scannedData?.code;
      });
      fetchMaterialDetails(scannedBarcode!);
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

  Future<void> fetchMaterialDetails(String barkodNo) async {
    final response = await http.get(Uri.parse('http://192.168.218.230:8083/api/materials/details/$barkodNo'));

    if (response.statusCode == 200) {
      setState(() {
        materialDetails = json.decode(response.body);
      });
    } else {
      setState(() {
        materialDetails = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Malzeme Bul'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Bilgisini öğrenmek istediğiniz malzemenin barkodunu okutun:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (scannedBarcode != null)
              Text(
                'Taranan Barkod: $scannedBarcode',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: 20),
            if (materialDetails != null)
              Table(
                border: TableBorder.all(color: Colors.grey),
                columnWidths: {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('SubLokasyon', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(materialDetails!['room']['subLocation']['name']),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Oda Numarası', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(materialDetails!['room']['odaNum']),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Model', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(materialDetails!['model']),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Marka', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(materialDetails!['marka']),
                      ),
                    ],
                  ),
                ],
              ),
            if (materialDetails == null && scannedBarcode != null)
              Text('Veri bulunamadı', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
