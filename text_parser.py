import re
from dateutil import parser, tz

def extract_customer_name(text: str) -> str:
    """
    Extract customer name from the CUSTOMER section.
    """
    customer_block = re.search(
        r"CUSTOMER\s+(.*?)(LICENSE\s*#:|LICENSE NAME:|SHIPPING|BILLING)",
        text,
        re.IGNORECASE | re.DOTALL
    )

    if not customer_block:
        return ""

    lines = [
        line.strip()
        for line in customer_block.group(1).splitlines()
        if line.strip()
    ]

    # Remove noise words
    blacklist = {
        "PAYMENT TERMS",
        "N/A",
        "LICENSE",
        "LICENSE NAME",
        "LOCATION EMAIL",
    }

    for line in lines:
        upper = line.upper()
        if not any(bad in upper for bad in blacklist):
            return line

    return ""

def extract_client(text: str) -> str:
    """
    Extract Pay To The Order Of entity.
    Returns 'GTI' or 'Ascend' (empty string if not found).
    """
    pattern = r"PAY TO THE ORDER OF\s*\n\s*([A-Za-z ]+)"

    match = re.search(pattern, text, re.IGNORECASE)
    if not match:
        return ""

    line = match.group(1).strip()

    if line.upper().startswith("GTI"):
        return "GTI"

    if line.upper().startswith("ASCEND"):
        return "Ascend"

    return ""

def extract_invoice_from_text(text: str) -> dict:
    data = {}

    clean = re.sub(r'\r', '', text)

    # Invoice number
    m = re.search(r"#(\d{6,})", clean)
    if m:
        data["invoice_number"] = m.group(1)

    # Customer name
    data["customer_name"] = extract_customer_name(text)
    # m = re.search(
    #     r"Customer\s+([A-Za-z0-9\-\&\'\.\s]+?)(?=\s+License|\nLicense)",
    #     clean,
    #     re.I
    # )
    # if m:
    #     data["customer_name"] = m.group(1).strip()

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

    #Client name
    data["client"] = extract_client(text)

    return data
