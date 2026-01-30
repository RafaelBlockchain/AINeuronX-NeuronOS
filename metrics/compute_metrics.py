from collections import defaultdict

def compute_latency(trace):
    commits = [e for e in trace if e["event"] == "COMMIT"]
    if not commits:
        return None
    return commits[-1]["cycle"] - commits[0]["cycle"]

def compute_ipc(trace):
    if not trace:
        return 0.0

    cycles = max(e["cycle"] for e in trace) + 1
    instructions = sum(1 for e in trace if e.get("event") == "instruction")

    return instructions / cycles if cycles > 0 else 0.0

def utilization(trace, prefix):
    if not trace:
        return 0.0

    active = sum(
        1 for e in trace
        if e.get("opcode") and e["opcode"].startswith(prefix)
    )
    return active / len(trace)
