import tkinter as tk
from tkinter import messagebox
import json
import sys
import os
from datetime import datetime, timezone

from text_parser import extract_invoice_from_text
from google_sheets import get_sheets_service, append_invoice_row

def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and PyInstaller """
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.abspath("."), relative_path)


# ---------------- USER MEMORY ----------------
USER_FILE = "user.json"


def load_user():
    if os.path.exists(USER_FILE):
        with open(USER_FILE, "r", encoding="utf-8") as f:
            return json.load(f).get("user", "")
    return ""


def save_user(user):
    with open(USER_FILE, "w", encoding="utf-8") as f:
        json.dump({"user": user}, f)


# ---------------- VALIDATION ----------------
def validate_invoice_data(data: dict) -> list:
    required_fields = {
        "invoice_number": "Invoice Number",
        "customer_name": "Customer Name",
        "license_number": "License Number",
        "total_due": "Total Due",
        "state": "State",
        "edits_required": "Edits Required",
        "uploaded_by": "Uploaded By",
    }

    missing = []
    for key, label in required_fields.items():
        if not data.get(key):
            missing.append(label)

    return missing


# ---------------- ACTIONS ----------------
def paste_from_clipboard():
    try:
        text = root.clipboard_get()
        text_box.delete("1.0", tk.END)
        text_box.insert(tk.END, text)
        status_var.set("📋 Pasted from clipboard")
        status_bar.config(bg="#e8f0fe")
    except tk.TclError:
        messagebox.showwarning("Clipboard Empty", "Clipboard does not contain text.")


def clear_fields():
    text_box.delete("1.0", tk.END)
    edits_var.set(value="__UNSET__")
    status_var.set("Cleared")
    status_bar.config(bg="#f0f0f0")


def process_and_upload():
    status_var.set("Processing...")
    status_bar.config(bg="#f0f0f0")
    root.update_idletasks()

    text = text_box.get("1.0", tk.END).strip()
    user = user_var.get().strip()

    if not user:
        messagebox.showwarning("User Required", "Please select or enter your name.")
        return

    if not text:
        messagebox.showwarning("Missing Data", "Please paste invoice text.")
        return

    save_user(user)

    data = extract_invoice_from_text(text)

    if not data or not any(data.values()):
        messagebox.showerror("Error", "No invoice data could be extracted.")
        return

    data["uploaded_by"] = user
    data["edits_required"] = edits_var.get()

    missing = validate_invoice_data(data)
    if missing:
        messagebox.showerror(
            "Missing Fields",
            "The following fields are missing:\n\n" + "\n".join(f"• {m}" for m in missing)
        )
        return

    try:
        service = get_sheets_service()
        append_invoice_row(service, data)

        status_var.set(f"✅ Uploaded invoice {data['invoice_number']}")
        status_bar.config(bg="#d4edda")

        clear_fields()

    except Exception as e:
        status_var.set("❌ Upload failed")
        status_bar.config(bg="#f8d7da")
        messagebox.showerror("Upload Failed", str(e))


# ---------------- UI ----------------
APP_BG = "#FFFFFF"
root = tk.Tk()
root.title("Sales Ops Order Logger")
root.geometry("360x620")
root.configure(bg=APP_BG)
root.iconbitmap(resource_path("icon.ico"))

frame = tk.Frame(root, bg=APP_BG)
frame.pack(padx=10, pady=10)

# Set window icon (Windows)
try:
    root.iconbitmap(resource_path("alien_icon.ico"))
except Exception as e:
    print("Icon load failed:", e)

# --- User Selection ---
user_var = tk.StringVar(value=load_user())

user_frame = tk.Frame(root)
user_frame.pack(fill="x", padx=10, pady=10, anchor="w")

tk.Label(user_frame, text="Logged by:", bg=APP_BG, font=("Consolas", 11, "bold")).pack(side="left", padx=(0,8))
tk.Entry(user_frame, textvariable=user_var, width=33, font=("Consolas", 10)).pack(side="left")

# --- Title ---
tk.Label(root, text="Paste invoice data here:", bg=APP_BG, font=("Consolas", 14, "bold")).pack(pady=5)

# --- Text Box ---
text_box = tk.Text(root, height=18, width=100, font=("Consolas", 10), wrap=tk.WORD)
text_box.pack(padx=10, pady=5)

# --- Buttons row ---
btn_frame = tk.Frame(root, bg=APP_BG)
btn_frame.pack(pady=8)

tk.Button(
    btn_frame,
    text="📋 Paste from Clipboard",
    command=paste_from_clipboard
).pack(side="left", padx=5)

tk.Button(
    btn_frame,
    text="🧹 Clear",
    command=clear_fields
).pack(side="left", padx=5)

# --- Edits Required ---
edits_var = tk.StringVar(value="__UNSET__")

edits_frame = tk.Frame(root)
edits_frame.pack(pady=10)

tk.Label(edits_frame, text="Edits required?", font=("Consolas", 11)).pack(side="left", padx=10)

tk.Radiobutton(edits_frame, text="YES", variable=edits_var, value="YES").pack(side="left")
tk.Radiobutton(edits_frame, text="NO", variable=edits_var, value="NO").pack(side="left")

# --- Upload Button ---
tk.Button(
    root,
    text="Process & Upload",
    font=("Consolas", 12, "bold"),
    bg="#75cc2e",
    fg="white",
    padx=20,
    pady=8,
    command=process_and_upload
).pack(pady=15)

# --- Status Bar ---
status_var = tk.StringVar(value="Ready")

status_bar = tk.Label(
    root,
    textvariable=status_var,
    anchor="w",
    relief="sunken",
    font=("Consolas", 10),
    bg="#f0f0f0",
    padx=10
)
status_bar.pack(side="bottom", fill="x")

# --- Auto-paste on startup ---
root.after(300, paste_from_clipboard)

root.mainloop()
