import 'dart:typed_data';
import 'package:excel/excel.dart' as excel;

class ExcelParser {
  static List<Map<String, dynamic>> parseExcelFile(Uint8List bytes) {
    var excelData = excel.Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> questions = [];

    for (var table in excelData.tables.keys) {
      var sheet = excelData.tables[table];
      if (sheet != null) {
        for (var i = 1; i < sheet.rows.length; i++) {
          var row = sheet.rows[i];
          questions.add({
            'question': row[0]?.value?.toString() ?? '',
            'options': [
              row[1]?.value?.toString() ?? '',
              row[2]?.value?.toString() ?? '',
              row[3]?.value?.toString() ?? '',
              row[4]?.value?.toString() ?? '',
            ],
            'answerIndex': int.tryParse(row[5]?.value?.toString() ?? '1')! - 1,
          });
        }
      }
    }
    return questions;
  }
}
