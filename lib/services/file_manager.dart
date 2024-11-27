import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/permission_helper.dart';

class FileManager {
  static late Directory designatedDirectory;

  static Future<void> initializeDesignatedDirectory() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    designatedDirectory = Directory("${appDocDir.path}/MCQFiles");
    if (!await designatedDirectory.exists()) await designatedDirectory.create(recursive: true);
  }

  static Future<void> moveFileToDesignatedDirectory(BuildContext context) async {
    await PermissionHelper.requestStoragePermission(context);

    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result == null) return;

    String sourcePath = result.files.single.path!;
    String fileName = result.files.single.name;

    File sourceFile = File(sourcePath);
    String destinationPath = "${designatedDirectory.path}/$fileName";

    await sourceFile.copy(destinationPath);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File moved successfully!")));
  }

  static Future<Uint8List> getFirstExcelFileBytes() async {
    List<FileSystemEntity> files = designatedDirectory.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith(".xlsx")) {
        return file.readAsBytes();
      }
    }
    throw Exception("No Excel file found.");
  }
}
