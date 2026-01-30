from core.emulator import Emulator
from core.scoreboard import Scoreboard
from core.tile import Tile
from logging.logger import EventLogger
from program.program import simple_program

logger = EventLogger()

tiles = []
for i in range(4):
    sb = Scoreboard(reg_count=32)
    tiles.append(Tile(i, simple_program(), sb))

emu = Emulator(tiles, logger)
emu.run()

for e in logger.events:
    print(e)
