import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import '../bloc/venue_management_bloc.dart';
import '../bloc/venue_management_event.dart';
import '../bloc/venue_management_state.dart';
import '../../../venues/dto/create_venue_dto.dart';
import '../../../venues/dto/update_venue_dto.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import 'grounds_form.dart';
import '../../data/datasources/venue_management_remote_datasource.dart';

class MultiStepVenueForm extends StatefulWidget {
  final VenueEntity? venue; // If provided, we're in edit mode

  const MultiStepVenueForm({
    super.key,
    this.venue,
  });

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

  // Step 2: Grounds (operating hours are now per-ground)
  List<Map<String, dynamic>> _grounds = [];

  String? _createdVenueId;
  bool get _isEditMode => widget.venue != null;
  final VenueManagementRemoteDataSource _remoteDataSource = 
      GetIt.instance<VenueManagementRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Pre-populate fields in edit mode
      final venue = widget.venue!;
      _createdVenueId = venue.id;
      _nameController.text = venue.name;
      _descriptionController.text = venue.description ?? '';
      _addressController.text = venue.address ?? '';
      _cityController.text = venue.city ?? '';
      // Load existing operating hours and grounds
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    if (!_isEditMode) return;
    
    try {
      // Load grounds
      final groundsData = await _remoteDataSource.getVenueGrounds(widget.venue!.id);
      
      // Load operating hours for each ground
      final List<Map<String, dynamic>> groundsWithHours = [];
      for (var g in groundsData) {
        final groundId = g['id'] as String?;
        if (groundId != null) {
          try {
            // Fetch operating hours for this ground
            final operatingHours = await _remoteDataSource.getGroundOperatingHours(
              widget.venue!.id,
              groundId,
            );
            
            groundsWithHours.add({
              'id': groundId, // Ensure ID is always set
              'name': g['name'] as String? ?? '',
              'sportType': g['sport_type'] ?? g['sportType'] ?? 'badminton',
              'size': g['size'] ?? 'medium',
              'price2hr': (g['price_2hr'] ?? g['price2hr'] as num?)?.toDouble() ?? 0.0,
              'price3hr': (g['price_3hr'] ?? g['price3hr'] as num?)?.toDouble() ?? 0.0,
              'isActive': g['is_active'] ?? g['isActive'] ?? true,
              'operatingHours': operatingHours, // Include operating hours
            });
          } catch (e) {
            // If operating hours fetch fails, still add the ground without hours
            print('Error loading operating hours for ground $groundId: $e');
            groundsWithHours.add({
              'id': groundId,
              'name': g['name'] as String? ?? '',
              'sportType': g['sport_type'] ?? g['sportType'] ?? 'badminton',
              'size': g['size'] ?? 'medium',
              'price2hr': (g['price_2hr'] ?? g['price2hr'] as num?)?.toDouble() ?? 0.0,
              'price3hr': (g['price_3hr'] ?? g['price3hr'] as num?)?.toDouble() ?? 0.0,
              'isActive': g['is_active'] ?? g['isActive'] ?? true,
              'operatingHours': <Map<String, dynamic>>[], // Empty if fetch fails
            });
          }
        }
      }
      
      setState(() {
        _grounds = groundsWithHours;
      });
    } catch (e) {
      // Handle error silently or show snackbar
      print('Error loading existing data: $e');
    }
  }

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

    if (_isEditMode) {
      // Update venue
      final dto = UpdateVenueDto(
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

      context.read<VenueManagementBloc>().add(UpdateVenueEvent(widget.venue!.id, dto));

      // Upload photo if selected (non-blocking)
      if (_selectedPhoto != null) {
        Future.microtask(() {
          context.read<VenueManagementBloc>().add(
                UploadVenuePhotoEvent(widget.venue!.id, _selectedPhoto!.path),
              );
        });
      }

      // Don't navigate here - let the VenueUpdated listener handle it
      // This prevents double navigation
    } else {
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

          // Move to step 2 (Grounds - operating hours are now per-ground)
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
            SnackBar(
              content: Text(_isEditMode 
                ? 'Venue updated and activated successfully!'
                : 'Venue created and activated successfully!'),
            ),
          );
        } else if (state is VenueUpdated && _isEditMode) {
          // In edit mode, after updating venue, move to step 2 (Grounds)
          // Only navigate if we're still on step 1 (Basic Info)
          // Don't show snackbar here - wait until form is complete
          if (_currentStep == 0) {
            setState(() {
              _currentStep = 1;
            });
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
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
                // Title
                Text(
                  _isEditMode ? 'Edit Venue' : 'Create New Venue',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Progress indicator
                Row(
                  children: [
                    _buildStepIndicator(0, 'Basic Info', _currentStep >= 0),
                    _buildStepConnector(),
                    _buildStepIndicator(1, 'Grounds', _currentStep >= 1),
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
                      // Step 2: Grounds (operating hours are now per-ground)
                      (_createdVenueId != null || _isEditMode)
                          ? GroundsForm(
                              grounds: _grounds,
                              venueId: _createdVenueId ?? widget.venue!.id,
                              isEditMode: _isEditMode,
                              onChanged: (grounds) {
                                setState(() {
                                  _grounds = grounds;
                                });
                              },
                              onComplete: () {
                                if (_isEditMode) {
                                  // In edit mode, activate venue and close
                                  context.read<VenueManagementBloc>().add(
                                        CompleteVenueSetupEvent(_createdVenueId ?? widget.venue!.id),
                                      );
                                } else {
                                  // In create mode, activate venue
                                  if (_createdVenueId != null) {
                                    context.read<VenueManagementBloc>().add(
                                          CompleteVenueSetupEvent(_createdVenueId!),
                                        );
                                  }
                                }
                              },
                              onBack: () {
                                setState(() {
                                  _currentStep = 0;
                                });
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
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

  Widget _buildStep1(bool isLoading) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the basic details for your venue',
              style: TextStyle(color: Colors.grey),
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
                  return 'Please enter a venue name';
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
            const SizedBox(height: 16),
            // Photo upload
            const Text(
              'Venue Photo (Optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_selectedPhoto != null)
                  Expanded(
                    child: Image.file(
                      _selectedPhoto!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick Image'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _handleStep1Next,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(_isEditMode ? 'Next: Manage Grounds' : 'Next: Add Grounds'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.blue : Colors.grey[300],
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.blue : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[300],
    );
  }
}

