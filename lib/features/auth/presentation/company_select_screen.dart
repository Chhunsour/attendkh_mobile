import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class CompanySelectScreen extends StatelessWidget {
  const CompanySelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Company')),
      body: const Center(
        child: Text('Company Select Screen - TODO'),
      ),
    );
  }
}