import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kalo_app/core/constants/app_strings.dart';
import 'package:kalo_app/features/home/presentation/home_page.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _manualCalorieController = TextEditingController();

  String _gender = 'Male';
  String _activityLevel = 'Sedentary';
  DateTime? _birthDate;
  bool _isLoading = false;

  bool _isManualTarget = false;

  int _calculateTDEE(int age) {
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double height = double.tryParse(_heightController.text) ?? 0;

    double bmr;
    if (_gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double multiplier;
    switch (_activityLevel) {
      case 'Sedentary':
        multiplier = 1.2;
        break;
      case 'Light':
        multiplier = 1.375;
        break;
      case 'Moderate':
        multiplier = 1.55;
        break;
      case 'Active':
        multiplier = 1.725;
        break;
      default:
        multiplier = 1.2;
    }

    return (bmr * multiplier).round();
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate() || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.completePhysicalData)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final age = DateTime.now().year - _birthDate!.year;

    int finalTargetCalorie;
    if (_isManualTarget) {
      finalTargetCalorie = int.parse(_manualCalorieController.text);
    } else {
      finalTargetCalorie = _calculateTDEE(age);
    }

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'current_weight': double.parse(_weightController.text),
            'height': double.parse(_heightController.text),
            'birth_date': _birthDate!.toIso8601String(),
            'gender': _gender,
            'activity_level': _activityLevel,
            'daily_calorie_target': finalTargetCalorie,
            'current_streak': 0,
          })
          .eq('id', user.id);

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppStrings.error}${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.onboardingTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(AppStrings.onboardingSubtitle),
              const Gap(24),

              const Text(
                AppStrings.gender,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text(AppStrings.male),
                      value: "Male",
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v.toString()),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text(AppStrings.female),
                      value: "Female",
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v.toString()),
                    ),
                  ),
                ],
              ),

              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.weight,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? AppStrings.required : null,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.height,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? AppStrings.required : null,
                    ),
                  ),
                ],
              ),

              const Gap(24),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.dateOfBirth,
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _birthDate == null
                        ? AppStrings.selectDate
                        : DateFormat('dd MMM yyyy').format(_birthDate!),
                  ),
                ),
              ),

              const Gap(24),
              DropdownButtonFormField<String>(
                value: _activityLevel,
                decoration: const InputDecoration(
                  labelText: AppStrings.physicalActivity,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Sedentary',
                    child: Text(AppStrings.sedentary),
                  ),
                  DropdownMenuItem(
                    value: 'Light',
                    child: Text(AppStrings.light),
                  ),
                  DropdownMenuItem(
                    value: 'Moderate',
                    child: Text(AppStrings.moderate),
                  ),
                  DropdownMenuItem(
                    value: 'Active',
                    child: Text(AppStrings.active),
                  ),
                ],
                onChanged: (v) => setState(() => _activityLevel = v!),
              ),

              const Divider(height: 48, thickness: 1),

              SwitchListTile(
                title: const Text(AppStrings.setCustomTarget),
                subtitle: const Text(AppStrings.customTargetHint),
                value: _isManualTarget,
                activeColor: Colors.black,
                onChanged: (val) {
                  setState(() {
                    _isManualTarget = val;
                  });
                },
              ),

              if (_isManualTarget)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextFormField(
                    controller: _manualCalorieController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: AppStrings.manualTargetLabel,
                      border: OutlineInputBorder(),
                      suffixText: AppStrings.kcal,
                      helperText: AppStrings.example1800,
                    ),
                    validator: (v) {
                      if (_isManualTarget && (v == null || v.isEmpty)) {
                        return AppStrings.enterCalorieTarget;
                      }
                      return null;
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.autoTargetInfo,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

              const Gap(32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isManualTarget
                            ? AppStrings.saveManualTarget
                            : AppStrings.calculateAndSave,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
