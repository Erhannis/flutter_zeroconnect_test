import 'package:zeroconnect/zeroconnect.dart';
import 'package:nsd/nsd.dart';

Future<void> serverTest() async {
  disableServiceTypeValidation(true);
  await ZeroConnect().advertise(serviceId: "YOUR_SERVICE_ID_HERE", callback: (messageSock, nodeId, serviceId) async {
    print("got message connection from $nodeId");
    var str = await messageSock.recvString();
    print(str);
    await messageSock.sendString("Hello from server");
  });
}

Future<void> clientTest() async {
  var messageSock = await ZeroConnect().connectToFirst(serviceId: "YOUR_SERVICE_ID_HERE");
  await messageSock?.sendString("Test message");
  var str = await messageSock?.recvBytes();
  print(str);
}