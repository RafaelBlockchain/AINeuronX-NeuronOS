#include "scheduler.h"
#include <iostream>

Scheduler::Scheduler(int num_clusters, int subarrays_per_cluster) {
    clusters = num_clusters;
    subarrays = subarrays_per_cluster;
}

void Scheduler::add_task(Task t) {
    task_queue.push_back(t);
}

void Scheduler::execute() {
    std::cout << "[Scheduler] Ejecutando " << task_queue.size() << " tareas...\n";
    for(auto &t : task_queue) {
        std::cout << "  Cluster " << t.cluster_id << ", Subarray " << t.subarray_id
                  << ", Precision " << (t.fp16 ? "FP16" : "FP8") << "\n";
    }
    task_queue.clear();
}

