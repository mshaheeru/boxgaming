import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/venue_management_bloc.dart';
import '../bloc/venue_management_event.dart';
import '../bloc/venue_management_state.dart';
import '../../../venues/dto/create_venue_dto.dart';
import 'operating_hours_form.dart';
import 'grounds_form.dart';

class MultiStepVenueForm extends StatefulWidget {
  const MultiStepVenueForm({super.key});

  @override
  State<MultiStepVenueForm> createState() => _MultiStepVenueFormState();
}

class _MultiStepVenueFormState extends State<MultiStepVenueForm> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Basic Info
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  File? _selectedPhoto;

  // Step 2: Operating Hours
  List<Map<String, dynamic>> _operatingHours = [];

  // Step 3: Grounds
  List<Map<String, dynamic>> _grounds = [];

  String? _createdVenueId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleStep1Next() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create venue
    final dto = CreateVenueDto(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
    );

    context.read<VenueManagementBloc>().add(CreateVenueEvent(dto));
  }

  Future<void> _handleStep2Next() async {
    if (_operatingHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set operating hours for at least one day')),
      );
      return;
    }

    if (_createdVenueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue not created yet. Please wait...')),
      );
      return;
    }

    // Create operating hours
    context.read<VenueManagementBloc>().add(
          CreateOperatingHoursEvent(_createdVenueId!, _operatingHours),
        );

    // Wait a bit for the operation to complete, then move to next step
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentStep = 2;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleStep3Complete() {
    if (_grounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ground')),
      );
      return;
    }

    // Complete setup will be handled by the grounds form after creating grounds
    // The grounds form will call CompleteVenueSetupEvent after all grounds are created
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VenueManagementBloc, VenueManagementState>(
      listener: (context, state) {
        if (state is VenueCreated) {
          setState(() {
            _createdVenueId = state.venue.id;
          });

          // Upload photo if selected (non-blocking - don't wait for it)
          if (_selectedPhoto != null && _createdVenueId != null) {
            // Upload in background, don't block the flow
            Future.microtask(() {
              context.read<VenueManagementBloc>().add(
                    UploadVenuePhotoEvent(_createdVenueId!, _selectedPhoto!.path),
                  );
            });
          }

          // Move to step 2
          setState(() {
            _currentStep = 1;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else if (state is VenueManagementError) {
          // Don't show error for photo upload failures - it's optional
          if (!state.message.contains('photo') && !state.message.contains('bucket')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        } else if (state is VenueActivated) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venue created and activated successfully!')),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress indicator
                Row(
                  children: [
                    _buildStepIndicator(0, 'Basic Info', _currentStep >= 0),
                    _buildStepConnector(),
                    _buildStepIndicator(1, 'Hours', _currentStep >= 1),
                    _buildStepConnector(),
                    _buildStepIndicator(2, 'Grounds', _currentStep >= 2),
                  ],
                ),
                const SizedBox(height: 24),
                // Form content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Step 1: Basic Info
                      _buildStep1(state is VenueManagementLoading),
                      // Step 2: Operating Hours
                      OperatingHoursForm(
                        operatingHours: _operatingHours,
                        onChanged: (hours) {
                          setState(() {
                            _operatingHours = hours;
                          });
                        },
                        onNext: _handleStep2Next,
                        onBack: () {
                          setState(() {
                            _currentStep = 0;
                          });
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                      // Step 3: Grounds
                      _createdVenueId != null
                          ? GroundsForm(
                              grounds: _grounds,
                              venueId: _createdVenueId!,
                              onChanged: (grounds) {
                                setState(() {
                                  _grounds = grounds;
                                });
                              },
                              onComplete: () {
                                // Complete setup: activate venue
                                context.read<VenueManagementBloc>().add(
                                      CompleteVenueSetupEvent(_createdVenueId!),
                                    );
                              },
                              onBack: () {
                                setState(() {
                                  _currentStep = 1;
                                });
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.blue : Colors.grey,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 30,
      height: 2,
      color: Colors.grey,
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildStep1(bool isLoading) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Venue Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter venue name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Photo upload
            const Text(
              'Venue Photo (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedPhoto != null
                    ? Image.file(
                        _selectedPhoto!,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48),
                            SizedBox(height: 8),
                            Text('Tap to add photo'),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _handleStep1Next,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Next: Operating Hours'),
            ),
          ],
        ),
      ),
    );
  }
}

