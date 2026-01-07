import os
import sys
from datetime import datetime, timezone

from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from google.auth.transport.requests import Request

# ================== GOOGLE CONFIG ==================
SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]
SPREADSHEET_ID = "15o4CAQ1Z8TE3xF82F0PEPJ3eiKNqAfQbLvwoFbpdzvY"
SHEET_NAME = "Sheet1"

# ================== PATH HANDLING ==================
def resource_path(relative_path):
    """
    Get absolute path to resource (works for script & PyInstaller exe)
    """
    if getattr(sys, "frozen", False):
        base_path = sys._MEIPASS
    else:
        base_path = os.path.dirname(os.path.abspath(__file__))

    return os.path.join(base_path, relative_path)

# credentials.json → bundled in EXE
CREDENTIALS_FILE = resource_path("credentials.json")

# token.json → user-writable location
TOKEN_FILE = os.path.join(
    os.path.expanduser("~"),
    ".invoice_uploader_token.json"
)

# ================== GOOGLE SERVICE ==================
def get_sheets_service():
    creds = None

    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                CREDENTIALS_FILE, SCOPES
            )
            creds = flow.run_local_server(port=0)

        with open(TOKEN_FILE, "w", encoding="utf-8") as token:
            token.write(creds.to_json())

    return build("sheets", "v4", credentials=creds)

# ================== APPEND ROW ==================
def append_invoice_row(service, data: dict):
    timestamp_utc = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")

    row = [
        data.get("invoice_number", ""),        # A Invoice Number
        data.get("state", ""),                 # B State
        data.get("customer_name", ""),         # C Customer Name
        data.get("edits_required", ""),        # D Edits Required
        data.get("uploaded_by", ""),           # E Uploaded By
        timestamp_utc,                         # F Timestamp UTC
        data.get("total_due", ""),             # G Total Due
        data.get("license_number", ""),        # H License Number
    ]

    body = {"values": [row]}

    service.spreadsheets().values().append(
        spreadsheetId=SPREADSHEET_ID,
        range=f"{SHEET_NAME}!A:H",
        valueInputOption="USER_ENTERED",
        insertDataOption="INSERT_ROWS",
        body=body,
    ).execute()