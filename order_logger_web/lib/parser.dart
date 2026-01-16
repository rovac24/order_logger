import 'package:intl/intl.dart';

class ParsedInvoice {
  final String invoiceNumber;
  final String customerName;
  final String licenseNumber;
  final String state;
  final String orderPlacedDate;
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

  String invoiceNumber = '';
  String customerName = '';
  String licenseNumber = '';
  String state = '';
  String orderPlacedDate = '';
  double totalDue = 0;
  String payTo = '';

  final stateRegex = RegExp(r',\s([A-Z]{2})\s\d{5}');

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // ----------------------------
    // Invoice number (#123 or #INV-123)
    // ----------------------------
    if (invoiceNumber.isEmpty &&
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
      ) ??
      0;
    }

    // ----------------------------
    // State (from address line)
    // ----------------------------
    if (state.isEmpty) {
      final match = stateRegex.firstMatch(line);
      if (match != null) {
        state = match.group(1) ?? '';
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

  return ParsedInvoice(
    invoiceNumber: invoiceNumber,
    customerName: customerName,
    licenseNumber: licenseNumber,
    state: state,
    orderPlacedDate: orderPlacedDate,
    totalDue: totalDue,
    payTo: payTo,
  );
}

// ===================================================================
// Date parsing (AM/PM safe, web-safe)
// ===================================================================
String _parseInvoiceDateUtc(String raw) {
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
    final formatted = formatUtcPretty(local);

    return formatted;
  } catch (_) {
    return '';
  }
}

String formatUtcPretty(DateTime utc) {
  final month = DateFormat('MMMM').format(utc);
  final day = utc.day;
  final year = utc.year;
  final time = DateFormat('h:mm a').format(utc);

  return '$month ${_ordinal(day)}, $year at $time UTC';
}

String _ordinal(int number) {
  if (number >= 11 && number <= 13) return '${number}th';

  switch (number % 10) {
    case 1:
      return '${number}st';
    case 2:
      return '${number}nd';
    case 3:
      return '${number}rd';
    default:
      return '${number}th';
  }
}
