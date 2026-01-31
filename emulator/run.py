from emulator.core.emulator import Emulator
from emulator.tile import Tile
from emulator.program.program import simple_program
from emulator.logging.logger import EventLogger
from emulator.memory.dma import DMAEngine


def main():
    # Logger global (golden trace)
    logger = EventLogger()

    # DMA engine (stub válido para N200)
    dma = DMAEngine()

    # Programa golden REAL (VADD)
    program = simple_program()

    # Tiles
    tiles = []
    ssb = None          # placeholder N200
    num_tiles = 1       # N200 = 1 tile

    for i in range(num_tiles):
        tiles.append(
            Tile(
                tile_id=i,
                program=program,
                ssb=ssb,
                dma_engine=dma,
                logger=logger,
            )
        )

    # Emulator
    emu = Emulator(tiles=tiles, logger=logger)

    # Ejecutar
    emu.run()

    # Guardar traza golden
    logger.dump("emu_trace.json")


if __name__ == "__main__":
    main()
