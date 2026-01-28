import 'package:http/http.dart' as http;
import 'parser.dart';

const String sheetUrl =
    'https://script.google.com/macros/s/AKfycbyj-VEr6UKW2NJojUbPxQOwXha7-8qzENYn_WHKRtWWYKNxtWazth3c7HcSVBs4sSxP/exec';

Future<void> uploadToSheets(ParsedInvoice p, String? selectedUploader) async {
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