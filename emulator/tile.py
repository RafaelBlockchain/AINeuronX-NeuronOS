class Tile:
    def __init__(self, tile_id, program, ssb, dma_engine, logger):
        self.tile_id = tile_id
        self.program = program
        self.ssb = ssb
        self.dma_engine = dma_engine
        self.logger = logger

        self.pc = 0
        self.current = None

    def step(self, cycle):
        # Golden Tile mínimo: avanza PC hasta terminar el programa
        if self.pc < len(self.program):
            self.current = self.program[self.pc]
            self.pc += 1
        else:
            self.current = None
