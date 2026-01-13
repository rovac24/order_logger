import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

const spreadsheetId = "YOUR_SPREADSHEET_ID";
const sheetName = "Sheet1";
const apiKey = "YOUR_PUBLIC_API_KEY";

Future<void> uploadInvoice(InvoiceData data, String uploadedBy, String edits) async {
  final url =
      "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$sheetName!A1:append"
      "?valueInputOption=USER_ENTERED&key=$apiKey";

  final row = [
    data.invoiceNumber,
    data.state,
    data.customerName,
    edits,
    uploadedBy,
    DateTime.now().toUtc().toIso8601String(),
    data.totalDue,
    data.licenseNumber,
    data.payToEntity,
  ];

  await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"values": [row]}),
  );
}