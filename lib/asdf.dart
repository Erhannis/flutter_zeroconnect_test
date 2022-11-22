import 'package:flutter/widgets.dart';
import 'package:zeroconnect/misc.dart';
import 'package:zeroconnect/zeroconnect.dart';
import 'package:nsd/nsd.dart';

const SERVICE_ID = "YOURSERVICEID";

Future<void> serverTest() async {
  WidgetsFlutterBinding.ensureInitialized(); // This is not needed if the usual `runApp` has already been called
  var zc = ZeroConnect(localId: "SERVER_ID");
  await zc.advertise(serviceId: SERVICE_ID, callback: (messageSock, nodeId, serviceId) async {
    print("got message connection from $nodeId");
    // If you also want to spontaneously send messages, pass the socket to e.g. another thread.
    while (true) {
      var str = await messageSock.recvString();
      print("$str");
      switch (str) {
        case "enable jimjabber":
          print("ENABLE JIMJABBER");
          break;
        case "save msg:":
          var toSave = await messageSock.recvBytes();
          print("SAVE MESSAGE $toSave");
          break;
        case "marco":
          await messageSock.sendString("polo");
          print("PING PONGED");
          break;
        case null:
          print("Connection closed from $nodeId");
          await messageSock.close();
          return;
        default:
          print("Unhandled message: $str");
          break;
      }
      // Use messageSock.sock for e.g. sock.remoteAddress
      // I recommend messageSock.close() after you're done with it - but it'll get closed on zc.close(), at least
    }
  });
  // You may call zc.close(), when you want to shut down existing stuff
}

Future<void> clientTest() async {
  var zc = ZeroConnect(localId: "CLIENT_ID"); // Technically the nodeId is optional; it'll assign you a random UUID

  var ads = await zc.scan(serviceId: SERVICE_ID, time: const Duration(seconds: 5));
  // OR: var ads = await zc.scan(serviceId: SERVICE_ID, nodeId: NODE_ID);
  // An `Ad` contains a `serviceId` and `nodeId` etc.; see `Ad` for details
  var messageSock = await zc.connect(ads.first); // See also (ZeroConnect).connectRaw
  // OR: var messageSock = await zc.connectToFirst(serviceId: SERVICE_ID);
  // OR: var messageSock = await zc.connectToFirst(serviceId: SERVICE_ID, nodeId: NODE_ID, time: const Duration(seconds: 10));
  // Perhaps one day you will be able to specify a nodeId alone, but I had some problems when doing that I haven't fixed, yet.

  await messageSock?.sendString("enable jimjabber");
  await messageSock?.sendString("save msg:");
  await messageSock?.sendString("i love you");
  await messageSock?.sendString("marco");
  print("rx: ${await messageSock?.recvString()}");

  await sleep(30000); // ...

  await zc.close();
}