# Connect-IQ Lap Maximum Speed
Simple Garmin Connect IQ app to enable per-lap maximum speed for Garmin Fenix watches.
## Description
Very minimalistic data field generating 4 numbers:
- maximum speed (typically checked once per second) in the current lap
- maximum speed over floating window (10s by default) in the current lap
- maximum speed (typically checked once per second) in the previous lap
- maximum speed over floating window (10s by default) in the previous lap

This data field makes for the lack of per-lap maximum speed available among available speed data fields on the Garmin Fenix series. 10s floating averaging window has been added to make for more stable measurements - maybe I will add storing those into the FIT files sometimes in the future.… More

## What’s New
0.7:
- support for customizable settings (currently floating window for max speed averaging)
0.5:
- initial version
