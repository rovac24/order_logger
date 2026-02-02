import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class ParsedInvoice {
  ParsedInvoice({
    required this.invoiceNumber,
    required this.customerName,
    required this.licenseNumber,
    required this.state,
    required this.orderPlacedDate,
    required this.totalDue,
    required this.payTo,
  });
  
  final String invoiceNumber;
  final String customerName;
  final String licenseNumber;
  final String state;
  final String orderPlacedDate;
  final double totalDue;
  final String payTo;
}

const Map<String, String> stateNameToCode = {
  'ALABAMA': 'AL',
  'ALASKA': 'AK',
  'ARIZONA': 'AZ',
  'ARKANSAS': 'AR',
  'CALIFORNIA': 'CA',
  'COLORADO': 'CO',
  'CONNECTICUT': 'CT',
  'DELAWARE': 'DE',
  'FLORIDA': 'FL',
  'GEORGIA': 'GA',
  'HAWAII': 'HI',
  'IDAHO': 'ID',
  'ILLINOIS': 'IL',
  'INDIANA': 'IN',
  'IOWA': 'IA',
  'KANSAS': 'KS',
  'KENTUCKY': 'KY',
  'LOUISIANA': 'LA',
  'MAINE': 'ME',
  'MARYLAND': 'MD',
  'MASSACHUSETTS': 'MA',
  'MICHIGAN': 'MI',
  'MINNESOTA': 'MN',
  'MISSISSIPPI': 'MS',
  'MISSOURI': 'MO',
  'MONTANA': 'MT',
  'NEBRASKA': 'NE',
  'NEVADA': 'NV',
  'NEW HAMPSHIRE': 'NH',
  'NEW JERSEY': 'NJ',
  'NEW MEXICO': 'NM',
  'NEW YORK': 'NY',
  'NORTH CAROLINA': 'NC',
  'NORTH DAKOTA': 'ND',
  'OHIO': 'OH',
  'OKLAHOMA': 'OK',
  'OREGON': 'OR',
  'PENNSYLVANIA': 'PA',
  'RHODE ISLAND': 'RI',
  'SOUTH CAROLINA': 'SC',
  'SOUTH DAKOTA': 'SD',
  'TENNESSEE': 'TN',
  'TEXAS': 'TX',
  'UTAH': 'UT',
  'VERMONT': 'VT',
  'VIRGINIA': 'VA',
  'WASHINGTON': 'WA',
  'WEST VIRGINIA': 'WV',
  'WISCONSIN': 'WI',
  'WYOMING': 'WY',
};

ParsedInvoice parseInvoice(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  var invoiceNumber = '';
  var customerName = '';
  var licenseNumber = '';
  var state = '';
  var orderPlacedDate = '';
  double totalDue = 0;
  var payTo = '';

  final stateRegex = RegExp(r',\s([A-Z]{2})\s\d{5}');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // ----------------------------
    // Invoice number (#123 or #INV-123)
    // ----------------------------
    if (invoiceNumber.isEmpty &&
        RegExp(r'^#(INV-)?\d+').hasMatch(line)) {
      invoiceNumber = line.replaceAll('#', '');
    }

    // ----------------------------
    // Customer name
    // ----------------------------
    if (line == 'Customer' && i + 1 < lines.length) {
      customerName = lines[i + 1];
    }

    // ----------------------------
    // License number
    // ----------------------------
    if (line.startsWith('License #') && i + 1 < lines.length) {
      licenseNumber = lines[i + 1];
    }

    // ----------------------------
    // Order placed date
    // ----------------------------
    if (line == 'Order Placed Date' && i + 1 < lines.length) {
      orderPlacedDate = _parseInvoiceDateUtc(lines[i + 1]);
    }

    // ----------------------------
    // Total due
    // ----------------------------
    if (line == 'Total Due' && i + 1 < lines.length) {
      totalDue = double.tryParse(
        lines[i + 1].replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ??
      0;
    }

    // ----------------------------
    // State (from address line)
    // ----------------------------
    if (state.isEmpty) {
      // final match = stateRegex.firstMatch(line);
      // if (match != null) {
      //   state = match.group(1) ?? '';
      // }
      final upper = line.toUpperCase();

      // Case 1: City, NV 89014
      final shortMatch = stateRegex.firstMatch(upper);
      if (shortMatch != null) {
        state = shortMatch.group(1) ?? '';
      }

      // Case 2: City, Nevada 89014
      for (final entry in stateNameToCode.entries) {
        if (upper.contains('${entry.key} ') || upper.contains(', ${entry.key}')) {
          state = entry.value;
          break;
        }
      }

      // Case 3: Header hint like "GTI NV"
      if (state.isEmpty) {
        final headerMatch = RegExp(r'\b([A-Z]{2})\b').firstMatch(upper);
        if (headerMatch != null &&
            stateNameToCode.values.contains(headerMatch.group(1))) {
          state = headerMatch.group(1) ?? '';
        }
      }
    }

    // ----------------------------
    // Pay to the order of
    // ----------------------------
    if (line == 'PAY TO THE ORDER OF' && i + 1 < lines.length) {
      final next = lines[i + 1].toUpperCase();

      if (next.contains('GTI') ||
          next.contains('GREEN THUMB')) {
        payTo = 'GTI';
      } else if (next.contains('ASCEND')) {
        payTo = 'Ascend';
      }
    }
  }

  return ParsedInvoice(
    invoiceNumber: invoiceNumber,
    customerName: customerName,
    licenseNumber: licenseNumber,
    state: state,
    orderPlacedDate: orderPlacedDate,
    totalDue: totalDue,
    payTo: payTo,
  );
}

