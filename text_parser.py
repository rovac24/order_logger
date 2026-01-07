import re
from dateutil import parser, tz

def extract_invoice_from_text(text: str) -> dict:
    data = {}

    clean = re.sub(r'\r', '', text)

    # Invoice number
    m = re.search(r"#(\d{6,})", clean)
    if m:
        data["invoice_number"] = m.group(1)

    # Customer name
    m = re.search(
        r"Customer\s+([A-Za-z0-9\-\&\'\.\s]+?)(?=\s+License|\nLicense)",
        clean,
        re.I
    )
    if m:
        data["customer_name"] = m.group(1).strip()

    # License number
    m = re.search(r"License\s*#:\s*([A-Z0-9\-\.]+)", clean, re.I)
    if m:
        data["license_number"] = m.group(1)

    # Total due
    m = re.search(r"Total\s+Due\s*\$([\d,]+\.\d{2})", clean, re.I)
    if m:
        data["total_due"] = m.group(1).replace(",", "")

    # Order placed date → UTC
    m = re.search(
        r"Order\s+Placed\s+Date\s+([A-Za-z]{3}\.\s+\d{1,2},\s+\d{4}\s+\d{1,2}:\d{2}:\d{2}\s+[ap]\.m\.\s+[A-Z]{3})",
        clean,
        re.I
    )
    if m:
        raw_date = m.group(1)

        tz_map = {
            "EST": tz.gettz("America/New_York"),
            "EDT": tz.gettz("America/New_York"),
            "CST": tz.gettz("America/Chicago"),
            "CDT": tz.gettz("America/Chicago"),
        }

        dt = parser.parse(raw_date, tzinfos=tz_map)
        data["order_date_utc"] = dt.astimezone(tz.UTC).isoformat().replace("+00:00", "Z")

    # State (from shipping or billing)
    m = re.search(r",\s*([A-Z]{2})\s+\d{5}", clean)
    if m:
        data["state"] = m.group(1)

    return data
