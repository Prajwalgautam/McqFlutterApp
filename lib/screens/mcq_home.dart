import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart'; // For getting app directory
import 'package:excel/excel.dart'; // For reading Excel files

class MCQHomePage extends StatefulWidget {
  @override
  _MCQHomePageState createState() => _MCQHomePageState();
}

class _MCQHomePageState extends State<MCQHomePage> {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = false;
  int currentQuestionIndex = 0;
  bool isSubmitted = false;
  String? selectedAnswer;
  int score = 0;

  // Path to the designated directory for storing files
  late Directory designatedDirectory;

  @override
  void initState() {
    super.initState();
    _getDesignatedDirectory();
  }

  // Getting app directory for storing questions file
  Future<void> _getDesignatedDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    designatedDirectory = Directory('${directory.path}/questions');
    if (!await designatedDirectory.exists()) {
      await designatedDirectory.create();
    }

    // Load questions immediately if a file already exists in the directory
    await loadQuestionsFromDesignatedDirectory();
  }

  // Requesting storage permission (if required)
  Future<void> requestStoragePermission() async {
    // Implement permission request code here if targeting Android 6.0+ or iOS
  }

  // Function to move the selected file to the designated directory
  Future<void> moveFileToDesignatedDirectory() async {
    try {
      await requestStoragePermission();  // Request permission before picking a file

      // Pick the file using the FilePicker plugin
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],  // Ensure only Excel files can be picked
      );

      if (result == null || result.files.isEmpty) {
        return; // Exit if no file was picked
      }

      // Get the path of the picked file
      String sourcePath = result.files.single.path!;
      String fileName = result.files.single.name;

      File sourceFile = File(sourcePath);
      String destinationPath = "${designatedDirectory.path}/$fileName";

      // Move the file to the designated directory
      await sourceFile.copy(destinationPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File moved to designated folder successfully!")),
      );

      // Load questions from the newly moved file
      await loadQuestionsFromDesignatedDirectory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error moving file: $e")),
      );
    }
  }

  // Function to load questions from the designated folder
  Future<void> loadQuestionsFromDesignatedDirectory() async {
    try {
      setState(() {
        isLoading = true;
      });

      List<FileSystemEntity> files = designatedDirectory.listSync();
      File? selectedFile;

      for (var file in files) {
        if (file is File && file.path.endsWith(".xlsx")) {
          selectedFile = file;
          break; // Load the first found .xlsx file
        }
      }

      if (selectedFile == null) {
        throw Exception("No valid .xlsx file found in the designated folder.");
      }

      Uint8List fileBytes = await selectedFile.readAsBytes();

      // Parse the Excel file
      var excel = Excel.decodeBytes(fileBytes);
      List<Map<String, dynamic>> loadedQuestions = [];

      for (var table in excel.tables.keys) {
        var rows = excel.tables[table]?.rows;
        for (var row in rows!) {
          // Assuming row[0] is the question, row[1] to row[4] are the options
          String correctOption = row[5].toString(); // Get the correct option index as a string
          int correctOptionIndex = int.tryParse(correctOption) ?? -1;

          loadedQuestions.add({
            "question": row[0],
            "options": [row[1], row[2], row[3], row[4]], // Answer options
            "correctAnswerIndex": correctOptionIndex, // Correct answer index (0-3)
          });
        }
      }

      setState(() {
        questions = loadedQuestions;
        currentQuestionIndex = 0;
        isSubmitted = false;
        selectedAnswer = null;
        score = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Questions loaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading questions: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to show error dialogs
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Software MCQ"),
        actions: [
          // File Picker Icon (for opening the Excel file)
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: moveFileToDesignatedDirectory, // Moves the file to designated folder
          ),
          // Refresh Icon (for refreshing the questions from the file)
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadQuestionsFromDesignatedDirectory, // Refreshes the questions
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : questions.isEmpty
          ? Center(child: Text("No questions loaded."))
          : ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          var question = questions[index];
          return ListTile(
            title: Text(question['question']),
            subtitle: Column(
              children: [
                for (var option in question['options']) Text(option),
              ],
            ),
          );
        },
      ),
    );
  }
}
