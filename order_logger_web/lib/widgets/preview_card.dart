import 'package:flutter/material.dart';
import '../models.dart';

class PreviewCard extends StatelessWidget {
  final InvoiceData data;

  const PreviewCard(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Invoice #: ${data.invoiceNumber}"),
            Text("Customer: ${data.customerName}"),
            Text("License: ${data.licenseNumber}"),
            Text("Total Due: \$${data.totalDue}"),
            Text("State: ${data.state}"),
            Text("Order UTC: ${data.orderDateUtc}"),
            Text("Pay To: ${data.payToEntity}"),
          ],
        ),
      ),
    );
  }
}