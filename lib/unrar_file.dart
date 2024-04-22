import 'dart:async';
import 'package:unrar_file/src/rarFile.dart';
import 'package:unrar_file/src/rar_decoder.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

class UnrarFile {
  static const MethodChannel _channel = const MethodChannel('unrar_file');

  static Future<String?> extract_rar(file_path, destination_path, {password = ""}) async {
    try {
      var result = await _channel.invokeMethod('extractRAR',
          {"file_path": file_path, "destination_path": destination_path, "password": password});
      return result;
    } on PlatformException catch (e) {
      if (e.code == "extractionRAR5Error") {
        try {
          var rar_file = RAR5(file_path);
          var files = rar_file.files;
          for (RarFile file in files) {
            var file_to_save = File(join(destination_path, file.name));
            file_to_save.writeAsBytesSync(file.content!);
          }
          return "Extraction Success";
        } catch (e) {
          throw e.toString();
        }
      } else {
        throw e.message!;
      }
    }
  }

  static Future<List<String>?> listFiles(String filePath) async {
    try {
      List result = await _channel.invokeMethod('listFiles', {"file_path": filePath});
      print("fuck rar");
      print(result);
      List<String> list = result.map((e) => e.toString()).toList();
      return list;
    } on PlatformException catch (e) {
      throw e.message!;
    }
  }
}
