import json

    class EventLogger:

    def export(self, path):
        with open(path, "w") as f:
            json.dump(self.events, f, indent=2)

    def __init__(self):
        self.events = []

    def log(self, cycle, tile, event, opcode=None):
        self.events.append({
            "cycle": cycle,
            "tile": tile,
            "event": event,
            "opcode": opcode
        })

    def dump(self):
        for e in self.events:
            print(e)

