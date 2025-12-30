import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/bookings_bloc.dart';
import '../bloc/bookings_event.dart';
import '../bloc/bookings_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/constants/route_constants.dart';
import '../../domain/entities/slot_entity.dart';
import '../../domain/entities/operating_hours_entity.dart';
import '../../domain/entities/day_slots_entity.dart';
import '../../../venues/domain/entities/ground_entity.dart';
import '../../../payments/domain/entities/payment_entity.dart';

class BookingScreenPage extends StatefulWidget {
  final GroundEntity ground;
  final String venueName;

  const BookingScreenPage({
    super.key,
    required this.ground,
    required this.venueName,
  });

  @override
  State<BookingScreenPage> createState() => _BookingScreenPageState();
}

class _BookingScreenPageState extends State<BookingScreenPage> {
  DateTimeRange? _selectedDateRange;
  int _selectedDuration = 2;
  String? _selectedDay; // Format: "2024-12-30" or dayOfWeek name
  String? _selectedTime;
  PaymentGateway? _selectedPaymentMethod;
  List<OperatingHoursEntity> _operatingHours = [];
  Map<String, DaySlotsEntity> _slotsByDate = {};
  List<String> _selectedSports = [];
  
  bool get _isAllSportsGround {
    final sportTypeName = widget.ground.sportType.name;
    return sportTypeName == 'all';
  }

