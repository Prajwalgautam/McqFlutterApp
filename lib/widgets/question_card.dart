import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final bool isSubmitted;
  final String? selectedAnswer;
  final Function(String)? onAnswerSelected;
  final VoidCallback? onSubmit;
  final VoidCallback? onNext;
  final bool isLastQuestion;
  final int score;
  final int totalQuestions;

  QuestionCard({
    required this.question,
    required this.isSubmitted,
    this.selectedAnswer,
    this.onAnswerSelected,
    this.onSubmit,
    this.onNext,
    required this.isLastQuestion,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Q: ${question['question']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...question['options'].asMap().entries.map((entry) {
          int index = entry.key;
          String option = entry.value;

          Color optionColor = Colors.white;
          if (isSubmitted) {
            if (index == question['answerIndex']) {
              optionColor = Colors.green;
            } else if (option == selectedAnswer) {
              optionColor = Colors.red;
            }
          } else if (option == selectedAnswer) {
            optionColor = Colors.blue.shade100;
          }

          return GestureDetector(
            onTap: isSubmitted ? null : () => onAnswerSelected?.call(option),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: optionColor,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(option, style: TextStyle(fontSize: 16)),
            ),
          );
        }).toList(),
        if (isSubmitted && onNext != null)
          ElevatedButton(onPressed: onNext, child: Text(isLastQuestion ? "Finish" : "Next")),
        if (!isSubmitted)
          ElevatedButton(onPressed: selectedAnswer != null ? onSubmit : null, child: Text("Submit")),
      ],
    );
  }
}
