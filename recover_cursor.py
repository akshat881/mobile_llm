import os
import json
import shutil
from pathlib import Path

history_dir = os.path.expanduser("~/Library/Application Support/Cursor/User/History")
target_project_dir = os.path.expanduser("~/Documents/flutterProjects/lm_studio_mobile")

count = 0
for root, dirs, files in os.walk(history_dir):
    if "entries.json" in files:
        entries_path = os.path.join(root, "entries.json")
        try:
            with open(entries_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                resource = data.get("resource", "")
                if "lm_studio_mobile" in resource:
                    if resource.startswith("file://"):
                        file_path = resource[14:] if resource.startswith("file:////") else resource[7:]
                        
                        entries = data.get("entries", [])
                        if entries:
                            latest_entry = entries[-1]
                            latest_id = latest_entry.get("id")
                            source_file = os.path.join(root, latest_id)
                            
                            if os.path.exists(source_file):
                                rel_path = os.path.relpath(file_path, target_project_dir)
                                # Don't recover if it's not actually in our target dir
                                if not rel_path.startswith(".."):
                                    recovery_dest = os.path.join(target_project_dir, "cursor_recovery", rel_path)
                                    os.makedirs(os.path.dirname(recovery_dest), exist_ok=True)
                                    shutil.copy2(source_file, recovery_dest)
                                    count += 1
                                    print(f"Recovered to cursor_recovery/{rel_path}")
        except Exception as e:
            pass

print(f"Total recovered files: {count}")
