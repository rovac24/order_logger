import 'dart:convert';
import 'package:http/http.dart' as http;
import 'parser.dart';

const String sheetUrl =
    'https://script.google.com/macros/s/AKfycbzW4AMJm-OBL7ES8sugMxKTtdewMHCwMzLoODrAQfcWxZn4k91vrm8R2EYTeTL8eoYAOQ/exec';

/// Result of a duplicate check: whether a match was found, and — if so —
/// the customer name and total currently on that row, so callers can tell
/// whether an update would actually change anything.
class DuplicateCheckResult {
  DuplicateCheckResult({
    required this.isDuplicate,
    this.existingCustomer,
    this.existingTotal,
  });

  final bool isDuplicate;
  final String? existingCustomer;
  final double? existingTotal;
}

/// Asks the Apps Script backend whether an invoice with this number has
/// already been logged on the sheet.
///
/// Returns a non-duplicate result (rather than throwing) if the check
/// itself fails, so a backend hiccup never blocks a legitimate upload.
Future<DuplicateCheckResult> checkDuplicateInvoice(ParsedInvoice p) async {
  final uri = Uri.parse(sheetUrl).replace(queryParameters: {
    'action': 'checkDuplicate',
    'invoice': p.invoiceNumber,
  });

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    return DuplicateCheckResult(isDuplicate: false);
  }

  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['duplicate'] != true) {
      return DuplicateCheckResult(isDuplicate: false);
    }
    final existingTotal = body['existingTotal'];
    return DuplicateCheckResult(
      isDuplicate: true,
      existingCustomer: body['existingCustomer'] as String?,
      existingTotal: existingTotal is num ? existingTotal.toDouble() : null,
    );
  } catch (_) {
    return DuplicateCheckResult(isDuplicate: false);
  }
}

/// Updates the customer name and Dollar Amount (total) on the most recent
/// existing row that matches this invoice's number, instead of appending a
/// new row. Used when the user confirms a duplicate should overwrite the
/// existing entry rather than create another one.
Future<void> updateInvoiceRow(ParsedInvoice p) async {
  final uri = Uri.parse(sheetUrl).replace(queryParameters: {
    'action': 'updateInvoiceRow',
    'invoice': p.invoiceNumber,
    'customer': p.customerName,
    'total': p.totalDue.toString(),
  });

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('Update failed: ${res.body}');
  }

  final body = jsonDecode(res.body) as Map<String, dynamic>;
  if (body['updated'] != true) {
    throw Exception('Update failed: no matching row found');
  }
}

Future<void> uploadToSheets(ParsedInvoice p, String selectedUploader) async {
  final uri = Uri.parse(sheetUrl).replace(queryParameters: {
    'invoice': p.invoiceNumber,
    'state': p.state,
    'customer': p.customerName,
    'edits': 'No',
    'submittedBy': selectedUploader,
    'dateUtc': p.orderPlacedDate,
    'total': p.totalDue.toString(),
    'license': p.licenseNumber,
    'payTo': p.payTo,
  });

  final res = await http.get(uri);

  if (res.statusCode != 200) {
    throw Exception('Upload failed: ${res.body}');
  }
}