import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_logger_web/sheets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:web/web.dart' as web;
import 'parser.dart';
import 'version_check.dart';

const Duration _versionCheckInterval = Duration(minutes: 5);

// Keep in sync with the `version:` field in pubspec.yaml.
const String appVersion = '1.0.0+1';

void main() {
  tz.initializeTimeZones();
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
  const OrderLoggerPage({
    super.key,
    required this.darkMode,
    required this.onToggleTheme,
  });

  final bool darkMode;
  final VoidCallback onToggleTheme;

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

  String? _loadedCommit;
  bool _updateAvailable = false;
  Timer? _versionCheckTimer;

  final List<String> sopsteam = [
  'Angel Daniel Di Alonzo Torres',
  'Arturo Juarez',
  'David Salazar',
  'Dusan Markovic',
  'Ernesto Salazar Alejos',
  'Juan Bayer',
  'Laura Martinez',
  'Maria Camila Gonzalez Montenegro',
  'Mariam Gogia',
  'Melody Choc',
  'Miguel Barreto Diaz',
  'Ognjen Petrovic',
  'Paola Castañon',
  'Rodolfo Valdez',
  'Ruben Ohanyan',
  'Ruben Hernández Alvarado',
  'Teodora Ljubičić Mijić',
];

  @override
  void initState() {
    super.initState();
    _loadUploaderName();
    _initVersionCheck();

    uploaderController.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'uploadedBy',
        uploaderController.text.trim(),
      );
    });
  }

  Future<void> _initVersionCheck() async {
    final commit = await fetchDeployedCommit();
    if (!mounted) return;
    setState(() => _loadedCommit = commit);
    if (commit == null) {
      // No build_info.json (e.g. local dev run) — nothing to compare against.
      return;
    }
    _versionCheckTimer = Timer.periodic(
      _versionCheckInterval,
      (_) => _checkForNewVersion(),
    );
  }

  Future<void> _checkForNewVersion() async {
    if (_updateAvailable) return;
    final latestCommit = await fetchDeployedCommit();
    if (latestCommit == null || latestCommit == _loadedCommit) {
      return;
    }
    _versionCheckTimer?.cancel();
    if (!mounted) return;
    setState(() => _updateAvailable = true);
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Text(
          'A new version of Order Logger is available.',
        ),
        leading: const Icon(Icons.system_update),
        actions: [
          TextButton(
            onPressed: () => web.window.location.reload(),
            child: const Text('Refresh now'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _versionCheckTimer?.cancel();
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
      if (parsed == null) {
        status = '';
        return;
      }
      final missing = missingFields(parsed!);
      if (missing.isNotEmpty) {
        status = '❌ Missing: ${missing.join(", ")}';
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
    final missing = missingFields(parsed!);
    if (missing.isNotEmpty) {
      setState(() {
        status = '❌ Missing: ${missing.join(", ")}';
      });
      return;
    }
    setState(() {
      isUploading = true;
      status = '⏳ Upload started...'; //status = '⏳ Checking for duplicates...';
      error = null;
    });

    final duplicateCheck = await checkDuplicateInvoice(parsed!);
    if (duplicateCheck.isDuplicate) {
      final existingTotal = duplicateCheck.existingTotal;
      final amountUnchanged = existingTotal != null &&
          (existingTotal - parsed!.totalDue).abs() < 0.005;
      if (amountUnchanged) {
        setState(() {
          isUploading = false;
          status = '⚠ Already logged with the same total — No changes made';
        });
        return;
      }

      final shouldUpdate = await _confirmDuplicateUpload(existingTotal);
      if (shouldUpdate != true) {
        setState(() {
          isUploading = false;
          status = '⚠ Upload cancelled — duplicate';
        });
        return;
      }

      setState(() {
        status = '⏳ Updating existing entry...';
      });
      try {
        debugPrint('📤 Updating existing row amount...');
        await updateInvoiceAmount(parsed!);
        setState(() {
          // ✅ reset everything
          parsed = null;
          controller.clear();
          status = '✅ Existing entry updated';
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
          error = 'Update failed';
          status = '';
          isUploading = false;
        });
      }
      return;
    }

    setState(() {
      status = '⏳ Upload started...';
    });
    try {
      debugPrint('📤 Sending upload payload...');
      await uploadToSheets(parsed!, selectedUploader!);
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

  Future<bool?> _confirmDuplicateUpload(double? existingTotal) {
    final existingTotalText = existingTotal != null
        ? '\$${existingTotal.toStringAsFixed(2)}'
        : 'an unknown amount';
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Duplicate alert!'),
        content: Text(
          'Invoice #${parsed!.invoiceNumber} for ${parsed!.customerName} '
          'already appears to be on the sheet with a total of '
          '$existingTotalText \nDo you want to update it to '
          '\$${parsed!.totalDue.toStringAsFixed(2)}?',
          style: TextStyle(
            fontSize:
                (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update existing row'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Ops Order Logger', 
        style: TextStyle(fontSize: 24,
        fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
                const Text(
                  'Logged by:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
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
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    onPressed: clearAll,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.paste),
                    label: const Text('Paste'),
                    onPressed: pasteClipboard,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : upload,
                    icon: isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload, size: 24,),
                    label: Text(isUploading ? 'Sending...' : 'SEND', 
                    style: const TextStyle(fontSize: 18, 
                    fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: parsed == null ? Colors.blueGrey :
                      const Color.fromARGB(255, 105, 177, 24),
                      minimumSize: const Size(200, 56), // 👈 width x height
                      padding: const EdgeInsets.symmetric(horizontal: 24, 
                      vertical: 16),
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('                  Sending this:', 
                              style: TextStyle(fontSize: 18, 
                              fontWeight: FontWeight.w600)),
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
                    ),
                  ),
              ]),
        ),
            Positioned(
              left: 8,
              bottom: 4,
              child: Text(
                _loadedCommit != null
                    ? 'v$appVersion · ${_loadedCommit!.substring(0, 7)}'
                    : 'v$appVersion',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
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
          color: missing ? const Color.fromARGB(255, 221, 62, 149) : 
          const Color.fromARGB(255, 48, 105, 190),
          fontWeight: missing ? FontWeight.bold : null,
        ),
      ),
    );
  }

}

