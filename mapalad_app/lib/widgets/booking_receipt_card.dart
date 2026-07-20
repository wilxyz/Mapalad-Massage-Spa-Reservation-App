import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../models/booking_model.dart';

class BookingReceiptCard extends StatelessWidget {
  final BookingModel booking;

  const BookingReceiptCard({super.key, required this.booking});

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _printTransaction(BuildContext context) async {
    final doc = pw.Document();
    final logoBytes = await rootBundle.load('assets/images/logo.jpg');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pwContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Image(logoImage, height: 50),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Mapalad Massage Spa Corporation',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Sa bawat oras ng pahinga-Mapalad Massage and Spa',
                        style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 8),
                _pdfRow('Service', booking.serviceName),
                _pdfRow('Price', booking.price.toStringAsFixed(2)),
                _pdfRow('Branch', booking.branchName),
                _pdfRow('Therapist', booking.therapistName ?? 'Any Therapist'),
                _pdfRow('Date', _formatDate(booking.appointmentDate)),
                _pdfRow('Time', booking.timeSlot),
                _pdfRow('Name', booking.fullName),
                _pdfRow('Phone', booking.contactNumber),
                _pdfRow('Email', booking.email ?? ''),
                if (booking.addOnName != null && booking.addOnName!.isNotEmpty)
                  _pdfRow('Add-On', booking.addOnName!),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightBrown.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Image.asset('assets/images/logo.jpg', height: 40),
              const SizedBox(height: 8),
              Text(
                'Mapalad Massage Spa Corporation',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                'Sa bawat oras ng pahinga-Mapalad Massage and Spa',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightBrown, fontStyle: FontStyle.italic, fontSize: 11),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          _row('Service', booking.serviceName),
          _row('Price', booking.price.toStringAsFixed(2)),
          _row('Branch', booking.branchName),
          _row('Therapist', booking.therapistName ?? 'Any Therapist'),
          _row('Date', _formatDate(booking.appointmentDate)),
          _row('Time', booking.timeSlot),
          _row('Name', booking.fullName),
          _row('Phone', booking.contactNumber),
          _row('Email', booking.email ?? ''),
          if (booking.addOnName != null && booking.addOnName!.isNotEmpty) _row('Add-On', booking.addOnName!),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _printTransaction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBrown,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Print Transaction',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.print_rounded, color: AppColors.darkBrown, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.lightBrown, fontSize: 15, fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}