import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_model.dart';
import 'pdf_service.dart';

class EmailService {
  /// Generate PDF file for email attachment
  static Future<File> _generatePdfFile(InvoiceModel invoice) async {
    return PdfService.writeInvoicePdf(invoice);
  }

  /// Send invoice via email using mailto (opens default email client)
  static Future<bool> sendInvoiceByEmail(InvoiceModel invoice) async {
    try {
      // Prepare email details
      final recipient = invoice.buyerEmail.isNotEmpty ? invoice.buyerEmail : '';
      final subject = 'Invoice ${invoice.invoiceNo} - ${invoice.sellerName}';
      final body = _generateEmailBody(invoice);

      // Create mailto URL
      final emailUri = Uri(
        scheme: 'mailto',
        path: recipient,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return true;
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      throw Exception('Error sending email: $e');
    }
  }

  /// Share invoice via email (using share_plus which includes email option with attachment)
  static Future<void> shareInvoiceViaEmail(InvoiceModel invoice) async {
    try {
      final pdfFile = await _generatePdfFile(invoice);
      final subject = 'Invoice ${invoice.invoiceNo}';
      final text = _generateEmailBody(invoice);
      
      // Use share_plus which will show email as an option and allows attachment
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: text,
        subject: subject,
      );
    } catch (e) {
      throw Exception('Error sharing invoice: $e');
    }
  }

  /// Generate email body text
  static String _generateEmailBody(InvoiceModel invoice) {
    return '''
Dear ${invoice.buyerName.isNotEmpty ? invoice.buyerName : 'Valued Customer'},

Please find attached Invoice ${invoice.invoiceNo} dated ${invoice.invoiceDate.toString().split(' ')[0]}.

Invoice Details:
- Invoice No: ${invoice.invoiceNo}
- Date: ${invoice.invoiceDate.toString().split(' ')[0]}
- Total Amount: ₹${invoice.grandTotal.toStringAsFixed(2)}

Payment is due by ${invoice.dueDate.toString().split(' ')[0]}.

Thank you for your business!

Best regards,
${invoice.sellerName}
''';
  }
}

