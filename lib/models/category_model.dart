import 'package:flutter/material.dart';

class CategoryModel {
  final IconData icon;
  final String title;

  CategoryModel({required this.icon, required this.title});
}

final List<CategoryModel> categoryList = [
    CategoryModel(icon: Icons.cleaning_services, title: "Cleaning"),
    CategoryModel(icon: Icons.handyman, title: "Carpenter"),
    CategoryModel(icon: Icons.electrical_services, title: "Electrician"),
    CategoryModel(icon: Icons.plumbing, title: "Plumber"),
    CategoryModel(icon: Icons.format_paint, title: "Painter"),
    CategoryModel(icon: Icons.bug_report, title: "Pest Control"),
    CategoryModel(icon: Icons.ac_unit, title: "AC Repair"),
    CategoryModel(icon: Icons.table_restaurant, title: "Furniture Assembly"),
    CategoryModel(icon: Icons.local_florist, title: "Gardening"),
    CategoryModel(icon: Icons.home_repair_service, title: "Home Repair"),
  ];