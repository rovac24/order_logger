import 'package:intl/intl.dart';

class ParsedInvoice {
  final String invoiceNumber;
  final String customerName;
  final String licenseNumber;
  final String state;
  final DateTime orderPlacedDate;
  final double totalDue;
  final String payTo;

  ParsedInvoice({
    required this.invoiceNumber,
    required this.customerName,
    required this.licenseNumber,
    required this.state,
    required this.orderPlacedDate,
    required this.totalDue,
    required this.payTo,
  });
}

ParsedInvoice parseInvoice(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  String? invoiceNumber;
  String? customerName;
  String? licenseNumber;
  String? state;
  DateTime? orderPlacedDate;
  double? totalDue;
  String? payTo;

  final stateRegex = RegExp(r',\s([A-Z]{2})\s\d{5}');

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // ----------------------------
    // Invoice number (#123 or #INV-123)
    // ----------------------------
    if (invoiceNumber == null &&
        RegExp(r'^#(INV-)?\d+').hasMatch(line)) {
      invoiceNumber = line.replaceAll('#', '');
    }

    // ----------------------------
    // Customer name
    // ----------------------------
    if (line == 'Customer' && i + 1 < lines.length) {
      customerName = lines[i + 1];
    }

    // ----------------------------
    // License number
    // ----------------------------
    if (line.startsWith('License #') && i + 1 < lines.length) {
      licenseNumber = lines[i + 1];
    }

    // ----------------------------
    // Order placed date
    // ----------------------------
    if (line == 'Order Placed Date' && i + 1 < lines.length) {
      orderPlacedDate = _parseInvoiceDateUtc(lines[i + 1]);
    }

    // ----------------------------
    // Total due
    // ----------------------------
    if (line == 'Total Due' && i + 1 < lines.length) {
      totalDue = double.tryParse(
        lines[i + 1].replaceAll(RegExp(r'[^0-9.]'), ''),
      );
    }

    // ----------------------------
    // State (from address line)
    // ----------------------------
    if (state == null) {
      final match = stateRegex.firstMatch(line);
      if (match != null) {
        state = match.group(1);
      }
    }

    // ----------------------------
    // Pay to the order of
    // ----------------------------
    if (line == 'PAY TO THE ORDER OF' && i + 1 < lines.length) {
      final next = lines[i + 1].toUpperCase();

      if (next.contains('GTI') ||
          next.contains('GREEN THUMB')) {
        payTo = 'GTI';
      } else if (next.contains('ASCEND')) {
        payTo = 'Ascend';
      }
    }
  }

  // ----------------------------
  // Validation
  // ----------------------------
  final missing = <String>[];
  if (invoiceNumber == null) missing.add('invoiceNumber');
  if (customerName == null) missing.add('customerName');
  if (licenseNumber == null) missing.add('licenseNumber');
  if (state == null) missing.add('state');
  if (orderPlacedDate == null) missing.add('orderPlacedDate');
  if (totalDue == null) missing.add('totalDue');
  if (payTo == null) missing.add('payTo');

  if (missing.isNotEmpty) {
    throw FormatException('Missing required fields: ${missing.join(', ')}');
  }

  return ParsedInvoice(
    invoiceNumber: invoiceNumber!,
    customerName: customerName!,
    licenseNumber: licenseNumber!,
    state: state!,
    orderPlacedDate: orderPlacedDate!,
    totalDue: totalDue!,
    payTo: payTo!,
  );
}

// ===================================================================
// Date parsing (AM/PM safe, web-safe)
// ===================================================================
DateTime? _parseInvoiceDateUtc(String raw) {
  try {
    final cleaned = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' a.m.', ' AM')
        .replaceAll(' p.m.', ' PM')
        .replaceAll(' am', ' AM')
        .replaceAll(' pm', ' PM')
        .replaceAll('.', '')
        .trim();

    final format = DateFormat('MMM d, yyyy h:mm:ss a');
    final local = format.parse(cleaned);

    return local.toUtc();
  } catch (_) {
    return null;
  }
}