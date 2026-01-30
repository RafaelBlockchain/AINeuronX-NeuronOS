from core.clock import Clock
from core.state import GlobalState
from memory.dma import DMAEngine
from emulator.noc.noc import NoC

self.noc = NoC(width=4, height=4, hop_latency=1, logger=self.logger)

class Emulator:
    def __init__(self, tiles, logger):
        self.clock = Clock()
        self.tiles = tiles
        self.logger = logger
        self.state = GlobalState.RUNNING
        self.dma = DMAEngine()

    def step(self):
        self.clock.tick()
        cycle = self.clock.cycle

        # 1. avanzar DMA
        self.dma.step()

        # avanzar NoC
        self.noc.step(cycle)

        # 2. issue instrucciones
        for tile in self.tiles:
            if tile.can_issue():
                tile.issue(cycle)

        # 3. ejecutar / commit
        for tile in self.tiles:
            tile.step(cycle)

        # 4. fin del programa
        if all(tile.pc >= len(tile.program) and tile.current is None for tile in self.tiles):
            self.state = GlobalState.DONE

    def run(self, max_cycles=100000):
        while self.state == GlobalState.RUNNING and self.clock.cycle < max_cycles:
            self.step()

