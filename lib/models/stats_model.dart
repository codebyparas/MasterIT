import 'package:flutter/material.dart';

class StatsModel {
  String name;
  String iconPath;
  String level;
  String duration;
  String calorie;
  Color boxColor;
  bool viewIsSelected;

  StatsModel({
    required this.name,
    required this.iconPath,
    required this.level,
    required this.duration,
    required this.calorie,
    required this.boxColor,
    required this.viewIsSelected,
  });

  static List<StatsModel> getDiets() {
    List<StatsModel> stats = [];

    stats.add(
      StatsModel(
        name: 'Streak',
        iconPath: 'assets/icons/streak.svg',
        level: 'Easy',
        duration: '30mins',
        calorie: '180kCal',
        viewIsSelected: true,
        boxColor: Color(0xff9DCEFF),
      ),
    );

    stats.add(
      StatsModel(
        name: '',
        iconPath: 'assets/icons/canai-bread.svg',
        level: 'Easy',
        duration: '20mins',
        calorie: '230kCal',
        viewIsSelected: false,
        boxColor: Color(0xffEEA4CE),
      ),
    );

    return stats;
  }
}
