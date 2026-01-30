from core.isa import Opcode
from core.instruction import Instruction

def dma_test_program():
    return [
        Instruction(Opcode.DMA_LOAD, dst=0, imm=1024),
        Instruction(Opcode.SC_ADD),
        Instruction(Opcode.DMA_WAIT),
        Instruction(Opcode.V_ADD),
        Instruction(Opcode.T_MATMUL),
    ]

