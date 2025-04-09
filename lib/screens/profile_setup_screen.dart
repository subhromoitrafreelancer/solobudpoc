import 'package:flutter/material.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupScreen extends StatefulWidget {
 const ProfileSetupScreen({super.key});

 @override
 State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
 final _formKey = GlobalKey<FormState>();
 final _fullNameController = TextEditingController();
 final _preferredNameController = TextEditingController();
 final _bioController = TextEditingController();
 final _phoneController = TextEditingController();
 
 DateTime? _dateOfBirth;
 String? _selectedPronouns;
 String? _selectedSexuality;
 bool _showSexualityOnProfile = true;
 bool _shareInMatching = true;
 
 List<String> _selectedHumorTypes = [];
 List<String> _selectedAdventureStyles = [];
 List<String> _selectedActivePursuits = [];
 List<String> _selectedSocialEnergies = [];
 List<String> _selectedCultureConnects = [];
 List<String> _selectedValuesStyles = [];
 
 File? _avatarFile;
 bool _isLoading = false;
 int _currentStep = 0;

 @override
 void dispose() {
   _fullNameController.dispose();
   _preferredNameController.dispose();
   _bioController.dispose();
   _phoneController.dispose();
   super.dispose();
 }

 Future<void> _pickImage() async {
   final ImagePicker picker = ImagePicker();
   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
   
   if (image != null) {
     setState(() {
       _avatarFile = File(image.path);
     });
   }
 }

 Future<void> _saveProfile() async {
   if (!_formKey.currentState!.validate()) {
     return;
   }

   if (_dateOfBirth == null) {
     context.showSnackBar('Please select your date of birth', isError: true);
     return;
   }

   // Check if user is at least 16 years old
   final now = DateTime.now();
   final age = now.year - _dateOfBirth!.year - 
     (now.month > _dateOfBirth!.month || 
     (now.month == _dateOfBirth!.month && now.day >= _dateOfBirth!.day) ? 0 : 1);
   
   if (age < 16) {
     context.showSnackBar('You must be at least 16 years old to use this app', isError: true);
     return;
   }

   setState(() {
     _isLoading = true;
   });

   try {
     final userId = supabase.auth.currentUser!.id;
     
     // Upload avatar if selected
     String? avatarUrl;
     if (_avatarFile != null) {
       final fileExt = _avatarFile!.path.split('.').last;
       final fileName = '$userId.$fileExt';
       final filePath = 'avatars/$fileName';
       
       await supabase.storage.from('avatars').upload(
         filePath,
         _avatarFile!,
         fileOptions: const FileOptions(
           cacheControl: '3600',
           upsert: true,
         ),
       );
       
       avatarUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
     }
     
     // Insert user_info
     await supabase.from('user_info').insert({
       'id': userId,
       'full_name': _fullNameController.text.trim(),
       'preferred_name': _preferredNameController.text.trim().isNotEmpty 
           ? _preferredNameController.text.trim() 
           : null,
       'date_of_birth': _dateOfBirth!.toIso8601String().split('T').first,
       'phone_number': _phoneController.text.trim().isNotEmpty 
           ? _phoneController.text.trim() 
           : null,
       'bio': _bioController.text.trim().isNotEmpty 
           ? _bioController.text.trim() 
           : null,
       'avatar_url': avatarUrl,
       'is_available': true,
       'status': 'Active',
       'account_status': 'active',
       'visibility': 'public',
     });
     
     // Insert user_profile
     await supabase.from('user_profiles').insert({
       'id': userId,
       'pronouns': _selectedPronouns,
       'sexuality': _selectedSexuality,
       'humor_type': _selectedHumorTypes.isNotEmpty ? _selectedHumorTypes : null,
       'adventure_style': _selectedAdventureStyles.isNotEmpty ? _selectedAdventureStyles : null,
       'active_pursuits': _selectedActivePursuits.isNotEmpty ? _selectedActivePursuits : null,
       'social_energy': _selectedSocialEnergies.isNotEmpty ? _selectedSocialEnergies : null,
       'culture_connect': _selectedCultureConnects.isNotEmpty ? _selectedCultureConnects : null,
       'values_style': _selectedValuesStyles.isNotEmpty ? _selectedValuesStyles : null,
       'show_sexuality_on_profile': _showSexualityOnProfile,
       'share_in_matching': _shareInMatching,
     });
     
     if (mounted) {
       Navigator.of(context).pushReplacementNamed('/home');
     }
   } catch (error) {
     context.showSnackBar('Error saving profile: ${error.toString()}', isError: true);
   } finally {
     if (mounted) {
       setState(() {
         _isLoading = false;
       });
     }
   }
 }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Set Up Your Profile'),
     ),
     body: Form(
       key: _formKey,
       child: Stepper(
         currentStep: _currentStep,
         onStepContinue: () {
           if (_currentStep < 2) {
             setState(() {
               _currentStep += 1;
             });
           } else {
             _saveProfile();
           }
         },
         onStepCancel: () {
           if (_currentStep > 0) {
             setState(() {
               _currentStep -= 1;
             });
           }
         },
         steps: [
           Step(
             title: const Text('Basic Information'),
             content: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Center(
                   child: GestureDetector(
                     onTap: _pickImage,
                     child: Stack(
                       children: [
                         CircleAvatar(
                           radius: 50,
                           backgroundImage: _avatarFile != null 
                               ? FileImage(_avatarFile!) 
                               : null,
                           child: _avatarFile == null 
                               ? const Icon(Icons.person, size: 50) 
                               : null,
                         ),
                         Positioned(
                           bottom: 0,
                           right: 0,
                           child: Container(
                             padding: const EdgeInsets.all(4),
                             decoration: BoxDecoration(
                               color: Theme.of(context).colorScheme.primary,
                               shape: BoxShape.circle,
                             ),
                             child: const Icon(
                               Icons.camera_alt,
                               color: Colors.white,
                               size: 20,
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
                 const SizedBox(height: 24),
                 TextFormField(
                   controller: _fullNameController,
                   decoration: const InputDecoration(
                     labelText: 'Full Name *',
                     border: OutlineInputBorder(),
                   ),
                   validator: (value) {
                     if (value == null || value.trim().isEmpty) {
                       return 'Please enter your full name';
                     }
                     return null;
                   },
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _preferredNameController,
                   decoration: const InputDecoration(
                     labelText: 'Preferred Name (Optional)',
                     border: OutlineInputBorder(),
                   ),
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _phoneController,
                   decoration: const InputDecoration(
                     labelText: 'Phone Number (Optional)',
                     border: OutlineInputBorder(),
                   ),
                   keyboardType: TextInputType.phone,
                 ),
                 const SizedBox(height: 16),
                 InkWell(
                   onTap: () async {
                     final DateTime? picked = await showDatePicker(
                       context: context,
                       initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                       firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                       lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
                     );
                     if (picked != null) {
                       setState(() {
                         _dateOfBirth = picked;
                       });
                     }
                   },
                   child: InputDecorator(
                     decoration: const InputDecoration(
                       labelText: 'Date of Birth *',
                       border: OutlineInputBorder(),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           _dateOfBirth != null
                               ? DateFormat('MMM dd, yyyy').format(_dateOfBirth!)
                               : 'Select Date',
                         ),
                         const Icon(Icons.calendar_today),
                       ],
                     ),
                   ),
                 ),
               ],
             ),
             isActive: _currentStep >= 0,
           ),
           Step(
             title: const Text('About You'),
             content: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 TextFormField(
                   controller: _bioController,
                   decoration: const InputDecoration(
                     labelText: 'Bio (Optional)',
                     border: OutlineInputBorder(),
                     hintText: 'Tell us about yourself...',
                   ),
                   maxLines: 3,
                 ),
                 const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                   decoration: const InputDecoration(
                     labelText: 'Pronouns (Optional)',
                     border: OutlineInputBorder(),
                   ),
                   value: _selectedPronouns,
                   items: pronounOptions.map((String value) {
                     return DropdownMenuItem<String>(
                       value: value,
                       child: Text(value),
                     );
                   }).toList(),
                   onChanged: (String? newValue) {
                     setState(() {
                       _selectedPronouns = newValue;
                     });
                   },
                 ),
                 const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                   decoration: const InputDecoration(
                     labelText: 'Sexuality (Optional)',
                     border: OutlineInputBorder(),
                   ),
                   value: _selectedSexuality,
                   items: sexualityOptions.map((String value) {
                     return DropdownMenuItem<String>(
                       value: value,
                       child: Text(value),
                     );
                   }).toList(),
                   onChanged: (String? newValue) {
                     setState(() {
                       _selectedSexuality = newValue;
                     });
                   },
                 ),
                 const SizedBox(height: 16),
                 SwitchListTile(
                   title: const Text('Show sexuality on profile'),
                   value: _showSexualityOnProfile,
                   onChanged: (bool value) {
                     setState(() {
                       _showSexualityOnProfile = value;
                     });
                   },
                 ),
                 SwitchListTile(
                   title: const Text('Use profile for matching'),
                   value: _shareInMatching,
                   onChanged: (bool value) {
                     setState(() {
                       _shareInMatching = value;
                     });
                   },
                 ),
               ],
             ),
             isActive: _currentStep >= 1,
           ),
           Step(
             title: const Text('Your Preferences'),
             content: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text(
                   'Humor Type',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 Wrap(
                   spacing: 8,
                   children: humorTypeOptions.map((type) {
                     return FilterChip(
                       label: Text(type),
                       selected: _selectedHumorTypes.contains(type),
                       onSelected: (selected) {
                         setState(() {
                           if (selected) {
                             _selectedHumorTypes.add(type);
                           } else {
                             _selectedHumorTypes.remove(type);
                           }
                         });
                       },
                     );
                   }).toList(),
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   'Adventure Style',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 Wrap(
                   spacing: 8,
                   children: adventureStyleOptions.map((style) {
                     return FilterChip(
                       label: Text(style),
                       selected: _selectedAdventureStyles.contains(style),
                       onSelected: (selected) {
                         setState(() {
                           if (selected) {
                             _selectedAdventureStyles.add(style);
                           } else {
                             _selectedAdventureStyles.remove(style);
                           }
                         });
                       },
                     );
                   }).toList(),
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   'Active Pursuits',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 Wrap(
                   spacing: 8,
                   children: activePursuitsOptions.map((pursuit) {
                     return FilterChip(
                       label: Text(pursuit),
                       selected: _selectedActivePursuits.contains(pursuit),
                       onSelected: (selected) {
                         setState(() {
                           if (selected) {
                             _selectedActivePursuits.add(pursuit);
                           } else {
                             _selectedActivePursuits.remove(pursuit);
                           }
                         });
                       },
                     );
                   }).toList(),
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   'Social Energy',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 Wrap(
                   spacing: 8,
                   children: socialEnergyOptions.map((energy) {
                     return FilterChip(
                       label: Text(energy),
                       selected: _selectedSocialEnergies.contains(energy),
                       onSelected: (selected) {
                         setState(() {
                           if (selected) {
                             _selectedSocialEnergies.add(energy);
                           } else {
                             _selectedSocialEnergies.remove(energy);
                           }
                         });
                       },
                     );
                   }).toList(),
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   'Culture Connect',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 Wrap(
                   spacing: 8,
                   children: cultureConnectOptions.map((culture) {
                     return FilterChip(
                       label: Text(culture),
                       selected: _selectedCultureConnects.contains(culture),
                       onSelected: (selected) {
                         setState(() {
                           if (selected) {
                             _selectedCultureConnects.add(culture);
                           } else {
                             _selectedCultureConnects.remove(culture);
                           }
                         });
                       },
                     );
                   }).toList(),
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   'Values Style',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 Wrap(
                   spacing: 8,
                   children: valuesStyleOptions.map((value) {
                     return FilterChip(
                       label: Text(value),
                       selected: _selectedValuesStyles.contains(value),
                       onSelected: (selected) {
                         setState(() {
                           if (selected) {
                             _selectedValuesStyles.add(value);
                           } else {
                             _selectedValuesStyles.remove(value);
                           }
                         });
                       },
                     );
                   }).toList(),
                 ),
               ],
             ),
             isActive: _currentStep >= 2,
           ),
         ],
       ),
     ),
   );
 }
}