// ===================================================================
// Date parsing (AM/PM safe, web-safe)
// ===================================================================
String _parseInvoiceDateUtc(String raw) {
  try {
    // Extract timezone
    final tzMatch = RegExp(r'\s+(EST|EDT|PST|PDT|CST|CDT|MST|MDT)$', 
        caseSensitive: false).firstMatch(raw);
    final tzAbbr = tzMatch?.group(1)?.toUpperCase() ?? 'EST';
    
    // Remove timezone
    final withoutTz = raw.replaceAll(
        RegExp(r'\s+(EST|EDT|PST|PDT|CST|CDT|MST|MDT)$', caseSensitive: false), '');
    
    // Clean the date
    final cleaned = withoutTz
        .replaceAll('.', '')
        .replaceAllMapped(RegExp(r'(\d+)\s*(a\.?m\.?|p\.?m\.?)', caseSensitive: false),
            (m) => '${m.group(1)} ${m.group(2)!.replaceAll('.', '')
            .toUpperCase()}')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Parse date
    final format = DateFormat('MMM d, yyyy h:mm:ss a');
    final parsed = format.parse(cleaned);
    
    // Map abbreviations to IANA timezone names
    final tzMap = {
      'EST': 'America/New_York',
      'EDT': 'America/New_York',
      'PST': 'America/Los_Angeles', 
      'PDT': 'America/Los_Angeles',
      'CST': 'America/Chicago',
      'CDT': 'America/Chicago',
      'MST': 'America/Denver',
      'MDT': 'America/Denver',
    };
    
    final locationName = tzMap[tzAbbr] ?? 'America/New_York';
    final location = tz.getLocation(locationName);
    
    // CORRECT WAY: Create TZDateTime from components
    final zonedTime = tz.TZDateTime(
      location,
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
    
    // Convert to UTC
    final utcTime = zonedTime.toUtc();
    
    return formatUtcPretty(utcTime);
  } catch (e) {
    debugPrint('Error parsing "$raw": $e');
    return '';
  }  
}

String formatUtcPretty(DateTime utc) {
  final month = DateFormat('MMMM').format(utc);
  final day = utc.day;
  final year = utc.year;
  final time = DateFormat('h:mm a').format(utc);

  return '$month ${_ordinal(day)}, $year at $time UTC';
}

String _ordinal(int number) {
  if (number >= 11 && number <= 13) return '${number}th';

  switch (number % 10) {
    case 1:
      return '${number}st';
    case 2:
      return '${number}nd';
    case 3:
      return '${number}rd';
    default:
      return '${number}th';
  }
}
