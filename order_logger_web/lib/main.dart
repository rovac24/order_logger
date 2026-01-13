import 'package:flutter/material.dart';
import 'parser.dart';
import 'sheets.dart';
import 'widgets/preview_card.dart';

void main() {
  runApp(const OrderLoggerApp());
}

class OrderLoggerApp extends StatelessWidget {
  const OrderLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Logger',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = TextEditingController();
  String uploadedBy = "Unknown";
  String edits = "No";
  var parsed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Logger")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: "Paste invoice text",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  parsed = parseInvoice(controller.text);
                });
              },
              child: const Text("Preview"),
            ),
            if (parsed != null) PreviewCard(parsed),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: parsed == null
                  ? null
                  : () async {
                      await uploadInvoice(parsed, uploadedBy, edits);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Uploaded successfully")),
                      );
                    },
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }
}