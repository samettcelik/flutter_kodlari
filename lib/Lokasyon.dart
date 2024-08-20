import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Lokasyon extends StatefulWidget {
  final String username;

  Lokasyon({required this.username});

  @override
  _LokasyonState createState() => _LokasyonState();
}

class _LokasyonState extends State<Lokasyon> {
  List<Map<String, dynamic>> subLocations = [];
  List<Map<String, dynamic>> filteredSubLocations = [];
  List<Map<String, dynamic>> rooms = [];
  bool isLoading = false;
  String query = "";

  @override
  void initState() {
    super.initState();
    fetchSubLocations();
  }

  Future<void> fetchSubLocations() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse('http://192.168.218.230:8083/api/sublocations'));

    if (response.statusCode == 200) {
      setState(() {
        subLocations = List<Map<String, dynamic>>.from(json.decode(response.body).map((data) => {'name': data['name'], 'id': data['id']}));
        filteredSubLocations = subLocations;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      query = newQuery;
      filteredSubLocations = subLocations
          .where((subLocation) =>
              subLocation['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> fetchRooms(int subId) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse('http://192.168.218.230:8083/api/rooms/$subId'));

    if (response.statusCode == 200) {
      setState(() {
        rooms = List<Map<String, dynamic>>.from(json.decode(response.body));
        isLoading = false;
      });
    } else {
      setState(() {
        rooms = [{'odaNum': 'Odalar yüklenemedi', 'id': null}];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lokasyon Seç'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Lokasyon Ara...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: updateSearchQuery,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSubLocations.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              filteredSubLocations[index]['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios),
                            onTap: () async {
                              await fetchRooms(filteredSubLocations[index]['id']);
                              setState(() {});
                            },
                          ),
                          Divider(),
                        ],
                      );
                    },
                  ),
                ),
                if (rooms.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6.0,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Odalar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        Divider(),
                        ...rooms.map((room) {
                          return ListTile(
                            title: Text(room['odaNum']),
                            onTap: () {
                              Navigator.pop(context, {
                                'roomId': room['id'],
                                'roomNum': room['odaNum'],
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
