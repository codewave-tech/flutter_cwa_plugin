import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:cw_core/cw_core.dart';
import 'package:cwa_plugin_core/cwa_plugin_core.dart';

class ArchBuddyConnect extends Command {
  ArchBuddyConnect(super.args);

  Map<String, bool> connectionInitiators = {};
  Map<String, Socket> socketMap = {};
  Socket? establishedConnection;

  @override
  Future<void> run() async {
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    for (final NetworkInterface interface in interfaces) {
      print('Interface: ${interface.name}');
      for (final InternetAddress addr in interface.addresses) {
        print('Address: ${addr.address}');
      }
    }

    CWLogger.inLinePrint('Enter a port number : ');
    String? portStr = stdin.readLineSync();
    int? port = int.tryParse(portStr ?? "");

    if (port == null || port > 65535) {
      CWLogger.namedLog(
        "Invalid Port specified.",
        loggerColor: CWLoggerColor.red,
      );
      exit(2);
    }

    String localIP = interfaces.first.addresses.first.address;
    ServerSocket server = await ServerSocket.bind(localIP, port);
    String id = generateIdentifier();

    CWLogger.namedLog('IP Address : $localIP',
        loggerColor: CWLoggerColor.yellow);
    CWLogger.namedLog('Port : $port', loggerColor: CWLoggerColor.yellow);
    CWLogger.namedLog('Identifier : $id', loggerColor: CWLoggerColor.yellow);

    await for (Socket socket in server) {
      socket.listen(
        (Uint8List event) async {
          String data = String.fromCharCodes(event);

          CodeScoutComms codeScoutComms;
          try {
            codeScoutComms = CodeScoutComms.fromJson(data);
          } catch (e) {
            if (e is FormatException) {
              CWLogger.namedLog(
                "Format Execption : Data wasn't received properly from the app",
                loggerColor: CWLoggerColor.red,
              );
              return;
            }
            CWLogger.namedLog(
              'Invalid Comms, please follow the protocol.',
              loggerColor: CWLoggerColor.red,
            );

            exit(2);
          }
          if (codeScoutComms.command == CodeScoutCommands.communication) {
            print(utf8.decode(List<int>.from(codeScoutComms.data['output'])));
            return;
          }

          if (codeScoutComms.command == CodeScoutCommands.establishConnection) {
            _establishConnection(socket, codeScoutComms, id);
            return;
          }
        },
        onError: (error) {
          CWLogger.namedLog(
            "Error: $error",
            loggerColor: CWLoggerColor.red,
          );
        },
        onDone: () {
          CWLogger.namedLog(
            "Closing connection",
            loggerColor: CWLoggerColor.green,
          );
          server.close();
          exit(0);
        },
        cancelOnError: true,
      );
    }
  }

  void _establishConnection(Socket socket, CodeScoutComms comms, String id) {
    String ipStr = socket.remoteAddress.address;
    CWLogger.namedLog('Connection request from $ipStr');

    if (establishedConnection != null) {
      rejectConnection(socket, ipStr);
      return;
    }

    _authenticate(comms, id, ipStr, socket);
  }

  void _authenticate(
      CodeScoutComms comms, String id, String ipStr, Socket socket) async {
    if (establishedConnection != null) {
      rejectConnection(socket, ipStr);
      return;
    }

    if (comms.data[CodeScoutPayloadType.identifier] == id) {
      connectionInitiators[ipStr] = true;
      establishedConnection = socket;
      CWLogger.namedLog(
        "Connection established!!",
        loggerColor: CWLoggerColor.green,
      );

      socket.write(
        CodeScoutComms(
          command: CodeScoutCommands.connectionApproved,
          payloadType: CodeScoutPayloadType.identifier,
          data: {},
        ),
      );

      notifyOtherSockets();
    } else {
      CWLogger.namedLog(
        "Invalid identifier from $ipStr",
        loggerColor: CWLoggerColor.red,
      );
      socket.write(
        CodeScoutComms(
          command: CodeScoutCommands.breakConnection,
          payloadType: CodeScoutPayloadType.identifier,
          data: {},
        ),
      );
      await socket.flush();
      await socket.close();
    }
  }

  void rejectConnection(Socket socket, String ipStr) {
    if (connectionInitiators.containsKey(ipStr) &&
        connectionInitiators[ipStr]!) {
      return;
    }

    CWLogger.namedLog(
      'Refused connection from $ipStr, already connected to another client',
      loggerColor: CWLoggerColor.red,
    );
    socket.write('Only one connection allowed at a time!');
    socket.close();
  }

  void notifyOtherSockets() {
    socketMap.forEach((key, value) {
      if (!connectionInitiators[key]!) {
        value.write('Only one connection allowed at a time!');
        value.close();
      }
    });
  }

  String generateIdentifier() {
    final random = math.Random();
    return List.generate(5, (_) => random.nextInt(10).toString()).join('');
  }
}
