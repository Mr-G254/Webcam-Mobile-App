import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';

abstract class Comms{
  static List<UsbDevice> devices = [];
  static late Function statusUpdate;

  static void initialize(Function() onChange)async{
    statusUpdate = onChange;
    identifyConnectedDevices();
    listenToUsbEvents();
  }

  static Future<void> identifyConnectedDevices()async{
    List<UsbDevice> devices = await UsbSerial.listDevices();

    for(final i in devices){
      connectToDevices(i);
    }
  }

  static Future<void> connectToDevices(UsbDevice device)async{
    UsbPort? port = await device.create();
    if(await port!.open()) {
      port.setDTR(true);
      port.setRTS(true);

      await port.write(Uint8List.fromList("Webcam_Desktop@Mrg".codeUnits));
      port.inputStream!.listen((data) {
        String message = String.fromCharCodes(data);
        if (message == "Connection_Accepted@Mrg") {
          Comms.devices.add(device);
          statusUpdate();

        }

        port.close();
      });
    }
  }

  static Future<void> listenToUsbEvents()async{
    UsbSerial.usbEventStream!.listen((UsbEvent event){
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        if(event.device != null){
          connectToDevices(event.device!);
        }

      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        devices.remove(event.device);
        statusUpdate();
      }

    });
  }
}