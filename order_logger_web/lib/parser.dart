import 'package:intl/intl.dart';
import 'models.dart';

String extract(RegExp regex, String text) {
  final match = regex.firstMatch(text);
  return match != null ? match.group(1)!.trim() : '';
}

InvoiceData parseInvoice(String text) {
  final invoice = extract(RegExp(r'#(INV-?\d+|\d+)', caseSensitive: false), text);
  final customer = extract(RegExp(r'Customer\s+([\s\S]*?)License', caseSensitive: false), text)
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final license = extract(RegExp(r'License\s#:\s*([A-Z0-9.-]+)', caseSensitive: false), text);
  final total = extract(RegExp(r'\$([\d,]+\.\d{2})'), text);
  final state = extract(RegExp(r',\s([A-Z]{2})\s\d{5}'), text);

  final dateRaw = extract(
    RegExp(r'Order Placed Date\s+([A-Za-z0-9.,:\s]+(?:EST|EDT|CST|CDT|PST|PDT))'),
    text,
  );

  String orderUtc = "";
  if (dateRaw.isNotEmpty) {
    final dt = DateFormat("MMM. d, yyyy h:mm:ss a z").parse(dateRaw, true);
    orderUtc = dt.toUtc().toIso8601String();
  }

  final payToRaw = extract(
    RegExp(r'PAY TO THE ORDER OF\s+([A-Za-z ]+)', caseSensitive: false),
    text,
  );

  final payTo = payToRaw.toUpperCase().startsWith('GTI')
      ? 'GTI'
      : payToRaw.toUpperCase().startsWith('ASCEND')
          ? 'Ascend'
          : '';

  return InvoiceData(
    invoiceNumber: invoice,
    customerName: customer,
    licenseNumber: license,
    totalDue: total,
    state: state,
    orderDateUtc: orderUtc,
    payToEntity: payTo,
  );
}