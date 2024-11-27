import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(SoftwareMCQApp());
}

class SoftwareMCQApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
      home: MCQHomePage(),
    );
  }
}

class MCQHomePage extends StatefulWidget {
  @override
  _MCQHomePageState createState() => _MCQHomePageState();
}

class _MCQHomePageState extends State<MCQHomePage> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  bool isSubmitted = false;
  String? selectedAnswer;
  int score = 0;
  bool isLoading = false;
  late Directory designatedDirectory;
  List<String> fileHistory = []; // Store file history
  String? currentFile; // Current selected file

  @override
  void initState() {
    super.initState();
    _initializeDesignatedDirectory();
  }

  Future<void> _initializeDesignatedDirectory() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    designatedDirectory = Directory("${appDocDir.path}/MCQFiles");

    if (!(await designatedDirectory.exists())) {
      await designatedDirectory.create(recursive: true);
    }
  }

  Future<void> moveFileToDesignatedDirectory() async {
    try {
      await requestStoragePermission();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        showErrorDialog(context, "No file selected.");
        return;
      }

      String sourcePath = result.files.single.path!;
      String fileName = result.files.single.name;

      File sourceFile = File(sourcePath);
      String destinationPath = "${designatedDirectory.path}/$fileName";

      await sourceFile.copy(destinationPath);

      // Add file to history
      setState(() {
        fileHistory.add(fileName);
        currentFile = fileName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File moved to designated folder successfully!")),
      );
    } catch (e) {
      showErrorDialog(context, "Error moving file: $e");
    }
  }

  Future<void> loadQuestionsFromSelectedFile() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get list of files in the designated directory
      List<FileSystemEntity> files = designatedDirectory.listSync();
      File? selectedFile;

      // Let the user choose the file
      if (currentFile != null) {
        selectedFile = File("${designatedDirectory.path}/$currentFile");
      }

      if (selectedFile == null || !selectedFile.existsSync()) {
        throw Exception("No valid .xlsx file found in the designated folder.");
      }

      Uint8List fileBytes = await selectedFile.readAsBytes();

      // Parse the Excel file
      var excelData = parseExcelFile(fileBytes);

      // Shuffle the questions list
      excelData.shuffle();

      setState(() {
        questions = excelData;
        currentQuestionIndex = 0;
        isSubmitted = false;
        selectedAnswer = null;
        score = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Questions loaded and shuffled successfully!")),
      );
    } catch (e) {
      showErrorDialog(context, "Error loading questions: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> parseExcelFile(Uint8List bytes) {
    var excelData = excel.Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> questions = [];

    if (excelData != null) {
      for (var table in excelData.tables.keys) {
        var sheet = excelData.tables[table];
        if (sheet != null) {
          for (var i = 1; i < sheet.rows.length; i++) {
            var row = sheet.rows[i];
            if (row.length >= 6) {
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
      }
    }

    return questions;
  }

  Future<void> requestStoragePermission() async {
    PermissionStatus status;

    if (Platform.isAndroid || Platform.isIOS) {
      status = await Permission.storage.request();
    } else {
      return;
    }

    if (status.isDenied) {
      showErrorDialog(context, "Storage permission denied.");
      return;
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void submitAnswer() {
    setState(() {
      isSubmitted = true;
      if (selectedAnswer == questions[currentQuestionIndex]['options'][questions[currentQuestionIndex]['answerIndex']]) {
        score++;
      }
    });
  }

  void nextQuestion() {
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        isSubmitted = false;
        selectedAnswer = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Software MCQ"),
        actions: [
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: moveFileToDesignatedDirectory,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadQuestionsFromSelectedFile,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text('File History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ...fileHistory.map((file) {
              return ListTile(
                title: Text(file),
                onTap: () {
                  setState(() {
                    currentFile = file;
                    loadQuestionsFromSelectedFile();
                    Navigator.pop(context); // Close the drawer after selection
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : questions.isEmpty
          ? Center(
        child: Text(
          "No Questions Loaded. Move files to the designated folder and refresh.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Score: $score",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Question ${currentQuestionIndex + 1} of ${questions.length}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Remaining: ${questions.length - currentQuestionIndex - 1}",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Q: ${questions[currentQuestionIndex]['question']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...questions[currentQuestionIndex]['options'].map<Widget>((option) {
            bool isCorrect = option == questions[currentQuestionIndex]['options'][questions[currentQuestionIndex]['answerIndex']];
            bool isSelected = selectedAnswer == option;
            Color cardColor = isSubmitted
                ? (isCorrect ? Colors.green : (isSelected ? Colors.red : Colors.grey[300]!))
                : (isSelected ? Colors.blue : Colors.white);

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedAnswer = option;
                });
              },
              child: Card(
                color: cardColor,
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    option,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }).toList(),
          if (isSubmitted)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: nextQuestion,
                child: Text("Next Question"),
              ),
            ),
          if (!isSubmitted)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: submitAnswer,
                child: Text("Submit Answer"),
              ),
            ),
          if (currentQuestionIndex == questions.length - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Quiz Finished"),
                      content: Text("Your score is $score/${questions.length}"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                },
                child: Text("Finish Quiz"),
              ),
            ),
        ],
      ),
    );
  }
}
