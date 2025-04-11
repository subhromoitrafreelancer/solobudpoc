import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
final LocalDatabaseService _localDb = LocalDatabaseService();

extension ShowSnackBar on BuildContext {
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
      duration: duration,
    ));
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, isError: true);
  }
}
