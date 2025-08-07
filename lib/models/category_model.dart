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

  static List<CategoryModel> getCategories() {
    List<CategoryModel> categories = [];

    categories.add(
      CategoryModel(
        name: 'Java',
        iconPath: 'assets/icons/java.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Geography',
        iconPath: 'assets/icons/planet-earth.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Aptitude',
        iconPath: 'assets/icons/mind-smart-light-bulb.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Biology',
        iconPath: 'assets/icons/java.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'History',
        iconPath: 'assets/icons/java.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Vocabulary',
        iconPath: 'assets/icons/java.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    return categories;
  }
}
