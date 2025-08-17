import 'package:flutter/material.dart';

class CategoryModel {
  String name;
  String iconPath;
  Color boxColor;

  CategoryModel({
    required this.name,
    required this.iconPath,
    required this.boxColor,
  });

  /// Factory to map subject string → category design
  factory CategoryModel.fromSubject(String subject) {
    switch (subject.toLowerCase()) {
      case "java":
        return CategoryModel(
          name: "Java",
          iconPath: "assets/icons/java.svg",
          boxColor: const Color(0xff9DCEFF),
        );
      case "geography":
        return CategoryModel(
          name: "Geography",
          iconPath: "assets/icons/planet-earth.svg",
          boxColor: const Color(0xffEEA4CE),
        );
      case "aptitude":
        return CategoryModel(
          name: "Aptitude",
          iconPath: "assets/icons/mind-smart-light-bulb.svg",
          boxColor: const Color(0xff9DCEFF),
        );
      case "biology":
        return CategoryModel(
          name: "Biology",
          iconPath: "assets/icons/biology.svg", // add correct icon
          boxColor: const Color(0xffEEA4CE),
        );
      case "history":
        return CategoryModel(
          name: "History",
          iconPath: "assets/icons/history.svg", // add correct icon
          boxColor: const Color(0xff9DCEFF),
        );
      case "vocabulary":
        return CategoryModel(
          name: "Vocabulary",
          iconPath: "assets/icons/vocabulary.svg", // add correct icon
          boxColor: const Color(0xffEEA4CE),
        );
      default:
        return CategoryModel(
          name: subject,
          iconPath: "assets/icons/default.svg",
          boxColor: Colors.grey,
        );
    }
  }
}
