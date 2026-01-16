#include "scheduler.h"
#include "buffers.h"
#include <iostream>

int main() {
    Scheduler sched(8,8); // 8 clusters x 8 subarrays
    Buffer buf(1024);

    // Tareas de prueba
    sched.add_task({0,0,true});
    sched.add_task({1,2,false});
    sched.execute();

    buf.write(0, 3.14f);
    std::cout << "Buffer[0] = " << buf.read(0) << "\n";

    return 0;
}

