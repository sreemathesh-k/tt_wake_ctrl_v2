# wake_ctrl_v2 - Priority-Aware Event-Driven Wake Controller

[![GDS](../../actions/workflows/gds.yml/badge.svg)](../../actions/workflows/gds.yml)

**Author:** Sreemathesh K

A 4-channel always-on digital wake controller for batteryless IoT sensors. Built as part of my undergraduate ASIC project — previously taped out through OpenROAD on SKY130 with zero DRC violations.

## How it works

- 4 sensor threshold inputs monitored continuously
- 2FF synchronizer on each input (prevents metastability)
- 8-cycle debounce counter per channel (removes noise)
- Configurable AND mode (all channels) or OR mode (any channel)
- Hardware priority encoder (reports first-fired channel)
- Clean fixed-width wake pulse output

## Pin map

| Pin | Function |
|-----|----------|
| ui[3:0] | thresh_in — sensor inputs |
| ui[7:4] | ch_en — channel enables |
| ui[4] | mode_and (shared with ch_en[0]) |
| uo[0] | wake_out — wake pulse |
| uo[4:1] | evt_flags — which channels fired |
| uo[6:5] | priority_ch — highest priority channel |

## Resources

- [TinyTapeout](https://tinytapeout.com)
