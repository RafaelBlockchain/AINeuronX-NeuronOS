cat << 'EOF' > emulator/logging/logger.py
class EventLogger:
    def __init__(self):
        self.events = []

    def log(self, event):
        self.events.append(event)

    def export(self, path):
        import json
        with open(path, "w") as f:
            json.dump(self.events, f, indent=2)
EOF
