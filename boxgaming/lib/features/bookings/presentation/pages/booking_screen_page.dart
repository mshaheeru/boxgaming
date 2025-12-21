import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Note: table_calendar import - using basic calendar for now
import '../bloc/bookings_bloc.dart';
import '../bloc/bookings_event.dart';
import '../bloc/bookings_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/constants/route_constants.dart';
import '../../domain/entities/slot_entity.dart';
import '../../../venues/domain/entities/ground_entity.dart';

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
  DateTime _selectedDate = DateTime.now();
  int _selectedDuration = 2;
  String? _selectedTime;
  List<SlotEntity> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  void _loadSlots() {
    context.read<BookingsBloc>().add(
          LoadAvailableSlotsEvent(
            groundId: widget.ground.id,
            date: _selectedDate,
            duration: _selectedDuration,
          ),
        );
  }

  void _createBooking() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    context.read<BookingsBloc>().add(
          CreateBookingEvent(
            groundId: widget.ground.id,
            bookingDate: _selectedDate,
            startTime: _selectedTime!,
            durationHours: _selectedDuration,
          ),
        );
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
            // Navigate to payment page using GoRouter
            context.push(
              RouteConstants.payment,
              extra: {
                'bookingId': state.booking.id,
                'amount': state.booking.price,
              },
            );
          } else if (state is BookingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is SlotsLoaded) {
            setState(() {
              _availableSlots = state.slots;
              _selectedTime = null;
            });
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 24),
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Simple date picker - can be replaced with table_calendar
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedTime = null;
                      });
                      _loadSlots();
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
                          DateFormatters.formatDisplayDate(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
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
                            _loadSlots();
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
                            _loadSlots();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Available Time Slots',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (state is BookingsLoading)
                  const LoadingWidget()
                else if (state is BookingsError)
                  ErrorDisplayWidget(
                    message: state.message,
                    onRetry: _loadSlots,
                  )
                else if (_availableSlots.isEmpty)
                  const Text('No available slots for this date')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSlots.map((slot) {
                      final isSelected = _selectedTime == slot.time;
                      return FilterChip(
                        label: Text(slot.time),
                        selected: isSelected,
                        onSelected: slot.available
                            ? (selected) {
                                setState(() {
                                  _selectedTime = selected ? slot.time : null;
                                });
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state is BookingsLoading ? null : _createBooking,
                    child: state is BookingsLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            'Book for Rs. ${(_selectedDuration == 2 ? widget.ground.price2hr : widget.ground.price3hr).toStringAsFixed(0)}',
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

