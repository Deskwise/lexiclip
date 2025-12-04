import json
import os
from datetime import datetime
from typing import List, Dict

HISTORY_FILE = os.path.expanduser("~/.local/share/pocr/history.json")

def load_history() -> List[Dict]:
    """Loads history from JSON file."""
    if not os.path.exists(HISTORY_FILE):
        return []
    try:
        with open(HISTORY_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading history: {e}")
        return []

def save_history(history: List[Dict]):
    """Saves history to JSON file."""
    try:
        os.makedirs(os.path.dirname(HISTORY_FILE), exist_ok=True)
        with open(HISTORY_FILE, 'w') as f:
            json.dump(history, f, indent=2)
    except Exception as e:
        print(f"Error saving history: {e}")

def add_entry(text: str):
    """Adds a new entry to history and trims to size."""
    history = load_history()
    # Format: 2:45p 12/3/25
    now = datetime.now()
    # %I is 01-12, %-I is 1-12 (linux). %p is AM/PM. 
    # We want lowercase p/a, so we'll post-process or just use %p and accept upper case for now, 
    # or use a custom format string.
    # Let's try to match the user request exactly: "2:45p 12/3/25"
    
    # Using %-I for no-pad hour, %M for minute.
    # %p gives AM/PM. We can lower() it and take the first char? Or just "p"/"a".
    # User said "2:45p".
    
    am_pm = now.strftime("%p").lower()[0] # 'a' or 'p'
    date_str = f"{now.strftime('%-I:%M')}{am_pm} {now.strftime('%-m/%-d/%y')}"

    entry = {
        "timestamp": date_str,
        "text": text,
        "snippet": text[:50].replace("\n", " ") + ("..." if len(text) > 50 else "")
    }
    history.insert(0, entry)
    # Keep only last 10 entries as per PRD
    history = history[:10]
    save_history(history)

def clear_history():
    """Clears all history."""
    save_history([])