  @override
  void initState() {
    super.initState();
    if (_isAllSportsGround) {
      _selectedSports = ['badminton', 'futsal', 'cricket', 'padel', 'table_tennis'];
    } else {
      _selectedSports = [widget.ground.sportType.name];
    }
    // Load operating hours after the first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadOperatingHours();
      }
    });
  }

  void _loadOperatingHours() {
    if (!mounted) return;
    final bloc = context.read<BookingsBloc>();
    if (!bloc.isClosed) {
      bloc.add(
        LoadOperatingHoursEvent(
          venueId: widget.ground.venueId,
          groundId: widget.ground.id,
        ),
      );
    }
  }

  void _loadSlotsForDateRange() {
    if (_selectedDateRange == null || !mounted) return;
    final bloc = context.read<BookingsBloc>();
    if (!bloc.isClosed) {
      bloc.add(
        LoadSlotsForDateRangeEvent(
          groundId: widget.ground.id,
          startDate: _selectedDateRange!.start,
          endDate: _selectedDateRange!.end,
          duration: _selectedDuration,
        ),
      );
    }
  }

  void _createBooking() {
    if (_selectedDay == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day and time slot')),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    // Parse selected day to DateTime
    final dateParts = _selectedDay!.split('-');
    final bookingDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    final bloc = context.read<BookingsBloc>();
    if (!bloc.isClosed && mounted) {
      bloc.add(
        CreateBookingEvent(
          groundId: widget.ground.id,
          bookingDate: bookingDate,
          startTime: _selectedTime!,
          durationHours: _selectedDuration,
          paymentMethod: _selectedPaymentMethod!,
        ),
      );
    }
  }

  // Get available days from operating hours that fall within the selected date range
  List<Map<String, dynamic>> _getAvailableDaysInRange() {
    if (_selectedDateRange == null || _operatingHours.isEmpty) return [];

    final availableDays = <Map<String, dynamic>>[];
    DateTime current = DateTime(
      _selectedDateRange!.start.year,
      _selectedDateRange!.start.month,
      _selectedDateRange!.start.day,
    );
    final end = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
    );

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // DateTime.weekday returns 1-7 (Monday=1, Sunday=7)
      // Database uses 0-6 (Sunday=0, Saturday=6)
      // Convert: Sunday (7) -> 0, Monday (1) -> 1, ..., Saturday (6) -> 6
      final weekday = current.weekday; // 1-7
      final dayOfWeek = weekday == 7 ? 0 : weekday; // Convert to 0-6
      
      final operatingHour = _operatingHours.where(
        (oh) => oh.dayOfWeek == dayOfWeek,
      ).firstOrNull;

      if (operatingHour != null) {
        availableDays.add({
          'date': current,
          'dateStr': DateFormatters.formatDate(current),
          'dayOfWeek': dayOfWeek,
          'dayName': operatingHour.dayName,
          'openTime': operatingHour.openTime,
          'closeTime': operatingHour.closeTime,
        });
      }

      current = current.add(const Duration(days: 1));
    }

    return availableDays;
  }

  // Get available slots for selected day
  List<SlotEntity> _getSlotsForSelectedDay() {
    if (_selectedDay == null) return [];
    return _slotsByDate[_selectedDay!]?.slots ?? [];
  }

  // Check if two time slots overlap
  bool _slotsOverlap(String time1, int duration1, String time2, int duration2) {
    final start1 = _parseTimeToMinutes(time1);
    var end1 = start1 + (duration1 * 60);
    final start2 = _parseTimeToMinutes(time2);
    var end2 = start2 + (duration2 * 60);
    
    // Handle overnight hours - normalize end times
    if (end1 >= 24 * 60) {
      end1 = end1 % (24 * 60);
    }
    if (end2 >= 24 * 60) {
      end2 = end2 % (24 * 60);
    }
    
    // Check for overlap: slots overlap if one starts before the other ends
    // But we need to handle the case where end time is less than start time (overnight)
    if (end1 < start1) {
      // Slot 1 crosses midnight
      return (start2 < end1) || (start2 >= start1);
    }
    if (end2 < start2) {
      // Slot 2 crosses midnight
      return (start1 < end2) || (start1 >= start2);
    }
    
    // Normal case: both slots are on the same day
    return (start1 < end2 && start2 < end1);
  }

  // Parse time string (HH:mm) to minutes from midnight
  int _parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Calculate end time for a slot
  String _calculateEndTime(String startTime, int durationHours) {
    final startMinutes = _parseTimeToMinutes(startTime);
    final endMinutes = startMinutes + (durationHours * 60);
    final endHour = (endMinutes ~/ 60) % 24;
    final endMin = endMinutes % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.ground.name}'),
      ),
      body: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            // Show success message and navigate back
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Booking confirmed! Amount: Rs. ${state.booking.price.toStringAsFixed(0)}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Navigate back to venues list
            context.pop();
          } else if (state is BookingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is OperatingHoursLoaded) {
            setState(() {
              _operatingHours = state.operatingHours;
            });
          } else if (state is SlotsRangeLoaded) {
            setState(() {
              _slotsByDate = state.slotsByDate;
              _selectedTime = null; // Reset selected time when slots reload
            });
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Venue and Ground Info
                Text(
                  widget.venueName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.ground.name,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                // Sport Selection (if all sports)
                if (_isAllSportsGround) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Select Sports',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SportSelectionChips(
                    selectedSports: _selectedSports,
                    onChanged: (selected) {
                      setState(() {
                        _selectedSports = selected;
                      });
                    },
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Date Range Picker
                const Text(
                  'Select Date Range',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                        _selectedDay = null;
                        _selectedTime = null;
                      });
                      _loadSlotsForDateRange();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDateRange == null
                              ? 'Select date range'
                              : '${DateFormatters.formatDisplayDate(_selectedDateRange!.start)} - ${DateFormatters.formatDisplayDate(_selectedDateRange!.end)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                
                // Day Selection Dropdown (shown after date range is selected)
                if (_selectedDateRange != null && _operatingHours.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Select Day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state is BookingsLoading && _slotsByDate.isEmpty)
                    const LoadingWidget()
                  else ...[
                    DropdownButtonFormField<String>(
                      value: _selectedDay,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text(
                        'Select a day',
                        style: TextStyle(fontSize: 14),
                      ),
                      selectedItemBuilder: (context) {
                        // This builder is used for the selected value display
                        return _getAvailableDaysInRange().map((day) {
                          final date = day['date'] as DateTime;
                          return Text(
                            DateFormatters.formatDayWithDate(date),
                            style: const TextStyle(fontSize: 14),
                          );
                        }).toList();
                      },
                      items: _getAvailableDaysInRange().map((day) {
                        final date = day['date'] as DateTime;
                        final dateStr = day['dateStr'] as String;
                        final dayName = day['dayName'] as String;
                        final openTime = day['openTime'] as String;
                        final closeTime = day['closeTime'] as String;
                        
                        return DropdownMenuItem<String>(
                          value: dateStr,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormatters.formatDayWithDate(date),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '$openTime - $closeTime',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                          _selectedTime = null;
                        });
                        // Load slots for the selected day
                        if (value != null) {
                          _loadSlotsForDateRange();
                        }
                      },
                    ),
                  ],
                ],
                
                // Duration Selection (shown after day is selected)
                if (_selectedDay != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Select Duration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('2 Hours'),
                          selected: _selectedDuration == 2,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedDuration = 2;
                                _selectedTime = null;
                              });
                              _loadSlotsForDateRange();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('3 Hours'),
                          selected: _selectedDuration == 3,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedDuration = 3;
                                _selectedTime = null;
                              });
                              _loadSlotsForDateRange();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Time Slots Section (shown when day and duration are selected)
                if (_selectedDay != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Available Time Slots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final availableSlots = _getSlotsForSelectedDay();
                      
                      // Debug: Check if slots are loaded
                      if (_slotsByDate.isEmpty && state is! BookingsLoading) {
                        return Column(
                          children: [
                            const Text('Loading slots for date range...'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadSlotsForDateRange,
                              child: const Text('Retry Loading Slots'),
                            ),
                          ],
                        );
                      }
                      
                      if (availableSlots.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('No slots available for this day.'),
                            const SizedBox(height: 8),
                            Text(
                              'This could be because:\n'
                              '- The time range doesn\'t allow valid ${_selectedDuration}hr slots\n'
                              '- All slots are already booked\n'
                              '- The operating hours configuration needs adjustment',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        );
                      }
                      
                      // Show slots as ranges and disable overlapping ones
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSlots.map((slot) {
                          final isSelected = _selectedTime == slot.time;
                          final slotRange = DateFormatters.formatTimeRange(slot.time, _selectedDuration);
                          
                          // Check if this slot overlaps with the selected slot
                          final isOverlapping = _selectedTime != null && 
                              _selectedTime != slot.time &&
                              _slotsOverlap(_selectedTime!, _selectedDuration, slot.time, _selectedDuration);
                          
                          final isDisabled = !slot.available || isOverlapping;
                          
                          return FilterChip(
                            label: Text(slotRange),
                            selected: isSelected,
                            onSelected: !isDisabled
                                ? (selected) {
                                    setState(() {
                                      _selectedTime = selected ? slot.time : null;
                                    });
                                  }
                                : null,
                            backgroundColor: isOverlapping ? Colors.grey[300] : null,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
                
                // Payment Method Selection (shown when time slot is selected)
                if (_selectedTime != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Easy Paisa'),
                          selected: _selectedPaymentMethod == PaymentGateway.easypaisa,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPaymentMethod = PaymentGateway.easypaisa;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('JazzCash'),
                          selected: _selectedPaymentMethod == PaymentGateway.jazzcash,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPaymentMethod = PaymentGateway.jazzcash;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Card'),
                          selected: _selectedPaymentMethod == PaymentGateway.card,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPaymentMethod = PaymentGateway.card;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                    ],
                  ),
                ),
              ),
              // Fixed Book button at bottom
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (state is BookingsLoading || _selectedDay == null || _selectedTime == null || _selectedPaymentMethod == null)
                          ? null
                          : _createBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state is BookingsLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Book for Rs. ${(_selectedDuration == 2 ? widget.ground.price2hr : widget.ground.price3hr).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SportSelectionChips extends StatefulWidget {
  final List<String> selectedSports;
  final Function(List<String>) onChanged;

  const _SportSelectionChips({
    required this.selectedSports,
    required this.onChanged,
  });

  @override
  State<_SportSelectionChips> createState() => _SportSelectionChipsState();
}

class _SportSelectionChipsState extends State<_SportSelectionChips> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedSports);
  }

  @override
  void didUpdateWidget(_SportSelectionChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSports != widget.selectedSports) {
      _selected = List.from(widget.selectedSports);
    }
  }

  void _toggleSport(String sport) {
    setState(() {
      if (_selected.contains(sport)) {
        _selected.remove(sport);
      } else {
        _selected.add(sport);
      }
      widget.onChanged(_selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSports = ['badminton', 'futsal', 'cricket', 'padel', 'table_tennis'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allSports.map((sport) {
        final isSelected = _selected.contains(sport);
        final displayName = sport.toUpperCase().replaceAll('_', ' ');
        
        return FilterChip(
          label: Text(displayName),
          selected: isSelected,
          onSelected: (_) => _toggleSport(sport),
          selectedColor: Colors.blue.withOpacity(0.2),
        );
      }).toList(),
    );
  }
}
