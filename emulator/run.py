from emulator.core.emulator import Emulator
from emulator.core.scoreboard import Scoreboard
from emulator.core.tile import Tile
from emulator.logging.logger import EventLogger
from emulator.program.program import simple_program

logger = EventLogger()

tiles = []
for i in range(4):
    sb = Scoreboard(reg_count=32)
    tiles.append(Tile(i, simple_program(), sb))

emu = Emulator(tiles, logger)
emu.run()

for e in logger.events:
    print(e)

    logger.export("emu_trace.json")
