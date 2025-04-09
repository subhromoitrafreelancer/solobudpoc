import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

// Supabase client
final supabase = Supabase.instance.client;

// Extension for showing snackbars
extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).colorScheme.primary,
      ),
    );
  }
}

// Profile constants
const List<String> humorTypeOptions = [
  'Sarcastic', 'Witty', 'Silly', 'Dark', 'Puns', 'Observational'
];

const List<String> adventureStyleOptions = [
  'Spontaneous', 'Planned', 'Relaxed', 'Thrill-seeking', 'Cultural', 'Nature'
];

const List<String> activePursuitsOptions = [
  'Hiking', 'Swimming', 'Cycling', 'Running', 'Yoga', 'Dancing', 'Climbing'
];

const List<String> socialEnergyOptions = [
  'Extroverted', 'Introverted', 'Ambivert', 'Depends on mood'
];

const List<String> cultureConnectOptions = [
  'Food', 'Art', 'Music', 'History', 'Language', 'Architecture'
];

const List<String> valuesStyleOptions = [
  'Environmental', 'Social justice', 'Spiritual', 'Family-oriented', 'Career-focused'
];

const List<String> pronounOptions = [
  'He/Him', 'She/Her', 'They/Them', 'Ze/Zir', 'Other'
];

const List<String> sexualityOptions = [
  'Straight', 'Gay', 'Lesbian', 'Bisexual', 'Pansexual', 'Asexual', 'Queer', 'Prefer not to say'
];
