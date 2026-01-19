import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_logger_web/sheets.dart';
import 'parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OrderLoggerApp());
}

class OrderLoggerApp extends StatefulWidget {
  const OrderLoggerApp({super.key});

  @override
  State<OrderLoggerApp> createState() => _OrderLoggerAppState();
}

class _OrderLoggerAppState extends State<OrderLoggerApp> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: darkMode ? ThemeData.light() : ThemeData.dark(),
      home: OrderLoggerPage(
        darkMode: darkMode,
        onToggleTheme: () => setState(() => darkMode = !darkMode),
      ),
    );
  }
}

class OrderLoggerPage extends StatefulWidget {
  final bool darkMode;
  final VoidCallback onToggleTheme;

  const OrderLoggerPage({
    super.key,
    required this.darkMode,
    required this.onToggleTheme,
  });

  @override
  State<OrderLoggerPage> createState() => _OrderLoggerPageState();
}

class _OrderLoggerPageState extends State<OrderLoggerPage> {
  final controller = TextEditingController();
  final uploaderController = TextEditingController();
  ParsedInvoice? parsed;
  String status = '';
  String? error;
  bool isUploading = false;
  String? selectedUploader;

  final List<String> sopsteam = [
  'Angel Alonzo',
  'Arturo Juarez',
  'Ayesha Reyes',
  'David Salazar',
  'Dusan Markovic',
  'Emily Funez',
  'Ernesto Salazar',
  'Juan Bayer',
  'Laura Martinez',
  'Miguel Barreto',
  'Ognjen Petrovic',
  'Paola Castañon',
  'Rodolfo Valdez',
  'Ruben Hernandez',
  'Teodora Ljubičić',
];

  @override
  void initState() {
    super.initState();
    _loadUploaderName();

    uploaderController.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'uploadedBy',
        uploaderController.text.trim(),
      );
    });
  }

  @override
  void dispose() {
    uploaderController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadUploaderName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedUploader = prefs.getString('uploadedBy');
    });
  }

  Future<void> _saveUploader(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uploadedBy', name);
  }

  void parseNow(String text) {
    setState(() {
      parsed = text.trim().isEmpty ? null : parseInvoice(text);
      final missing = missingFields(parsed!);
      if (missing.isNotEmpty) {
        setState(() {
          status = '❌ Missing: ${missing.join(", ")}';
        });
      } else {
        status = '✅ All good here ✅';
      }
    if (parsed != null) {
      debugPrint('--- PARSED DATA ---');
      debugPrint('Invoice: ${parsed!.invoiceNumber}');
      debugPrint('Customer: ${parsed!.customerName}');
      debugPrint('License: ${parsed!.licenseNumber}');
      debugPrint('Total: ${parsed!.totalDue}');
      debugPrint('State: ${parsed!.state}');
      debugPrint('DateUTC: ${parsed!.orderPlacedDate}');
      debugPrint('Pay To: ${parsed!.payTo}');
    }
  });
}

  Future<void> pasteClipboard() async {
    final data = await Clipboard.getData('text/plain');
    controller.text = data?.text ?? '';
    parseNow(controller.text);
    status = '';
  }

  void clearAll() {
    controller.clear();
    setState(() {
      parsed = null;
      status = '';
    });
  }

  List<String> missingFields(ParsedInvoice p) {
  final missing = <String>[];

  if (p.invoiceNumber.isEmpty) missing.add('Invoice Number');
  if (p.customerName.isEmpty) missing.add('Customer Name');
  if (p.licenseNumber.isEmpty) missing.add('License Number');
  if (p.totalDue < 0) missing.add('Total Due');
  if (p.state.isEmpty) missing.add('State');
  if (p.payTo.isEmpty) missing.add('Client');

  return missing;
}

  Future<void> upload() async {
    if (isUploading) return;
    if (selectedUploader == null) {
      setState(() => status = '⚠ Please select your name before uploading');
      return;
    }
    if (parsed == null) {
      setState(() => status = '❌ No invoice data to upload');
      return;
    }
    // Always parse current text before upload
    if (parsed == null && controller.text.trim().isNotEmpty) {
      parsed = parseInvoice(controller.text);
    }
    final missing = missingFields(parsed!);
    if (missing.isNotEmpty) {
      setState(() {
        status = '❌ Missing: ${missing.join(", ")}';
      });
      return;
    }
    setState(() {
      isUploading = true;
      status = '⏳ Upload started...';
      error = null;
    });
    try {
      debugPrint('📤 Sending upload payload...');
      await uploadToSheets(parsed!, selectedUploader);
      setState(() {
        // ✅ reset everything
        parsed = null;
        controller.clear();
        status = '✅ Upload complete';
        isUploading = false;
      });
        // optional: auto-clear success message after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => status = '');
          }
        });
      } catch (e) {
        setState(() {
          error = 'Upload failed';
          status = '';
          isUploading = false;
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Ops Order Logger', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
              Text(
                'Logged by:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedUploader,
                hint: const Text('Select your name'),
                items: sopsteam
                    .map(
                      (name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedUploader = value);
                  _saveUploader(value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 10,
                onChanged: parseNow,
                decoration: const InputDecoration(
                  labelText: 'Paste invoice data here',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
            
              Row(children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste'),
                  onPressed: pasteClipboard,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  onPressed: clearAll,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: isUploading ? null : upload,
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload, size: 24,),
                  label: Text(isUploading ? 'Sending...' : 'SEND', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: parsed == null ? Colors.blueGrey : const Color.fromARGB(255, 105, 177, 24),
                    minimumSize: const Size(200, 56), // 👈 width x height
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                  ),
                ),
                ),
              ]),
            
              const SizedBox(height: 12),            
              if (status.isNotEmpty)
                Text(status,
                    style: TextStyle(
                        color: status.startsWith('✅')
                            ? Colors.green
                            : const Color.fromARGB(255, 221, 62, 149))),
            
              const SizedBox(height: 12),            
              if (parsed != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('                Sending this:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        row('Invoice', parsed!.invoiceNumber),
                        row('Customer', parsed!.customerName),
                        row('License', parsed!.licenseNumber),
                        row('Total', parsed!.totalDue.toStringAsFixed(2)),
                        row('Order UTC', parsed!.orderPlacedDate),
                        row('State', parsed!.state),
                        row('Client', parsed!.payTo),
                      ],
                    ),
                  ),
                ),
            ]),
      ),
    );
  }

  Widget row(String label, String value) {
    final missing = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: ${missing ? "⚠ Missing" : value}',
        style: TextStyle(
          color: missing ? Color.fromARGB(255, 221, 62, 149) : const Color.fromARGB(255, 48, 105, 190),
          fontWeight: missing ? FontWeight.bold : null,
        ),
      ),
    );
  }
}