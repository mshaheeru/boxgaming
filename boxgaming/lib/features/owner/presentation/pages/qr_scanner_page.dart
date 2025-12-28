import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/owner_bloc.dart';
import '../bloc/owner_event.dart';
import '../../../../shared/widgets/loading_widget.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleQRCode(String code) {
    // Extract booking ID from QR code
    // QR code format: booking:{bookingId}
    if (code.startsWith('booking:')) {
      final bookingId = code.substring(8);
      // Navigate to booking details or show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned booking: $bookingId')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRCode(barcode.rawValue!);
                  controller.stop();
                  break;
                }
              }
            },
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  controller.start();
                },
                child: const Text('Start Scanning'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



