from emulator.core.emulator import Emulator
from emulator.tile import Tile
from emulator.memory.dma import DMAEngine
from emulator.logging.logger import EventLogger
from emulator.program.program import simple_program


def main():
    # Configuración Golden
    num_tiles = 4
    ssb = None  # placeholder hasta que el SSB sea modelado

    logger = EventLogger()
    dma = DMAEngine()

    tiles = []
    for i in range(num_tiles):
        tiles.append(
            Tile(
                tile_id=i,
                program=simple_program(),
                ssb=ssb,
                dma_engine=dma,
                logger=logger,
            )
        )

    emu = Emulator(tiles)
    emu.run()


if __name__ == "__main__":
    main()

