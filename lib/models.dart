class InvoiceData {
  InvoiceData({
    required this.invoiceNumber,
    required this.customerName,
    required this.licenseNumber,
    required this.totalDue,
    required this.state,
    required this.orderDateUtc,
    required this.payToEntity,
  });
  
  final String invoiceNumber;
  final String customerName;
  final String licenseNumber;
  final String totalDue;
  final String state;
  final String orderDateUtc;
  final String payToEntity;
}