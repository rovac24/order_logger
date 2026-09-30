import 'dart:convert';
import 'package:http/http.dart' as http;
import 'parser.dart';

const String sheetUrl =
    'https://script.google.com/macros/s/AKfycbyLUs-qeujwDZQUEkBZn_w8sSahSX59m2WHmZ4jRojQxoS73P00QqcSXJ85k94xChCQDg/exec';

// Apps Script executions can be slow under load (large sheet scans,
// concurrent users). Without a timeout, a hung request leaves the caller
// awaiting forever — the UI stays stuck showing "Sending..." with no way
// to retry. Failing fast surfaces a clear error instead.
const Duration _requestTimeout = Duration(seconds: 20);

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

  http.Response res;
  try {
    res = await http.get(uri).timeout(_requestTimeout);
  } catch (_) {
    return DuplicateCheckResult(isDuplicate: false);
  }
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

  final res = await http.get(uri).timeout(_requestTimeout);
  if (res.statusCode != 200) {
    throw Exception('Update failed: ${res.body}');
  }

  final body = jsonDecode(res.body) as Map<String, dynamic>;
  if (body['updated'] != true) {
    throw Exception('Update failed: no matching row found');
  }
}

/// Submits a new order. Returns a [DuplicateCheckResult] with
/// `isDuplicate: true` if the Apps Script backend re-checked at write time
/// and found this invoice already on the sheet (e.g. the caller's earlier
/// `checkDuplicateInvoice` call raced with another submission) — in that
/// case nothing was written, and the caller should resolve it the same way
/// as an upfront duplicate (confirm + updateInvoiceRow). A result with
/// `isDuplicate: false` means the row was appended successfully.
Future<DuplicateCheckResult> uploadToSheets(
  ParsedInvoice p,
  String selectedUploader,
) async {
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

  final res = await http.get(uri).timeout(_requestTimeout);

  if (res.statusCode != 200) {
    throw Exception('Upload failed: ${res.body}');
  }

  final body = jsonDecode(res.body) as Map<String, dynamic>;
  if (body['status'] == 'duplicate') {
    final existingTotal = body['existingTotal'];
    return DuplicateCheckResult(
      isDuplicate: true,
      existingCustomer: body['existingCustomer'] as String?,
      existingTotal: existingTotal is num ? existingTotal.toDouble() : null,
    );
  }

  return DuplicateCheckResult(isDuplicate: false);
}