from src.core import history
from datetime import datetime
import os

# Mock history file to avoid messing up real history
history.HISTORY_FILE = "/tmp/test_history.json"
if os.path.exists(history.HISTORY_FILE):
    os.remove(history.HISTORY_FILE)

print("Adding entry...")
history.add_entry("Test text")

entries = history.load_history()
print(f"Entries count: {len(entries)}")
if entries:
    print(f"Timestamp: {entries[0]['timestamp']}")
    # Verify format roughly
    ts = entries[0]['timestamp']
    print(f"Timestamp format check: {ts}")
