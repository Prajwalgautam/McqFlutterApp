import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<void> requestStoragePermission(BuildContext context) async {
    PermissionStatus status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Storage permission is required!")));
    }
  }
}
