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

bool _isStreetAddress(String line) {
  // If it has a ZIP code, it's an address line we want to parse
  if (RegExp(r'\d{5}').hasMatch(line)) {
    return false; // DON'T skip lines with ZIP codes
  }
  
  final upper = line.toUpperCase();
  
  // Common street indicators
  final streetIndicators = [
    'ST ', ' AVE', ' AV ', 'ROAD', ' RD ', 
    'BOULEVARD', ' BLVD', 'LANE', ' LN ',
    'DRIVE', ' DR ', 'WAY', 'COURT', ' CT ',
    'PLACE', ' PL ', 'HIGHWAY', ' HWY',
    'SUITE', 'STE ', 'FLOOR', ' FL '
  ];
  
  return streetIndicators.any((s) => upper.contains(s)) ||
         RegExp(r'^\d+').hasMatch(line); // Starts with number
}

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
  var inAddressSection = false;
  var pacS = false;

  final stateRegex = RegExp(r',\s([A-Z]{2})\s\d{5}');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // ----------------------------
    // Invoice number (#123, 123, SO-123 or #INV-123)
    // ----------------------------
    if (invoiceNumber.isEmpty) {

      //Pacific Stone
      if (line.startsWith('INVOICE # ') && line.endsWith('-A')) {

        pacS = true;
        
        // Automatically set client to PacStone
        if (payTo.isEmpty) {
          payTo = 'Pacific Stone';
        }
        // Automatically set State to CA
        if (state.isEmpty) {
          state = 'CA';
        }
        // Order placed date - use current date and time
        // ----------------------------
        if (orderPlacedDate.isEmpty) {
          // Use current date and time
          final now = DateTime.now();
          orderPlacedDate = formatUtcPretty(now.toUtc());
        }
      } 
      // Check for SO- prefix first
      if (line.toUpperCase().startsWith('SO-')) {
        invoiceNumber = line.replaceAll(RegExp(r'[^0-9]'), '');
        
        // Automatically set client to Punch Edibles
        if (payTo.isEmpty) {
          payTo = 'Punch Edibles';
        }
        // Automatically set License to N/A
        if (licenseNumber.isEmpty) {
          licenseNumber = '-';
        }
      } 
      // Existing patterns
      else {
        final patterns = [
          RegExp(r'^#?(?:INV[-]?)?\d+'),  // #123, 123, #INV-123, INV-123
          RegExp(r'^(?:Invoice|Order)[\s#:-]+\d+', caseSensitive: false),
          RegExp(r'INV[-]?\d+', caseSensitive: false),
        ];
        
        for (final pattern in patterns) {
          if (pattern.hasMatch(line)) {
            invoiceNumber = line.replaceAll(RegExp(r'[^0-9]'), '');
            break;
          }
        }
      }
      // If still empty and it's the first line, take any numbers
      if (invoiceNumber.isEmpty && i == 0) {
        invoiceNumber = line.replaceAll(RegExp(r'[^0-9]'), '');
      }
    }
    // ----------------------------
    // Customer name
    // ----------------------------
    if (line == 'Customer' && i + 1 < lines.length) {
      customerName = lines[i + 1];
    }
    // ----------------------------
    // Customer name - from line after "RECIPIENT:"
    // Extract between "D.B.A." and "["
    // ----------------------------
    if (customerName.isEmpty && line.contains('RECIPIENT:')) {
      // Look at next few lines (up to 2 lines) to find the D.B.A. pattern
      // Start from next line and combine until we find the pattern
      var combinedText = '';
      for (var offset = 1; offset <= 2; offset++) {
        if (i + offset < lines.length) {
          combinedText += ' ${lines[i + offset]}';
          
          final dbaMatch = RegExp(r'D\.B\.A\.\s*(.*?)\s*\[').firstMatch(combinedText);
          if (dbaMatch != null) {
            customerName = dbaMatch.group(1)!.trim();
            break;
          }
        }
      }
    }
    // ----------------------------
    // License number
    // ----------------------------
    if (line.startsWith('License #') && i + 1 < lines.length) {
      licenseNumber = lines[i + 1];
    }
    // ----------------------------
        // License number - after first "License" word, before first "Address" word
        // ----------------------------
        if (licenseNumber.isEmpty && line.startsWith('License')) {
          // isLicenseSection = true;
          // Look for license number in this line
          final licenseMatch = RegExp(r'License\s+(\S+)').firstMatch(line);
          if (licenseMatch != null) {
            licenseNumber = licenseMatch.group(1)!;
          }
        }
    // ----------------------------
    // Order placed date
    // ----------------------------
    if (orderPlacedDate.isEmpty) {
    // Check for "Order Placed Date"
      if (line == 'Order Placed Date' && i + 1 < lines.length) {
        orderPlacedDate = _parseInvoiceDateUtc(lines[i + 1]);
      }
      // Check for "Created At" 
      else if (line == 'Created At' && i + 1 < lines.length) {
        // Get the date from the next line
        var dateStr = lines[i + 1];
        
        // Add PST timezone since we know Created At format is PST
        if (!dateStr.contains(RegExp(r'\s+(EST|PST|CST|MST|EDT|PDT|CDT|MDT)$', caseSensitive: false))) {
          dateStr = '$dateStr PST';
        }
    
    orderPlacedDate = _parseInvoiceDateUtc(dateStr);
  }
    }

    // ----------------------------
    // Total due
    // ----------------------------
    if (pacS = true) {
      final dollarMatch = RegExp(r'\$([\d,]+(?:\.\d{2})?)').firstMatch(line);
      if (dollarMatch != null) {
        final amountStr = dollarMatch.group(1)!.replaceAll(',', '');
        totalDue = double.tryParse(amountStr) ?? 0;
  }
    }
    else if ((line == 'Total Due' || line == 'Total') && i + 1 < lines.length) {
      totalDue = double.tryParse(
        lines[i + 1].replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ?? 0;
    }

    // ----------------------------
    // State (from address line)
    // ----------------------------
    if ((line == 'CONTACT') || (line == 'Billing Address') ||
    (line == 'SHIPPING')){
      inAddressSection = true;
      //continue;
    }
    // End of address section (next major section)
    if (inAddressSection && 
        (line == 'PAY TO THE ORDER OF' || 
        line == 'PAYMENT TERMS' || 
        line == 'Customer' || 
        line == 'Total Due')) {
      inAddressSection = false;
    }
    if (state.isEmpty && inAddressSection) {
      if (_isStreetAddress(line)) {
        continue;
      }
      final upper = line.toUpperCase();

      //Case 1: City, NV 89014
      final zipMatch = stateRegex.firstMatch(upper);
      if (zipMatch != null) {
        state = zipMatch.group(1) ?? '';
      }
      
      var stateMatch = RegExp(r',\s([A-Z]{2})(?:\s|$)').firstMatch(upper);
      if (stateMatch != null) {
        state = stateMatch.group(1) ?? '';
      }

      // Case 2: City, ST [anything else] pattern
      // This catches "Natick, MA Natick"
      stateMatch = RegExp(r',\s([A-Z]{2})\s').firstMatch(upper);
      if (stateMatch != null) {
        state = stateMatch.group(1) ?? '';
        // if (state != null && stateNameToCode.values.contains(state)) {
        //   return state;
        // }
      }

      // Case 3: City, Nevada 89014
      for (final entry in stateNameToCode.entries) {
        if (upper.contains('${entry.key} ') || 
        upper.contains(', ${entry.key}')) 
        {
          state = entry.value;
          break;
        }
      }
    }

    // ----------------------------
    // Pay to the order of
    // ----------------------------
    if (line == 'PAY TO THE ORDER OF' && i + 1 < lines.length) {
      final next = lines[i + 1].toUpperCase();

      if (next.contains('GTI') ||
          next.contains('GREEN THUMB') || 
          next.contains('FIORELLO PHARMACEUTICALS')) {
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
        .replaceAll('-', '')
        .replaceAllMapped(RegExp(r'(\d+)\s*(a\.?m\.?|p\.?m\.?)', caseSensitive: false),
            (m) => '${m.group(1)} ${m.group(2)!.replaceAll('.', '')
            .toUpperCase()}')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    DateTime parsed;
    // Parse date
    // TRY WITHOUT SECONDS FIRST
    try {
      final formatWithoutSeconds = DateFormat('MMM d, yyyy h:mm a');
      parsed = formatWithoutSeconds.parse(cleaned);
    } catch (_) {
      // If that fails, try WITH seconds
      final formatWithSeconds = DateFormat('MMM d, yyyy h:mm:ss a');
      parsed = formatWithSeconds.parse(cleaned);
    } 
    
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
