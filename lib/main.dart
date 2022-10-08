import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show json;
import 'package:file_selector/file_selector.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/gestures.dart';

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
  List<Polyline> inputLine = [];
  List<Marker> inputMarker = [];
  final controller = TextEditingController();
  var position = const Offset(400, 0);

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

  void clear(){
    setState(() {
      data = "";
      dots = [];
      markers = [];
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

  void input() async{
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'json',
      extensions: ['json'],
    );
    final XFile? file =
    await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      return;
    }
    final String fileContent = await file.readAsString();
    Map<String, dynamic> inputJson = jsonDecode(fileContent);

    controller.text = fileContent.toString();

    int comSize = inputJson['component'].length;
    for(int com = 0; com < comSize; com++){
      int dotSize = inputJson['component'][com]['dot'].length;
      List<LatLng> buf = [];
      for(int dot = 0; dot < dotSize; dot++){
        buf.add(LatLng(inputJson['component'][com]['dot'][dot]['latitude'], inputJson['component'][com]['dot'][dot]['longitude']));
      }
      inputLine.add(Polyline(points: buf, color: Colors.blue, strokeWidth: 12.0,));
      inputMarker.add(Marker(
        point: buf[0],
        width: 200,
        height: 80,
        builder: (ctx) => Column(children :[
          Icon(Icons.flag, size: 50, color: Colors.black,),
          Container(child: Text(inputJson['component'][com]['index'].toString() + "_start"), color: Colors.white.withOpacity(0.5),)
        ]),
      ));
      inputMarker.add(Marker(
        point: buf[dotSize -1],
        width: 200,
        height: 80,
          builder: (ctx) => Column(children :[
            Icon(Icons.flag, size: 50, color: Colors.black,),
            Container(child: Text(inputJson['component'][com]['index'].toString() + "_end"), color: Colors.white.withOpacity(0.5),)
          ])
      ));
      setState(() {
      });
    }
  }

  void init(){
    output(data);
    setState(() {
      data = "";
      dots = [];
      markers = [];
    });
  }

  void undo(){
    print("---------------------");
    int numOfRemain = 0;
    int length = data.length;
    for(int i = 1; i < length; i++){
      if(data[length - i] == "," && data[length - (i + 1)] == "}") {numOfRemain = length - i; break;}
    }
    data = data.substring(0, numOfRemain);
    dots.removeLast();
    markers.removeLast();
    print(data);
    setState(() {

    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                print('{\n    \"longitude\":${tapPosition.longitude},\n    \"latitude"\:${tapPosition.latitude},\n    \"altitude"\:${altitude}\n},');
                if(data == ''){
                  data += '{\n    \"longitude\":${tapPosition.longitude},\n    \"latitude"\:${tapPosition.latitude},\n    \"altitude"\:${altitude}\n}';
                }else{
                  data += ',\n{\n    \"longitude\":${tapPosition.longitude},\n    \"latitude"\:${tapPosition.latitude},\n    \"altitude"\:${altitude}\n}';
                }
              });
            }
            ),
            layers: [
              TileLayerOptions(
                urlTemplate: "https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              TileLayerOptions(
                urlTemplate: "https://cyberjapandata.gsi.go.jp/xyz/hillshademap/{z}/{x}/{y}.png",
                opacity : 0.5,
              ),
              PolylineLayerOptions(
                polylineCulling: false,
                polylines: [
                  Polyline(
                  points: dots,
                  color: Colors.lightBlueAccent,
                  strokeWidth: 12.0,
                  ),
                ],
              ),
              PolylineLayerOptions(
                polylineCulling:  false,
                polylines: inputLine,
              ),
              CircleLayerOptions(
                circles: markers,
              ),
              MarkerLayerOptions(
                markers: inputMarker,
              ),
            ],
          ),
          Column(children: [
            FloatingActionButton(onPressed: init, child: Icon(Icons.file_download),),
            FloatingActionButton(onPressed: () async {
                int? num = await showDialog<int>(context: context, builder:(_) {return checkDelete();});
                if(num == 0) clear();
              },
              child: Icon(Icons.delete),
            ),
            FloatingActionButton(onPressed: input, child: Icon(Icons.input),),
            FloatingActionButton(onPressed: undo, child: Icon(Icons.undo),)
            ],
          ),
        ],
      )
    );
  }
}



class checkDelete extends StatelessWidget {
  const checkDelete({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("道を削除します"),
      content: Text("この作業は取り消すことができません"),
      actions: [
        GestureDetector(
          child: Icon(Icons.cancel_outlined),
          onTap: () {Navigator.pop(context, -1);},
        ),
        GestureDetector(
          child: Icon(Icons.delete),
          onTap: () {Navigator.pop(context, 0);},
        )
      ],
    );
  }
}