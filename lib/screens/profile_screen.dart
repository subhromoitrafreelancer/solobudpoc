import 'package:flutter/material.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  UserInfo? _userInfo;
  UserProfile? _userProfile;
  List<UserLanguage> _userLanguages = [];
  List<UserNationality> _userNationalities = [];
  
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _preferredNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      
      // Load user_info
      final userInfoData = await supabase
          .from('user_info')
          .select()
          .eq('id', userId)
          .single();
      
      _userInfo = UserInfo.fromJson(userInfoData);
      
      // Load user_profile
      final userProfileData = await supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (userProfileData != null) {
        _userProfile = UserProfile.fromJson(userProfileData);
      }
      
      // Load user_languages with language names
      final userLanguagesData = await supabase
          .from('user_languages')
          .select('*, languages(name)')
          .eq('user_id', userId);
      
      _userLanguages = (userLanguagesData as List)
          .map((item) => UserLanguage.fromJson(item))
          .toList();
      
      // Load user_nationalities with country names
      final userNationalitiesData = await supabase
          .from('user_nationalities')
          .select('*, countries(name)')
          .eq('user_id', userId);
      
      _userNationalities = (userNationalitiesData as List)
          .map((item) => UserNationality.fromJson(item))
          .toList();
      
      // Initialize form controllers
      _fullNameController.text = _userInfo!.fullName;
      _preferredNameController.text = _userInfo!.preferredName ?? '';
      _bioController.text = _userInfo!.bio ?? '';
      _phoneController.text = _userInfo!.phoneNumber ?? '';
      _dateOfBirth = _userInfo!.dateOfBirth;
      
      if (_userProfile != null) {
        _selectedPronouns = _userProfile!.pronouns;
        _selectedSexuality = _userProfile!.sexuality;
        _showSexualityOnProfile = _userProfile!.showSexualityOnProfile;
        _shareInMatching = _userProfile!.shareInMatching;
        
        _selectedHumorTypes = _userProfile!.humorType ?? [];
        _selectedAdventureStyles = _userProfile!.adventureStyle ?? [];
        _selectedActivePursuits = _userProfile!.activePursuits ?? [];
        _selectedSocialEnergies = _userProfile!.socialEnergy ?? [];
        _selectedCultureConnects = _userProfile!.cultureConnect ?? [];
        _selectedValuesStyles = _userProfile!.valuesStyle ?? [];
      }
    } catch (error) {
      context.showSnackBar('Error loading profile: ${error.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  Future<void> _updateProfile() async {
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
      String? avatarUrl = _userInfo!.avatarUrl;
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
      
      // Update user_info
      await supabase.from('user_info').update({
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
      }).eq('id', userId);
      
      // Update user_profile
      await supabase.from('user_profiles').upsert({
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
      
      await _loadUserProfile();
      
      setState(() {
        _isEditing = false;
      });
      
      if (mounted) {
        context.showSnackBar('Profile updated successfully');
      }
    } catch (error) {
      context.showSnackBar('Error updating profile: ${error.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isEditing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          actions: [
            TextButton(
              onPressed: _updateProfile,
              child: const Text('Save'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
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
                              : (_userInfo!.avatarUrl != null 
                                  ? NetworkImage(_userInfo!.avatarUrl!) as ImageProvider 
                                  : null),
                          child: (_avatarFile == null && _userInfo!.avatarUrl == null) 
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
                      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Tell us about yourself...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                const SizedBox(height: 24),
                const Text(
                  'Your Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _userInfo!.avatarUrl != null 
                        ? NetworkImage(_userInfo!.avatarUrl!) as ImageProvider 
                        : null,
                    child: _userInfo!.avatarUrl == null 
                        ? const Icon(Icons.person, size: 60) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userInfo!.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userInfo!.preferredName != null)
                    Text(
                      '(${_userInfo!.preferredName})',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_userProfile?.pronouns != null)
                    Text(
                      _userProfile!.pronouns!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_userInfo!.bio != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_userInfo!.bio!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.cake),
              title: const Text('Date of Birth'),
              subtitle: Text(
                DateFormat('MMMM d, yyyy').format(_userInfo!.dateOfBirth),
              ),
            ),
            if (_userInfo!.phoneNumber != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: Text(_userInfo!.phoneNumber!),
              ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Visibility'),
              subtitle: Text(_userInfo!.visibility),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Personal Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_userProfile?.sexuality != null && _userProfile!.showSexualityOnProfile)
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Sexuality'),
                subtitle: Text(_userProfile!.sexuality!),
              ),
            if (_userProfile?.humorType != null && _userProfile!.humorType!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('Humor Type'),
                subtitle: Wrap(
                  spacing: 4,
                  children: _userProfile!.humorType!.map((type) {
                    return Chip(
                      label: Text(type),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
            if (_userProfile?.adventureStyle != null && _userProfile!.adventureStyle!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.explore),
                title: const Text('Adventure Style'),
                subtitle: Wrap(
                  spacing: 4,
                  children: _userProfile!.adventureStyle!.map((style) {
                    return Chip(
                      label: Text(style),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
            if (_userProfile?.activePursuits != null && _userProfile!.activePursuits!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.directions_run),
                title: const Text('Active Pursuits'),
                subtitle: Wrap(
                  spacing: 4,
                  children: _userProfile!.activePursuits!.map((pursuit) {
                    return Chip(
                      label: Text(pursuit),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
            if (_userProfile?.socialEnergy != null && _userProfile!.socialEnergy!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Social Energy'),
                subtitle: Wrap(
                  spacing: 4,
                  children: _userProfile!.socialEnergy!.map((energy) {
                    return Chip(
                      label: Text(energy),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
            if (_userProfile?.cultureConnect != null && _userProfile!.cultureConnect!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Culture Connect'),
                subtitle: Wrap(
                  spacing: 4,
                  children: _userProfile!.cultureConnect!.map((culture) {
                    return Chip(
                      label: Text(culture),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
            if (_userProfile?.valuesStyle != null && _userProfile!.valuesStyle!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.volunteer_activism),
                title: const Text('Values Style'),
                subtitle: Wrap(
                  spacing: 4,
                  children: _userProfile!.valuesStyle!.map((value) {
                    return Chip(
                      label: Text(value),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
            if (_userLanguages.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Languages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...(_userLanguages.map((language) => ListTile(
                leading: const Icon(Icons.language),
                title: Text(language.languageName),
                subtitle: Text(language.proficiency),
              ))),
            ],
            if (_userNationalities.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Nationalities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...(_userNationalities.map((nationality) => ListTile(
                leading: const Icon(Icons.flag),
                title: Text(nationality.countryName),
                trailing: nationality.isPrimary ? const Chip(label: Text('Primary')) : null,
              ))),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
