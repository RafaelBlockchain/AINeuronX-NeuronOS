from collections import defaultdict

def compute_latency(trace):
    commits = [e for e in trace if e["event"] == "COMMIT"]
    if not commits:
        return None
    return commits[-1]["cycle"] - commits[0]["cycle"]

def compute_ipc(trace):
    cycles = max(e["cycle"] for e in trace)
    commits = len([e for e in trace if e["event"] == "COMMIT"])
    return commits / cycles if cycles > 0 else 0

def utilization(trace, prefix):
    active = len([e for e in trace if e["opcode"] and e["opcode"].startswith(prefix)])
    total = max(e["cycle"] for e in trace)
    return active / total if total > 0 else 0
