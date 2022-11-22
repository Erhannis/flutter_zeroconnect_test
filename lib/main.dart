import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:cross_scroll/cross_scroll.dart';
import 'package:flutter/material.dart';
import 'package:zeroconnect/MessageSocket.dart';
import 'package:zeroconnect/misc.dart';
import 'package:zeroconnect/zeroconnect.dart';
import 'package:zeroconnect_test/asdf.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // serverTest();
  // await sleep(10000);
  // clientTest();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var zc = ZeroConnect();

  var localServiceId = "";

  var remoteServiceId = "";
  var remoteNodeId = "";

  var broadcastText = "";

  Map<MessageSocket, String> lastMsgs = {};

  @override
  void initState() {
    super.initState();
    Future(() async {
      while (true) {
        await sleep(1000);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(child: TextFormField(initialValue: "ID: ${zc.localId}", readOnly: true, onChanged: (value) => localServiceId = value)),
            Row(children: [
              Expanded(child: TextFormField(onChanged: (value) => localServiceId = value)),
              ElevatedButton(child: const Text("Advertise"), onPressed: () async {
                if (localServiceId.isNotEmpty) { //THINK Probably add some extra checks
                  await zc.advertise(serviceId: localServiceId, callback: (sock, nodeId, serviceId) async {
                    log("incoming connection: ($nodeId ; $serviceId)");
                    while (true) {
                      var msg = await sock.recvString();
                      lastMsgs[sock] = msg ?? "ERROR";
                      log("rx msg $msg");
                      if (msg == null) {
                        log("got null msg, returning from connection: ($nodeId ; $serviceId)");
                        return;
                      }
                    }
                  },);
                  setState(() {});
                }
              },),
            ],),
            const Text("Local ads:"),
            Container(decoration: BoxDecoration(border: Border.all(color: Colors.black)), child:
              SizedBox(height: 50, child: CrossScroll(child: Column(children: zc.localAds.map((e) => Text("$e")).toList()))),
            ),
            Row(children: [
              Expanded(child: TextFormField(onChanged: (value) => remoteServiceId = value)),
              Expanded(child: TextFormField(onChanged: (value) => remoteNodeId = value)),
              ElevatedButton(child: const Text("Scan"), onPressed: () async {
                String? rsi = null;
                if (remoteServiceId.isEmpty) {
                  log("need service id, for now");
                  return;
                } else {
                  rsi = remoteServiceId;
                }
                String? rni = null;
                if (remoteNodeId.isNotEmpty) {
                  rni = remoteNodeId;
                }
                await zc.scan(serviceId: rsi, nodeId: rni);
                setState(() {});
              },),
            ],),
            const Text("Remote ads:"),
            Container(decoration: BoxDecoration(border: Border.all(color: Colors.black)), child:
              SizedBox(height: 120, child: CrossScroll(child: Column(children:
                zc.remoteAds.values()
                  .fold(Set<Ad>(), (a, b) => a..addAll(b))
                  .map((e) =>
                    Row(children: [
                      Text("$e"),
                      ElevatedButton(child: Text("Connect"), onPressed: () async {
                        var sock = await zc.connect(e);
                        if (sock != null) {
                          unawaited(Future(() async {
                            log("outgone connection: (${e.nodeId} ; ${e.serviceId})");
                            while (true) {
                              var msg = await sock.recvString();
                              lastMsgs[sock] = msg ?? "ERROR";
                              log("rx msg $msg");
                              if (msg == null) {
                                log("got null msg, returning from connection: (${e.nodeId} ; ${e.serviceId})");
                                return;
                              }
                            }
                          }));
                        }
                        setState(() {});
                      },)
                    ]))
                  .toList()
              ))),
            ),
            Row(children: [
              Expanded(child: TextFormField(onChanged: (value) => broadcastText = value)),
              ElevatedButton(child: const Text("Broadcast"), onPressed: () async {
                await zc.broadcastString(broadcastText);
              },),
            ],),
            const Text("Outgone connections:"),
            Container(decoration: BoxDecoration(border: Border.all(color: Colors.black)), child:
              SizedBox(height: 120, child: CrossScroll(child: Column(children:
                zc.outgoneConnections.entries()
                  .fold(List<Pair<List<String>, MessageSocket>>.empty(growable: true), (a, b) => a..addAll(b.value.map((e) => Pair(b.key, e))))
                  .map((e) =>
                    Row(children: [
                      Text("$e ; ${lastMsgs[e.b]} [INPUT]"),
                      ElevatedButton(child: Text("Send"), onPressed: () async {
                        await e.b.sendString(broadcastText);
                        setState(() {});
                      },)
                    ]))
                  .toList()
              ))),
            ),
            const Text("Incame connections:"),
            Container(decoration: BoxDecoration(border: Border.all(color: Colors.black)), child:
              SizedBox(height: 120, child: CrossScroll(child: Column(children:
                zc.incameConnections.entries()
                  .fold(List<Pair<List<String>, MessageSocket>>.empty(growable: true), (a, b) => a..addAll(b.value.map((e) => Pair(b.key, e))))
                  .map((e) =>
                  Row(children: [
                    Text("$e ; ${lastMsgs[e.b]} [INPUT]"),
                    ElevatedButton(child: Text("Send"), onPressed: () async {
                      await e.b.sendString(broadcastText);
                      setState(() {});
                    },)
                  ]))
                  .toList()
              ))),
            ),
            ElevatedButton(child: const Text("Close"), onPressed: () async {
              await zc.close();
            },),
          ],
        ),
      ),
    );
  }
}
