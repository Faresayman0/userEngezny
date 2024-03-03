// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class TransportDetails extends StatefulWidget {
  const TransportDetails({super.key});

  @override
  _TransportDetailsState createState() => _TransportDetailsState();
}

class _TransportDetailsState extends State<TransportDetails> {
  TextEditingController addNameController = TextEditingController();
  bool isSearching = false;
  Map<String, List<QueryDocumentSnapshot>> lineAvailableMap = {};
  Map<String, String> stationNameMap = {};
  Map<String, bool> expansionTileState = {};
  bool dataLoaded = false;
  Position? currentPosition;
  String selectedLineName = '';

  @override
  void initState() {
    super.initState();
    fetchData();
    checkLocationPermission();

    _getCurrentLocation();
  }

  Future<void> fetchData() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final snapshot = await FirebaseFirestore.instance
          .collection('المواقف')
          .orderBy('timestamp', descending: true)
          .get();
      print('Data fetched successfully.');

      List<Map<String, dynamic>> stationsWithDistance = [];

      for (final doc in snapshot.docs) {
        final lineData = await getLineAvailable(doc.id);
        GeoPoint location = doc['location'];
        double distance = await _calculateDistance(currentPosition.latitude,
            currentPosition.longitude, location.latitude, location.longitude);
        stationsWithDistance.add({
          'id': doc.id,
          'name': doc['name'],
          'distance': distance,
        });
        lineAvailableMap[doc.id] = lineData;
        stationNameMap[doc.id] = doc['name'];
        expansionTileState[doc.id] = true;
      }

      stationsWithDistance
          .sort((a, b) => a['distance'].compareTo(b['distance']));

      lineAvailableMap.clear();
      stationNameMap.clear();
      expansionTileState.clear();

      for (var station in stationsWithDistance) {
        lineAvailableMap[station['id']] = await getLineAvailable(station['id']);
        stationNameMap[station['id']] = station['name'];
        expansionTileState[station['id']] = true;
      }

      setState(() {
        dataLoaded = true;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<double> _calculateDistance(double userLat, double userLong,
      double stationLat, double stationLong) async {
    double distanceInMeters =
        Geolocator.distanceBetween(userLat, userLong, stationLat, stationLong);
    return distanceInMeters;
  }

  Future<List<QueryDocumentSnapshot>> getLineAvailable(String stationId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("المواقف")
          .doc(stationId)
          .collection("line")
          .get();

      return querySnapshot.docs;
    } catch (e) {
      return [];
    }
  }

  Future<void> checkLocationPermission() async {
    PermissionStatus permissionStatus = await Permission.location.status;

    if (permissionStatus != PermissionStatus.granted) {
      PermissionStatus newPermissionStatus =
          await Permission.location.request();

      if (newPermissionStatus != PermissionStatus.granted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('تفعيل الموقع'),
              content: const Text(
                  'يرجى تفعيل الصلاحية للوصول إلى الموقع واستخدام هذه الميزة'),
              actions: <Widget>[
                TextButton(
                  child: const Text('إغلاق'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('فتح الإعدادات'),
                  onPressed: () async {
                    openAppSettings();
                  },
                ),
              ],
            );
          },
        );
      }
    }
    _getCurrentLocation();

