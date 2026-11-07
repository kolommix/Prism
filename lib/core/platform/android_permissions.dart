import 'dart:io';

import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

/// Android runtime permissions. Only the Android plugin is linked on purpose:
/// on Windows there is nothing to ask for, and these all answer "yes" without
/// touching a plugin.
class AndroidPermissions {
  const AndroidPermissions._();

  static Future<bool> _request(Permission p) async {
    final result = await PermissionHandlerPlatform.instance.requestPermissions([p]);
    return result[p]?.isGranted ?? false;
  }

  /// READ_MEDIA_AUDIO on Android 13+, READ_EXTERNAL_STORAGE before that.
  static Future<bool> requestAudioFiles() async {
    if (!Platform.isAndroid) return true;
    if (await _request(Permission.audio)) return true;
    // Older Android versions report `audio` as denied/unsupported.
    return _request(Permission.storage);
  }

  /// RECORD_AUDIO, which Android needs for its Visualizer API.
  static Future<bool> hasMicrophone() async {
    if (!Platform.isAndroid) return true;
    return (await PermissionHandlerPlatform.instance.checkPermissionStatus(Permission.microphone)).isGranted;
  }

  static Future<bool> requestMicrophone() async {
    if (!Platform.isAndroid) return true;
    return _request(Permission.microphone);
  }

  static Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    await PermissionHandlerPlatform.instance.openAppSettings();
  }
}
