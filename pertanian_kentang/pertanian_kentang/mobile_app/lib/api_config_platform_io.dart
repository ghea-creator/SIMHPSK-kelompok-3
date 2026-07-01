import 'dart:io';

String get platformServerIp {
  if (Platform.isIOS) {
    return '127.0.0.1';
  }
  return '10.0.2.2';
}
