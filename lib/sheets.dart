import 'dart:convert';

import 'package:http/http.dart' as http;
import 'parser.dart';

const String sheetUrl =
    'https://script.google.com/macros/s/AKfycbzOm0oM7Wlo-ViJjtHgaQ4YToYsL2VhfXRanhOfQHDditPk2B4FZxKs2LHXXCFYvpxsvg/exec';

/// Asks the Apps Script backend whether an invoice with this number and
/// customer name has already been logged on the sheet.
///
/// Returns `false` (rather than throwing) if the check itself fails, so a
/// backend hiccup never blocks a legitimate upload.
// Future<bool> checkDuplicateInvoice(ParsedInvoice p) async {
//   final uri = Uri.parse(sheetUrl).replace(queryParameters: {
//     'action': 'checkDuplicate',
//     'invoice': p.invoiceNumber,
//     'customer': p.customerName,
//   });

//   final res = await http.get(uri);
//   if (res.statusCode != 200) {
//     return false;
//   }

//   try {
//     final body = jsonDecode(res.body) as Map<String, dynamic>;
//     return body['duplicate'] == true;
//   } catch (_) {
//     return false;
//   }
// }

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