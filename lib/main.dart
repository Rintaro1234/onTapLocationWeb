import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show json;
import 'package:file_selector/file_selector.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<double> getAltitude(double lat, double long) async{
  double altitude = 0.0;
  Uri url = Uri.parse('https://cyberjapandata2.gsi.go.jp/general/dem/scripts/getelevation.php?lon=${long}&lat=${lat}&outtype=JSON');
  final response = await http.get(url);
  Map<String, dynamic> data = json.decode(response.body);
  altitude = data['elevation'];
  return altitude;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const showMap(),
    );
  }
}

class showMap extends StatefulWidget {
  const showMap({Key? key}) : super(key: key);

  @override
  State<showMap> createState() => _showMap();
}

class _showMap extends State<showMap> {

  double _latitude=34.007705434617, _longitude=134.49272864666574;

  List<LatLng> dots = [];
  String data = "";
  List<CircleMarker> markers = [];

  @override
  void initState() {
    super.initState();
  }

  void onTap(double latitude, double longitude){
    setState(() {
      dots.add(LatLng(latitude, longitude));
      markers.add(CircleMarker(
          color: Colors.lightBlue.withOpacity(0.5),
          point: LatLng(latitude, longitude),
          radius: 10
      ));
    });
  }

  void output(String out) async{
    out='{\n "component": [\n{\n"dot":[\n' + out + ']\n}\n]\n}';
    String? path = await getSavePath(acceptedTypeGroups: [
      XTypeGroup(label: 'txt', extensions: ['txt'])
    ], suggestedName: "road.txt");
    if (path == "") { // 空文字の場合、AnchorElementでDLリンクを作成 → 発火
      final anchor = html.AnchorElement(
          href: "data:application/json;charset=utf-8," +
              out);
      anchor.download = "road.json";
      anchor.click();
    }
  }

  void init(){
    output(data);
    data = "";
    dots = [];
    markers = [];
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new Stack(
        children: <Widget>[
          FlutterMap(
            options: MapOptions(
            center: LatLng(_latitude,_longitude),
            minZoom: 1,
            maxZoom: 18,
            onTap: (polyline, tapPosition){
              double altitude;
              onTap(tapPosition.latitude, tapPosition.longitude);
              getAltitude(tapPosition.latitude, tapPosition.longitude).then((value)
              {
                altitude = value;
                print('{\n\"longitude\":${tapPosition.longitude},\n\"latitude"\:${tapPosition.latitude},\n\"altitude"\:${altitude}\n},');
                if(data == ''){
                  data += '{\n\"longitude\":${tapPosition.longitude},\n\"latitude"\:${tapPosition.latitude},\n\"altitude"\:${altitude}\n}';
                }else{
                  data += ',\n{\n\"longitude\":${tapPosition.longitude},\n\"latitude"\:${tapPosition.latitude},\n\"altitude"\:${altitude}\n}';
                }
              });
            }
            ),
            layers: [
              TileLayerOptions(
                urlTemplate: "https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              CircleLayerOptions(
                circles: markers,
              ),
              PolylineLayerOptions(
                polylineCulling: false,
                polylines: [
                  Polyline(
                  points: dots,
                  color: Colors.blue,
                  strokeWidth: 3.0,
                  ),
                ],
              )
            ],
          ),
          FloatingActionButton(onPressed: init),
        ]
      )
    );
  }
}