# Connect-IQ Lap Maximum Speed
Simple Garmin Connect IQ app to enable per-lap maximum speed for Garmin Fenix watches.
## Description
Very minimalistic data field generating 4 numbers:
- maximum speed (typically checked once per second) in the current lap
- maximum speed over floating window (10s by default) in the current lap
- maximum speed (typically checked once per second) in the previous lap
- maximum speed over floating window (10s by default) in the previous lap

This data field makes for the lack of per-lap maximum speed available among available speed data fields on the Garmin Fenix series. 10s floating averaging window has been added to make for more stable measurements - maybe I will add storing those into the FIT files sometimes in the future.

Known issues: 
- The four numbers can start overflowing and get truncated when more fields are displayed; however, as I am mostly interested in the first two numbers, it hasn't been worth going for some fancy graphics to compress it for me (but may reconsider if others become annoyed by this :) ).
- Backcountry skiing app (by Garmin) unfortunately uses Lap key for switching ascent/descent modes and does not generate new lap after this transition and hence one does not get maximum speeds per lap (this is not a problem with the data field, but property of the Backcountry skiing app).

## What’s New
0.7:
- support for customizable settings (currently floating window for max speed averaging)
0.5:
- initial version
