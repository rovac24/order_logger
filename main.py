from text_parser import extract_invoice_from_text
from google_sheets import get_sheets_service, append_invoice_row

def main():
    print("📋 Paste invoice text below. Press ENTER twice when done:\n")

    lines = []
    while True:
        line = input()
        if line == "":
            break
        lines.append(line)

    text = "\n".join(lines)

    data = extract_invoice_from_text(text)

    print("✅ Extracted fields:", data)

    if not data:
        print("⚠ No data extracted.")
        return

    service = get_sheets_service()
    append_invoice_row(service, data)

if __name__ == "__main__":
    main()