# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Distributed acoustic reconnaissance system for field observation posts. Multiple autonomous ESP32-S3 sensor stations detect, classify, and triangulate sound sources (people, animals, vehicles) using microphone arrays. Results are forwarded to a central server (Rock Pi 4C+) for mapping and operator display.

Documentation is primarily in Ukrainian. See `docs/acoustic_system_context.md` for full technical specification.

## Architecture

### Three-Layer System

```
Server (Rock Pi 4C+)
  ├── Triangulation, neural-net classification, map UI
  ├── Station 0 (ESP32-S3 N16R8) — 4× INMP441, USB CDC → Rock Pi
  └── Gateway (TTGO LoRa32) — LoRa + nRF24 radio bridge → Rock Pi
        ↕ LoRa 433MHz (metadata/control) + nRF24 2.4GHz (on-demand audio)
Autonomous Stations (ESP32-S3 N16R8, up to 500m apart, 3-5km total radius)
  └── 4× INMP441 MEMS microphones, LoRa + nRF24 radios, Li-Ion 21700 (2S2P)
```

### Dual-Radio Design

| Radio | Frequency | Always On? | Purpose |
|-------|-----------|-----------|---------|
| LoRa Ra-02 SX1278 | 433 MHz FHSS | Yes | Metadata packets, sync, control (AES-128-CCM encrypted) |
| nRF24L01 PA+LNA | 2.4 GHz | No (on-demand) | Audio fragment retrieval (Opus 32kbps, ~15-20s) |

**Shared SPI bus:** LoRa + nRF24 share MOSI/MISO/SCK with separate CS. Firmware mutex required; LoRa has priority over nRF24.

### Station Operation
- **Idle:** Analog comparator triggers on sound; ~56mW draw
- **Event:** Records 4-channel I2S to PSRAM ring buffer (10-15s pre+post trigger, ~3.84MB), runs GCC-PHAT TDOA (6 pairs), classifies, sends ~50-byte LoRa packet (AES-128-CCM)
- **Audio request:** Server pulls audio via nRF24 when needed

### Time Synchronization (GPS-free)
No GPS — vulnerable to EW jamming. Instead: TCXO ±0.5ppm + acoustic beacon calibration + LoRa mesh drift correction. Accuracy ~1-5ms (yields ~0.5m position error/hour of drift).

### LoRa Packet (~50 bytes, AES-128-CCM)
Station ID (2B) | Counter (4B) | [encrypted: Timestamp µs (8B) | TDOA 6 pairs (24B) | SNR×4 (4B) | Event class (1B) | Confidence (1B) | Battery % (1B) | Temperature (1B)] | MIC (4B)

## Development Stages

| Stage | Goal | Status |
|-------|------|--------|
| 1 | Single node: 4-channel I2S recording + GCC-PHAT TDOA on bench | Pending |
| 2 | LoRa metadata link + nRF24 audio protocol with gateway | Pending |
| 3 | Two nodes in field: real triangulation accuracy tests | Pending |
| 4 | Server: map UI, neural-net classification, full integration | Pending |

## Firmware (ESP32-S3 Station)

**Toolchain:** ESP-IDF v5.x
**Target:** `esp32s3` (N16R8 variant — 8MB PSRAM required for ring buffer)

```bash
# From firmware/station/
idf.py set-target esp32s3
idf.py build
idf.py flash monitor
idf.py flash -p COM<N>   # specific port on Windows
```

**Key pin assignments (station):**
- I2S Bus 0: SCK=14, WS=15, DATA M1=16, M2=17
- I2S Bus 1: SCK=18, WS=19, DATA M3=20, M4=21
- LoRa SPI: MOSI=11, MISO=13, SCK=12, NSS=10, DIO0=9, RST=8
- nRF24 SPI (shared bus): CSN=7, CE=6, IRQ=5
- DS3231 I2C: SDA=3, SCL=4

## Firmware (TTGO LoRa32 — Communication Module)

TTGO LoRa32 is a radio bridge between autonomous stations and Rock Pi 4C+. It handles LoRa reception and nRF24 audio relay only. USB microphone connects directly to Rock Pi.

**Toolchain:** ESP-IDF v5.x or Arduino
**Key pin assignments (gateway):**
- nRF24: MOSI=23, MISO=19, SCK=18, CSN=5, CE=17, IRQ=16

## Server (Rock Pi 4C+)

**Language:** Python 3
**Key dependencies:** `numpy`, `scipy`, `torch` or `tflite-runtime`, `pyserial`, `folium`

```bash
# From server/
pip install -r requirements.txt
python main.py
```

## Hardware Models

**3D modeling toolchain: build123d (Python)** — перехід з OpenSCAD.
Viewer: `ocp-vscode` розширення для VS Code (`show(obj)` в коді).

Моделі в `hardware/` (будуть переписані з нуля на build123d):
- `station_battery_mount.scad` — Li-Ion 21700×4 (2S2P) compartment
- `station_electronics_compartment.scad` — PCB enclosure (IP65)
- `station_mic_lid.scad` — Microphone cover

```bash
pip install build123d ocp-vscode
```

## Key Technical Constraints

- **PSRAM mandatory:** Ring buffer (15s × 4ch × 32kHz × 16bit = 3.84MB) fits in 8MB PSRAM of N16R8 module. Recording parameters: **32 000 Hz / 16-bit** (bandwidth 16 kHz, covers UAV acoustic signatures). Serial production target: 44 100 Hz / 24-bit with ICS-43434 mics (requires external SDRAM or ≤10s buffer).
- **Tetrahedral mic geometry:** 1 mic on top, 3 at 120° with 35° tilt from vertical (≈35.26° — true tetrahedron) — enables 3D bearing (azimuth + elevation)
- **Sound speed correction:** Temperature from DS3231 must be factored into TDOA→distance conversion (~0.6 m/s per °C)
- **FHSS on LoRa:** Frequency hopping pattern must be pre-shared and synchronized across all nodes
- **AES-128-CCM encryption:** All LoRa packets encrypted + authenticated with pre-shared 128-bit key
- **SPI bus sharing:** LoRa and nRF24 share SPI bus — firmware mutex required, LoRa priority
- **Opus codec:** Audio compressed to 32kbps mono 16kHz before nRF24 transmission