    // إذا كانت الصلاحية ممنوحة، نقوم بتنفيذ الكود الخاص بجلب البيانات
    fetchData();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentPosition = position;
      });
    } catch (e) {}
  }

  Future<void> _openInMap(double latitude, double longitude) async {
    String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  Future<void> _getPublicTransportForStation(
      String stationId, String lineName) async {
    setState(() {
      selectedLineName = lineName;
    });

    try {
      print(
          'Getting public transport for station: $stationId, line: $lineName');

      GeoPoint stationLocation = (await FirebaseFirestore.instance
              .collection('المواقف')
              .doc(stationId)
              .get())
          .get('location');
      print('Public transport data retrieved successfully.');

      const apiKey = 'AIzaSyDh3__9kh_BOO31Jph0XNt2VhSYVsMYobo';
      const apiUrl = 'https://maps.googleapis.com/maps/api/directions/json';

      const language = 'ar';

      final response = await http.get(Uri.parse(
          '$apiUrl?key=$apiKey&origin=${currentPosition!.latitude},${currentPosition!.longitude}&destination=${stationLocation.latitude},${stationLocation.longitude}&mode=transit&language=$language'));

      if (response.statusCode == 200) {
        print(response.request);
        print(response.statusCode);
        print(response.body);

        final decodedData = json.decode(response.body);

        const arrivalTimeText = 'لاحقا';
        final distance = (decodedData['routes'][0]['legs'][0]["distance"] !=
                    null &&
                decodedData['routes'][0]['legs'][0]["distance"]['text'] != null)
            ? decodedData['routes'][0]['legs'][0]["distance"]['text']
            : 'لاحقا';

        final departureTime =
            (decodedData['routes'][0]['legs'][0]['departure_time'] != null &&
                    decodedData['routes'][0]['legs'][0]['departure_time']
                            ['text'] !=
                        null)
                ? decodedData['routes'][0]['legs'][0]['departure_time']['text']
                : 'لاحقا';

        final duration = (decodedData['routes'][0]['legs'][0]["duration"] !=
                    null &&
                decodedData['routes'][0]['legs'][0]["duration"]['text'] != null)
            ? decodedData['routes'][0]['legs'][0]["duration"]['text']
            : 'لاحقا';

        _showTransportDetailsBottomSheet(decodedData, arrivalTimeText,
            departureTime, distance, duration, stationLocation);
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                "حدثت مشكله ",
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 18),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            );
          },
        );
        throw Exception('فشل في تحميل بيانات النقل العام');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "لا توجد مواصلات عامه لهذه المنطقه حاليا في هذا الوقت",
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          );
        },
      );
      print('Error getting public transport data: $e');
    }
  }

 void _showTransportDetailsBottomSheet(
  Map<String, dynamic> data,
  String arrivalTime,
  String departureTime,
  String distance,
  String duration,
  GeoPoint stationLocation,
) {
  if (data.containsKey('routes') &&
      data['routes'].isNotEmpty &&
      data['routes'][0].containsKey('legs') &&
      data['routes'][0]['legs'].isNotEmpty &&
      data['routes'][0]['legs'][0].containsKey('steps') &&
      data['routes'][0]['legs'][0]['steps'].isNotEmpty) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _openInMap(
                        stationLocation.latitude,
                        stationLocation.longitude,
                      );
                    },
                    icon: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                    ),
                    label: const Text(
                      "عرض الموقع",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedLineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    " :طريقك للوصول الي ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('وقت الوصول الي وجهتك: $arrivalTime'),
                      Text('وقت المغادرة: $departureTime'),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('المسافه الكليه: $distance'),
                      Text('الوقت الكلي : $duration'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: data['routes'][0]['legs'].length,
                  itemBuilder: (BuildContext context, int index) {
                    final leg = data['routes'][0]['legs'][index];
                    final startAddress = leg['start_address'] ?? '';
                    final endAddress = leg['end_address'] ?? '';
                    final steps = leg['steps'];

                    return Column(
                      children: List.generate(steps.length, (index) {
                        final step = steps[index];
                        final lineDetails = step['transit_details'];
                        final lineName = lineDetails != null
                            ? lineDetails['line']['name']
                            : 'Unknown';
                        final instructions =
                            _stripHtmlIfNeeded(step['html_instructions'] ?? '');
                        final duration = step['duration']['text'] ?? '';
                        final distance = step['distance']['text'] ?? '';

                        List<Widget> subInstructionsWidgets = [];

                        if (step.containsKey('steps')) {
                          final subSteps =
                              step['steps'] as List<dynamic>;
                          for (final subStep in subSteps) {
                            final subInstructions =
                                _stripHtmlIfNeeded(subStep['html_instructions'] ?? '');
                            subInstructionsWidgets.add(
                              Text(subInstructions),
                            );
                          }
                        }

                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                _getTransportIcon(step),
                                color: Colors.blue,
                              ),
                              title: Text(' $instructions'),
                              subtitle: Column(
                                children: [
                                  Column(children: subInstructionsWidgets),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text('الوقت: $duration'),
                                      Text('المسافه: $distance'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  } else {}
}

IconData _getTransportIcon(Map<String, dynamic> step) {
  if (step.containsKey('transit_details')) {
    final transitDetails = step['transit_details'];
    final vehicleType = transitDetails['line']['vehicle']['type'];

    switch (vehicleType) {
      case 'BUS':
        return Icons.directions_bus;
      case 'WALKING':
        return Icons.directions_walk;
      case 'RAIL':
        return Icons.train;
      default:
        return Icons.directions;
    }
  } else {
    return Icons.directions;
  }
}

String _stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
}


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: const Text("تفاصيل الذهاب الى وجهتك"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.end,
                    cursorColor: Colors.blue,
                    controller: addNameController,
                    onChanged: (value) {
                      setState(() {
                        isSearching = true;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "ابحث عن وجهتك",
                      hintStyle: TextStyle(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
            Expanded(
              child: dataLoaded
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: lineAvailableMap.length,
                      itemBuilder: (BuildContext context, int index) {
                        final MapEntry<String, List<QueryDocumentSnapshot>>
                            entry = lineAvailableMap.entries.elementAt(index);
                        final stationId = entry.key;
                        final List<QueryDocumentSnapshot> lineAvailable =
                            entry.value;

                        final stationName = stationNameMap[stationId] ?? '';

                        final filteredLines = lineAvailable
                            .where((line) => line['nameLine']
                                .toString()
                                .contains(addNameController.text.trim()))
                            .toList();

                        final hasSearchResults = filteredLines.isNotEmpty;

                        final hasLines = lineAvailable.isNotEmpty;

                        if (!hasLines) {
                          return const SizedBox();
                        }

                        if (hasSearchResults) {
                          return ExpansionTile(
                            iconColor: Colors.blue,
                            title: Text("موقف $stationName"),
                            initiallyExpanded:
                                expansionTileState[stationId] ?? false,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                expansionTileState[stationId] = expanded;
                              });
                            },
                            children: [
                              Column(
                                children: filteredLines
                                    .map((line) => ListTile(
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("خط ${line['nameLine']}"),
                                              const Text("اضغط للتفاصيل")
                                            ],
                                          ),
                                          subtitle: Text(
                                              "سعر الخط: ${line['priceLine']}"),
                                          onTap: () {
                                            _getPublicTransportForStation(
                                                stationId, line['nameLine']);
                                          },
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(
                                height: 30,
                              )
                            ],
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    )
                  : const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: Colors.blue,
                          ),
                          Text(
                              "انتظر قليلا جار ترتيب المواقف من حيث الاقرب لك..."),
                        ],
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
