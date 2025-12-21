import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Note: url_launcher for payment URLs
import '../bloc/payments_bloc.dart';
import '../bloc/payments_event.dart';
import '../bloc/payments_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentPage extends StatelessWidget {
  final String bookingId;
  final double amount;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: BlocConsumer<PaymentsBloc, PaymentsState>(
        listener: (context, state) {
          if (state is PaymentInitiated) {
            if (state.payment.paymentUrl != null) {
              _launchPaymentUrl(context, state.payment.paymentUrl!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment initiated successfully')),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is PaymentsLoading) {
            return const LoadingWidget(message: 'Processing payment...');
          }

          if (state is PaymentsError) {
            return ErrorDisplayWidget(
              message: state.message,
              onRetry: () {
                // Retry logic can be added
              },
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Amount to Pay',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rs. ${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _PaymentMethodCard(
                  icon: Icons.phone_android,
                  title: 'JazzCash',
                  onTap: () {
                    context.read<PaymentsBloc>().add(
                          InitiatePaymentEvent(
                            bookingId: bookingId,
                            gateway: PaymentGateway.jazzcash,
                          ),
                        );
                  },
                ),
                const SizedBox(height: 12),
                _PaymentMethodCard(
                  icon: Icons.phone_android,
                  title: 'EasyPaisa',
                  onTap: () {
                    context.read<PaymentsBloc>().add(
                          InitiatePaymentEvent(
                            bookingId: bookingId,
                            gateway: PaymentGateway.easypaisa,
                          ),
                        );
                  },
                ),
                const SizedBox(height: 12),
                _PaymentMethodCard(
                  icon: Icons.credit_card,
                  title: 'Card',
                  onTap: () {
                    context.read<PaymentsBloc>().add(
                          InitiatePaymentEvent(
                            bookingId: bookingId,
                            gateway: PaymentGateway.card,
                          ),
                        );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchPaymentUrl(BuildContext context, String url) async {
    // Payment URL handling - can be enhanced with url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment URL: $url')),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

