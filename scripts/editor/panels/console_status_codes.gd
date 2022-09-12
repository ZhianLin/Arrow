# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Console Status Codes
# (sent by nodes being played, interpreted by the console)
class_name CONSOLE_STATUS_CODE

# the outgoing played slot is connected to no other node
const END_EDGE = 0
const END_EDGE_MESSAGE = "錄 EOL: {name} ({uid})"

# no default action is taken by the node (e.g. due to being skipped)
const NO_DEFAULT = 1
const NO_DEFAULT_MESSAGE = " No DEFAULT: {name} ({uid})"
