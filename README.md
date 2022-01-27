# Connect-IQ Lap Maximum Speed
Simple Garmin Connect IQ app to enable per-lap maximum speed for Garmin Fenix watches. 

Data field has been primarily motivated by downhill sports, namely downhill/resort skiing. Standard Fenix Ski mode does this partially automatically, but the automated detection of downhill skiing and stopping for uphill chair lifts is not always perfect and in smaller resorts with lower elevation differences one often needs to use other ski modes (such as backcountry or XC skiing) to get meaningful recordings. Then the per-lap maximum speed is not available among standard data fields. 

When writing a custom data field, I took the opportunity to implement also averaging maximum speed over user-definable window, so that one can get more stable readouts of maximum speed. This maximum speed floating average is shown next to the instantaneous maximum speed.

## Description
Current implementation is very minimalistic data field generating 5 numbers:
- maximum speed (typically checked once per second) in the current lap (top left)
- maximum speed over floating window (10s by default) in the current lap (bottom left)
- maximum speed (typically checked once per second) in the previous lap (top right)
- maximum speed over floating window (10s by default) in the previous lap (bottom right)
- lenght of the floating window (bottom middle)

This data field makes for the lack of per-lap maximum speed available among available speed data fields on the Garmin Fenix series. 10s floating averaging window has been added to make for more stable measurements - maybe I will add storing those into the FIT files sometimes in the future.

Known issues: 
- The four numbers can start overflowing and get truncated when more fields are displayed in some screen configurations and the overflow detection does not work for me well enough.
- Backcountry skiing app (by Garmin) unfortunately uses Lap key for switching ascent/descent modes and does not generate new lap after this transition and hence one does not get maximum speeds per lap (this is not a problem with the data field, but property of the Backcountry skiing app).

Other bugs and issues can be reported via GitHub Issues.

## What’s New
1.0:
- transition to full DataField instead of SimpleDataField, allowing better layout of numbers.
0.7:
- support for customizable settings (currently floating window for max speed averaging)
0.5:
- initial version
