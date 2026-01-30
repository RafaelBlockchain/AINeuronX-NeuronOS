import sys
from metrics.parse_trace import load_trace
from metrics.compute_metrics import compute_latency, compute_ipc, utilization

trace = load_trace("emu_trace.json")

LATENCY_MAX = 32 * 2
IPC_MIN = 0.75
VEC_UTIL_MIN = 0.60
TEN_UTIL_MIN = 0.40
DMA_UTIL_MIN = 0.30

lat = compute_latency(trace)
ipc = compute_ipc(trace)
vu  = utilization(trace, "V_")
tu  = utilization(trace, "T_")
du  = utilization(trace, "DMA_")

errors = []

if lat is None or lat > LATENCY_MAX:
    errors.append(f"Latency FAIL: {lat}")

if ipc < IPC_MIN:
    errors.append(f"IPC FAIL: {ipc}")

if vu < VEC_UTIL_MIN:
    errors.append(f"Vector util FAIL: {vu}")

if tu < TEN_UTIL_MIN:
    errors.append(f"Tensor util FAIL: {tu}")

if du < DMA_UTIL_MIN:
    errors.append(f"DMA util FAIL: {du}")

if errors:
    print("❌ N200 PERFORMANCE TARGETS FAILED")
    for e in errors:
        print(e)
    sys.exit(1)

print("✅ N200 PERFORMANCE TARGETS PASSED")
