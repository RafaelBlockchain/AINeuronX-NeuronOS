#include "buffers.h"

Buffer::Buffer(int size) {
    data.resize(size, 0.0f);
}

void Buffer::write(int index, float value) {
    if(index < data.size()) data[index] = value;
}

float Buffer::read(int index) {
    if(index < data.size()) return data[index];
    return 0.0f;
}

