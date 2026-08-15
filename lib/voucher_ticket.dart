import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a simple voucher PDF using provided registration data.
/// The map keys used: student_name, email_address, phone_number, college,
/// event_title, event_venue, registered_at
Future<Uint8List> buildVoucherPdf(Map<String, dynamic> data) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Event Voucher',
                  style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text('Name: ${data['student_name'] ?? ''}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Email: ${data['email_address'] ?? ''}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Phone: ${data['phone_number'] ?? ''}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('College: ${data['college'] ?? ''}', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text('Event: ${data['event_title'] ?? ''}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Venue: ${data['event_venue'] ?? ''}', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 12),
              pw.Text('Registered At: ${data['registered_at'] ?? ''}', style: pw.TextStyle(fontSize: 12)),
              pw.Spacer(),
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Bring this voucher to the event.', style: pw.TextStyle(fontSize: 12)),
                      pw.SizedBox(height: 4),
                      pw.Text('— College Fest Team', style: pw.TextStyle(fontSize: 12)),
                    ],
                  )),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}
