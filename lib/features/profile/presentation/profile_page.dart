import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kalo_app/core/constants/app_strings.dart';
import 'package:kalo_app/features/auth/data/auth_repository.dart';
import 'package:kalo_app/features/auth/presentation/login_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _manualCalController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _manualCalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('current_weight, height, daily_calorie_target')
        .eq('id', user.id)
        .single();

    setState(() {
      _weightController.text = data['current_weight'].toString();
      _heightController.text = data['height'].toString();
      _manualCalController.text = data['daily_calorie_target'].toString();
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final newTarget = int.parse(_manualCalController.text);

      await Supabase.instance.client
          .from('profiles')
          .update({
            'current_weight': double.parse(_weightController.text),
            'height': double.parse(_heightController.text),
            'daily_calorie_target': newTarget,
          })
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profileUpdated)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${AppStrings.error}$e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const Gap(16),
                  Text(
                    user?.email ?? "User",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const Gap(32),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.physicalData,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.weight,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.height,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Gap(24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.calorieTarget,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Gap(8),
                  TextFormField(
                    controller: _manualCalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: AppStrings.dailyTarget,
                      border: OutlineInputBorder(),
                      helperText: AppStrings.adjustTargetHint,
                    ),
                  ),

                  const Gap(40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(AppStrings.saveChanges),
                    ),
                  ),

                  const Gap(24),
                  const Divider(),
                  const Gap(24),

                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      AppStrings.signOut,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
