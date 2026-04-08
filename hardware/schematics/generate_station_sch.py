#!/usr/bin/env python3
"""Generate KiCad 8 schematic for Autonomous Acoustic Station."""

import json
import uuid
import os

# Deterministic UUID generator
_uuid_counter = 0
def make_uuid():
    global _uuid_counter
    _uuid_counter += 1
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, f"acoustic-station-sch-{_uuid_counter}"))

ROOT_UUID = "f47ac10b-58cc-4372-a567-0e02b2c3d479"

# ── Symbol definitions (lib coords: y-up) ──────────────────────

def rect(x1, y1, x2, y2):
    return f"""      (rectangle
        (start {x1} {y1})
        (end {x2} {y2})
        (stroke (width 0.254) (type default))
        (fill (type background))
      )"""

def pin(ptype, name, number, x, y, angle, length=2.54):
    return f"""      (pin {ptype} line
        (at {x} {y} {angle})
        (length {length})
        (name "{name}" (effects (font (size 1.27 1.27))))
        (number "{number}" (effects (font (size 1.27 1.27))))
      )"""

def lib_symbol(name, graphics_body, pins_body, desc=""):
    return f"""    (symbol "{name}"
      (pin_names (offset 1.016))
      (exclude_from_sim no)
      (in_bom yes)
      (on_board yes)
      (symbol "{name}_0_1"
{graphics_body}
      )
      (symbol "{name}_1_1"
{pins_body}
      )
    )"""

def make_lib_symbols():
    symbols = []

    # ── ESP32-S3-DevKitC-1 ──
    # 13 pins left, 8 pins right
    esp_rect = rect(-12.7, -17.78, 12.7, 17.78)
    esp_pins = []
    left_pins = [
        ("power_in", "3V3",    "1",  15.24),
        ("power_in", "GND",    "2",  12.7),
        ("bidirectional", "GPIO3",  "3",  10.16),
        ("bidirectional", "GPIO4",  "4",  7.62),
        ("bidirectional", "GPIO5",  "5",  5.08),
        ("bidirectional", "GPIO6",  "6",  2.54),
        ("bidirectional", "GPIO7",  "7",  0),
        ("bidirectional", "GPIO8",  "8",  -2.54),
        ("bidirectional", "GPIO9",  "9",  -5.08),
        ("bidirectional", "GPIO10", "10", -7.62),
        ("bidirectional", "GPIO11", "11", -10.16),
        ("bidirectional", "GPIO12", "12", -12.7),
        ("bidirectional", "GPIO13", "13", -15.24),
    ]
    for ptype, pname, pnum, py in left_pins:
        esp_pins.append(pin(ptype, pname, pnum, -15.24, py, 0))
    right_pins = [
        ("bidirectional", "GPIO14", "14", 10.16),
        ("bidirectional", "GPIO15", "15", 7.62),
        ("bidirectional", "GPIO16", "16", 5.08),
        ("bidirectional", "GPIO17", "17", 2.54),
        ("bidirectional", "GPIO18", "18", 0),
        ("bidirectional", "GPIO19", "19", -2.54),
        ("bidirectional", "GPIO20", "20", -5.08),
        ("bidirectional", "GPIO21", "21", -7.62),
    ]
    for ptype, pname, pnum, py in right_pins:
        esp_pins.append(pin(ptype, pname, pnum, 15.24, py, 180))
    symbols.append(lib_symbol("ESP32_S3_DevKitC1", esp_rect, "\n".join(esp_pins)))

    # ── INMP441 Breakout ──
    mic_rect = rect(-7.62, -5.08, 7.62, 5.08)
    mic_pins = "\n".join([
        pin("power_in", "VDD", "1", -10.16, 2.54, 0),
        pin("power_in", "GND", "2", -10.16, 0, 0),
        pin("input",    "L/R", "3", -10.16, -2.54, 0),
        pin("input",    "SCK", "4", 10.16, 2.54, 180),
        pin("input",    "WS",  "5", 10.16, 0, 180),
        pin("output",   "SD",  "6", 10.16, -2.54, 180),
    ])
    symbols.append(lib_symbol("INMP441_Breakout", mic_rect, mic_pins))

    # ── Ra-02 SX1278 LoRa ──
    lora_rect = rect(-10.16, -10.16, 10.16, 10.16)
    lora_pins = "\n".join([
        pin("power_in", "VCC",  "1", -12.7, 7.62, 0),
        pin("power_in", "GND",  "2", -12.7, 5.08, 0),
        pin("output",   "DIO0", "3", -12.7, -5.08, 0),
        pin("input",    "RST",  "4", -12.7, -7.62, 0),
        pin("input",    "MOSI", "5", 12.7, 7.62, 180),
        pin("output",   "MISO", "6", 12.7, 5.08, 180),
        pin("input",    "SCK",  "7", 12.7, 2.54, 180),
        pin("input",    "NSS",  "8", 12.7, -2.54, 180),
    ])
    symbols.append(lib_symbol("Ra02_SX1278", lora_rect, lora_pins))

    # ── nRF24L01 PA+LNA ──
    nrf_rect = rect(-10.16, -10.16, 10.16, 10.16)
    nrf_pins = "\n".join([
        pin("power_in", "VCC",  "1", -12.7, 7.62, 0),
        pin("power_in", "GND",  "2", -12.7, 5.08, 0),
        pin("input",    "CE",   "3", -12.7, -5.08, 0),
        pin("output",   "IRQ",  "4", -12.7, -7.62, 0),
        pin("input",    "MOSI", "5", 12.7, 7.62, 180),
        pin("output",   "MISO", "6", 12.7, 5.08, 180),
        pin("input",    "SCK",  "7", 12.7, 2.54, 180),
        pin("input",    "CSN",  "8", 12.7, -2.54, 180),
    ])
    symbols.append(lib_symbol("nRF24L01_PA_LNA", nrf_rect, nrf_pins))

    # ── DS3231 RTC ──
    rtc_rect = rect(-7.62, -5.08, 7.62, 5.08)
    rtc_pins = "\n".join([
        pin("power_in",    "VCC", "1", -10.16, 2.54, 0),
        pin("power_in",    "GND", "2", -10.16, -2.54, 0),
        pin("bidirectional","SDA", "3", 10.16, 2.54, 180),
        pin("input",       "SCL", "4", 10.16, -2.54, 180),
    ])
    symbols.append(lib_symbol("DS3231_RTC", rtc_rect, rtc_pins))

    # ── Mini360 DC-DC ──
    reg_rect = rect(-7.62, -5.08, 7.62, 5.08)
    reg_pins = "\n".join([
        pin("power_in",  "IN",  "1", -10.16, 2.54, 0),
        pin("power_in",  "GND", "2", -10.16, -2.54, 0),
        pin("power_out", "OUT", "3", 10.16, 0, 180),
    ])
    symbols.append(lib_symbol("Mini360_DCDC", reg_rect, reg_pins))

    # ── Li-Ion Battery 2S2P ──
    bat_rect = rect(-7.62, -5.08, 7.62, 5.08)
    bat_pins = "\n".join([
        pin("power_out", "POS", "1", 10.16, 2.54, 180),
        pin("power_out", "NEG", "2", -10.16, -2.54, 0),
    ])
    symbols.append(lib_symbol("Li_Ion_2S2P", bat_rect, bat_pins))

    # ── Power symbols: +3V3, GND, VBAT ──
    # Note: no "power:" prefix in inline lib_symbols — KiCad can't parse it in sub-symbol names
    pwr_3v3 = """    (symbol "+3V3"
      (power)
      (pin_names (offset 0))
      (exclude_from_sim no)
      (in_bom yes)
      (on_board yes)
      (symbol "+3V3_0_1"
        (polyline
          (pts (xy -0.762 1.27) (xy 0 2.54))
          (stroke (width 0) (type default))
          (fill (type none))
        )
        (polyline
          (pts (xy 0 0) (xy 0 2.54))
          (stroke (width 0) (type default))
          (fill (type none))
        )
        (polyline
          (pts (xy 0 2.54) (xy 0.762 1.27))
          (stroke (width 0) (type default))
          (fill (type none))
        )
      )
      (symbol "+3V3_1_1"
        (pin power_in line
          (at 0 0 90)
          (length 0)
          (name "+3V3" (effects (font (size 1.27 1.27))))
          (number "1" (effects (font (size 1.27 1.27))))
        )
      )
    )"""

    pwr_gnd = """    (symbol "GND"
      (power)
      (pin_names (offset 0))
      (exclude_from_sim no)
      (in_bom yes)
      (on_board yes)
      (symbol "GND_0_1"
        (polyline
          (pts (xy 0 0) (xy 0 -1.27) (xy -1.27 -1.27) (xy 0 -2.54) (xy 1.27 -1.27) (xy 0 -1.27))
          (stroke (width 0) (type default))
          (fill (type none))
        )
      )
      (symbol "GND_1_1"
        (pin power_in line
          (at 0 0 270)
          (length 0)
          (name "GND" (effects (font (size 1.27 1.27))))
          (number "1" (effects (font (size 1.27 1.27))))
        )
      )
    )"""

    pwr_vbat = """    (symbol "VBAT"
      (power)
      (pin_names (offset 0))
      (exclude_from_sim no)
      (in_bom yes)
      (on_board yes)
      (symbol "VBAT_0_1"
        (polyline
          (pts (xy -0.762 1.27) (xy 0 2.54))
          (stroke (width 0) (type default))
          (fill (type none))
        )
        (polyline
          (pts (xy 0 0) (xy 0 2.54))
          (stroke (width 0) (type default))
          (fill (type none))
        )
        (polyline
          (pts (xy 0 2.54) (xy 0.762 1.27))
          (stroke (width 0) (type default))
          (fill (type none))
        )
      )
      (symbol "VBAT_1_1"
        (pin power_in line
          (at 0 0 90)
          (length 0)
          (name "VBAT" (effects (font (size 1.27 1.27))))
          (number "1" (effects (font (size 1.27 1.27))))
        )
      )
    )"""

    symbols.extend([pwr_3v3, pwr_gnd, pwr_vbat])
    return "\n\n".join(symbols)


# ── Symbol placement and wiring ─────────────────────────────

def symbol_instance(lib_id, ref, value, desc, sx, sy, rot=0):
    uid = make_uuid()
    return f"""  (symbol
    (lib_id "{lib_id}")
    (at {sx} {sy} {rot})
    (unit 1)
    (exclude_from_sim no)
    (in_bom yes)
    (on_board yes)
    (dnp no)
    (uuid "{uid}")
    (property "Reference" "{ref}"
      (at {sx} {sy - 22} 0)
      (effects (font (size 1.27 1.27)))
    )
    (property "Value" "{value}"
      (at {sx} {sy - 20} 0)
      (effects (font (size 1.27 1.27)))
    )
    (property "Footprint" ""
      (at {sx} {sy} 0)
      (effects (font (size 1.27 1.27)) hide)
    )
    (property "Datasheet" ""
      (at {sx} {sy} 0)
      (effects (font (size 1.27 1.27)) hide)
    )
    (property "Description" "{desc}"
      (at {sx} {sy} 0)
      (effects (font (size 1.27 1.27)) hide)
    )
    (instances
      (project "station"
        (path "/{ROOT_UUID}"
          (reference "{ref}")
          (unit 1)
        )
      )
    )
  )"""


def power_instance(lib_id, ref, sx, sy):
    """Place a power symbol (+3V3, GND, VBAT)."""
    uid = make_uuid()
    net = lib_id
    return f"""  (symbol
    (lib_id "{lib_id}")
    (at {sx} {sy} 0)
    (unit 1)
    (exclude_from_sim no)
    (in_bom yes)
    (on_board yes)
    (dnp no)
    (uuid "{uid}")
    (property "Reference" "{ref}"
      (at {sx} {sy - 3} 0)
      (effects (font (size 1.27 1.27)) hide)
    )
    (property "Value" "{net}"
      (at {sx} {sy - 5} 0)
      (effects (font (size 1.27 1.27)))
    )
    (property "Footprint" ""
      (at {sx} {sy} 0)
      (effects (font (size 1.27 1.27)) hide)
    )
    (property "Datasheet" ""
      (at {sx} {sy} 0)
      (effects (font (size 1.27 1.27)) hide)
    )
    (instances
      (project "station"
        (path "/{ROOT_UUID}"
          (reference "{ref}")
          (unit 1)
        )
      )
    )
  )"""


def wire(x1, y1, x2, y2):
    uid = make_uuid()
    return f"""  (wire
    (pts (xy {x1} {y1}) (xy {x2} {y2}))
    (stroke (width 0) (type default))
    (uuid "{uid}")
  )"""


def label(name, x, y, rot=0):
    uid = make_uuid()
    return f"""  (label "{name}"
    (at {x} {y} {rot})
    (effects (font (size 1.27 1.27)))
    (uuid "{uid}")
  )"""


def text_note(text, x, y):
    uid = make_uuid()
    return f"""  (text "{text}"
    (exclude_from_sim no)
    (at {x} {y} 0)
    (effects (font (size 2.54 2.54)) (justify left))
    (uuid "{uid}")
  )"""


# ── Main generation ─────────────────────────────────────────

def generate():
    instances = []
    wires = []
    labels_list = []
    power_syms = []
    notes = []

    # Power symbol reference counters
    pwr_ref_counter = {"3V3": 0, "GND": 0, "VBAT": 0}

    def add_power(ptype, x, y):
        """Add a power symbol and wire stub. ptype: '+3V3', 'GND', 'VBAT'."""
        lib = ptype
        key = ptype.replace("+", "")
        pwr_ref_counter[key] += 1
        ref = f"#{key}{pwr_ref_counter[key]:02d}"
        if ptype == "GND":
            # GND symbol: pin at top (y=0 in symbol, pointing down)
            # Wire goes down from pin to power symbol
            power_syms.append(power_instance(lib, ref, x, y + 2.54))
            wires.append(wire(x, y, x, y + 2.54))
        else:
            # +3V3/VBAT: pin at bottom (pointing up)
            power_syms.append(power_instance(lib, ref, x, y - 2.54))
            wires.append(wire(x, y, x, y - 2.54))

    def connect_pin(pin_sheet_x, pin_sheet_y, net_name, side):
        """Add wire stub + label from a pin endpoint.
        side: 'left' (wire goes left) or 'right' (wire goes right)."""
        stub = 7.62
        if side == "left":
            end_x = pin_sheet_x - stub
            lrot = 180
        else:
            end_x = pin_sheet_x + stub
            lrot = 0
        wires.append(wire(pin_sheet_x, pin_sheet_y, end_x, pin_sheet_y))
        labels_list.append(label(net_name, end_x, pin_sheet_y, lrot))

    def connect_pin_power(pin_sheet_x, pin_sheet_y, ptype, side):
        """Connect pin to a power symbol via wire stub."""
        stub = 5.08
        if side == "left":
            end_x = pin_sheet_x - stub
        else:
            end_x = pin_sheet_x + stub
        wires.append(wire(pin_sheet_x, pin_sheet_y, end_x, pin_sheet_y))
        add_power(ptype, end_x, pin_sheet_y)

    # ── Placement coordinates ──
    # U1: ESP32-S3 (center)
    u1_x, u1_y = 210, 155

    # MIC1-4: INMP441
    mic1_x, mic1_y = 70, 80
    mic2_x, mic2_y = 70, 110
    mic3_x, mic3_y = 70, 190
    mic4_x, mic4_y = 70, 220

    # U2: LoRa (right top)
    u2_x, u2_y = 350, 85

    # U3: nRF24 (right middle)
    u3_x, u3_y = 350, 155

    # U4: DS3231 (right bottom)
    u4_x, u4_y = 350, 235

    # REG1: Mini360 (top center)
    reg_x, reg_y = 210, 38

    # BAT1: Battery (top left)
    bat_x, bat_y = 120, 38

    # ── Section notes ──
    notes.append(text_note("I2S Bus 0", 30, 60))
    notes.append(text_note("I2S Bus 1", 30, 172))
    notes.append(text_note("MCU", 195, 125))
    notes.append(text_note("Power", 145, 22))
    notes.append(text_note("LoRa 433 MHz", 325, 63))
    notes.append(text_note("nRF24 2.4 GHz", 325, 133))
    notes.append(text_note("RTC", 335, 218))

    # ── Component instances ──

    instances.append(symbol_instance(
        "ESP32_S3_DevKitC1", "U1", "ESP32-S3-DevKitC-1 N16R8",
        "MCU: dual-core 240MHz, 8MB Flash, 8MB PSRAM", u1_x, u1_y))

    for i, (mx, my) in enumerate([(mic1_x, mic1_y), (mic2_x, mic2_y),
                                    (mic3_x, mic3_y), (mic4_x, mic4_y)], 1):
        lr = "GND" if i in (1, 3) else "VCC"
        ch = "left" if i in (1, 3) else "right"
        instances.append(symbol_instance(
            "INMP441_Breakout", f"MIC{i}", "INMP441",
            f"I2S MEMS mic, L/R={lr} ({ch} channel)", mx, my))

    instances.append(symbol_instance(
        "Ra02_SX1278", "U2", "Ra-02 SX1278",
        "LoRa 433 MHz, FHSS, SPI", u2_x, u2_y))

    instances.append(symbol_instance(
        "nRF24L01_PA_LNA", "U3", "nRF24L01 PA+LNA",
        "2.4 GHz radio, SPI shared with LoRa", u3_x, u3_y))

    instances.append(symbol_instance(
        "DS3231_RTC", "U4", "DS3231",
        "RTC with TCXO, I2C, temperature sensor", u4_x, u4_y))

    instances.append(symbol_instance(
        "Mini360_DCDC", "REG1", "Mini360",
        "DC-DC buck 7.4V to 3.3V", reg_x, reg_y))

    instances.append(symbol_instance(
        "Li_Ion_2S2P", "BAT1", "Li-Ion 21700 2S2P",
        "4x Li-Ion 21700: 2S2P, 7.4V nom, ~67Wh", bat_x, bat_y))

    # ── Pin connections ──
    # Helper: compute sheet position of a pin
    # sheet_x = inst_x + pin_x, sheet_y = inst_y - pin_y  (y-up in lib → y-down on sheet)

    # U1 ESP32-S3 left side pins
    esp_left = [
        (15.24,  "+3V3"),      # VDD
        (12.7,   "GND"),       # GND
        (10.16,  "I2C_SDA"),   # GPIO3
        (7.62,   "I2C_SCL"),   # GPIO4
        (5.08,   "NRF_IRQ"),   # GPIO5
        (2.54,   "NRF_CE"),    # GPIO6
        (0,      "NRF_CSN"),   # GPIO7
        (-2.54,  "LORA_RST"),  # GPIO8
        (-5.08,  "LORA_DIO0"), # GPIO9
        (-7.62,  "LORA_NSS"),  # GPIO10
        (-10.16, "SPI_MOSI"),  # GPIO11
        (-12.7,  "SPI_SCK"),   # GPIO12
        (-15.24, "SPI_MISO"),  # GPIO13
    ]
    for pin_y, net in esp_left:
        sx = u1_x + (-15.24)
        sy = u1_y - pin_y
        if net in ("+3V3",):
            connect_pin_power(sx, sy, "+3V3", "left")
        elif net == "GND":
            connect_pin_power(sx, sy, "GND", "left")
        else:
            connect_pin(sx, sy, net, "left")

    # U1 ESP32-S3 right side pins
    esp_right = [
        (10.16,  "I2S0_SCK"),      # GPIO14
        (7.62,   "I2S0_WS"),       # GPIO15
        (5.08,   "I2S0_DATA_M1"),  # GPIO16
        (2.54,   "I2S0_DATA_M2"),  # GPIO17
        (0,      "I2S1_SCK"),      # GPIO18
        (-2.54,  "I2S1_WS"),       # GPIO19
        (-5.08,  "I2S1_DATA_M3"), # GPIO20
        (-7.62,  "I2S1_DATA_M4"), # GPIO21
    ]
    for pin_y, net in esp_right:
        sx = u1_x + 15.24
        sy = u1_y - pin_y
        connect_pin(sx, sy, net, "right")

    # ── INMP441 mic connections ──
    mic_configs = [
        # (inst_x, inst_y, lr_net, bus_prefix, data_net)
        (mic1_x, mic1_y, "GND",  "I2S0", "I2S0_DATA_M1"),
        (mic2_x, mic2_y, "+3V3", "I2S0", "I2S0_DATA_M2"),
        (mic3_x, mic3_y, "GND",  "I2S1", "I2S1_DATA_M3"),
        (mic4_x, mic4_y, "+3V3", "I2S1", "I2S1_DATA_M4"),
    ]
    for mx, my, lr_net, bus, data_net in mic_configs:
        # Left pins: VDD(y=2.54), GND(y=0), L/R(y=-2.54)
        vdd_sx, vdd_sy = mx - 10.16, my - 2.54
        gnd_sx, gnd_sy = mx - 10.16, my
        lr_sx,  lr_sy  = mx - 10.16, my + 2.54

        connect_pin_power(vdd_sx, vdd_sy, "+3V3", "left")
        connect_pin_power(gnd_sx, gnd_sy, "GND", "left")
        if lr_net == "GND":
            connect_pin_power(lr_sx, lr_sy, "GND", "left")
        else:
            connect_pin_power(lr_sx, lr_sy, "+3V3", "left")

        # Right pins: SCK(y=2.54), WS(y=0), SD(y=-2.54)
        sck_sx, sck_sy = mx + 10.16, my - 2.54
        ws_sx,  ws_sy  = mx + 10.16, my
        sd_sx,  sd_sy  = mx + 10.16, my + 2.54

        connect_pin(sck_sx, sck_sy, f"{bus}_SCK", "right")
        connect_pin(ws_sx, ws_sy, f"{bus}_WS", "right")
        connect_pin(sd_sx, sd_sy, data_net, "right")

    # ── Ra-02 LoRa (U2) ──
    # Left: VCC(y=7.62), GND(y=5.08), DIO0(y=-5.08), RST(y=-7.62)
    for pin_y, net, is_pwr in [
        (7.62, "+3V3", True), (5.08, "GND", True),
        (-5.08, "LORA_DIO0", False), (-7.62, "LORA_RST", False)
    ]:
        sx = u2_x - 12.7
        sy = u2_y - pin_y
        if is_pwr:
            connect_pin_power(sx, sy, net, "left")
        else:
            connect_pin(sx, sy, net, "left")

    # Right: MOSI(y=7.62), MISO(y=5.08), SCK(y=2.54), NSS(y=-2.54)
    for pin_y, net in [
        (7.62, "SPI_MOSI"), (5.08, "SPI_MISO"),
        (2.54, "SPI_SCK"), (-2.54, "LORA_NSS")
    ]:
        sx = u2_x + 12.7
        sy = u2_y - pin_y
        connect_pin(sx, sy, net, "right")

    # ── nRF24L01 (U3) ──
    for pin_y, net, is_pwr in [
        (7.62, "+3V3", True), (5.08, "GND", True),
        (-5.08, "NRF_CE", False), (-7.62, "NRF_IRQ", False)
    ]:
        sx = u3_x - 12.7
        sy = u3_y - pin_y
        if is_pwr:
            connect_pin_power(sx, sy, net, "left")
        else:
            connect_pin(sx, sy, net, "left")

    for pin_y, net in [
        (7.62, "SPI_MOSI"), (5.08, "SPI_MISO"),
        (2.54, "SPI_SCK"), (-2.54, "NRF_CSN")
    ]:
        sx = u3_x + 12.7
        sy = u3_y - pin_y
        connect_pin(sx, sy, net, "right")

    # ── DS3231 (U4) ──
    for pin_y, net, is_pwr in [
        (2.54, "+3V3", True), (-2.54, "GND", True)
    ]:
        sx = u4_x - 10.16
        sy = u4_y - pin_y
        connect_pin_power(sx, sy, net, "left")

    for pin_y, net in [(2.54, "I2C_SDA"), (-2.54, "I2C_SCL")]:
        sx = u4_x + 10.16
        sy = u4_y - pin_y
        connect_pin(sx, sy, net, "right")

    # ── Mini360 (REG1) ──
    # Left: IN(y=2.54) → VBAT, GND(y=-2.54)
    connect_pin_power(reg_x - 10.16, reg_y - 2.54, "VBAT", "left")
    connect_pin_power(reg_x - 10.16, reg_y + 2.54, "GND", "left")
    # Right: OUT(y=0) → +3V3
    connect_pin_power(reg_x + 10.16, reg_y, "+3V3", "right")

    # ── Battery (BAT1) ──
    # POS at right (pin_y=2.54): VBAT
    connect_pin_power(bat_x + 10.16, bat_y - 2.54, "VBAT", "right")
    # NEG at left (pin_y=-2.54): GND
    connect_pin_power(bat_x - 10.16, bat_y + 2.54, "GND", "left")

    # ── Assemble schematic ──
    sch = f"""(kicad_sch
  (version 20231120)
  (generator "eeschema")
  (generator_version "8.0")
  (uuid "{ROOT_UUID}")

  (paper "A3")

  (title_block
    (title "Autonomous Acoustic Station — ESP32-S3")
    (date "2026-04-07")
    (rev "1.0")
    (comment 1 "4x INMP441 + LoRa Ra-02 + nRF24L01 PA+LNA + DS3231")
    (comment 2 "I2S: 32kHz/16-bit, Ring buffer 3.84MB in PSRAM")
    (comment 3 "Li-Ion 21700 2S2P, Mini360 buck 7.4V->3.3V")
  )

  (lib_symbols
{make_lib_symbols()}
  )

{"".join(notes)}
{"".join(instances)}
{"".join(power_syms)}
{"".join(wires)}
{"".join(labels_list)}

  (sheet_instances
    (path "/"
      (page "1")
    )
  )
)
"""
    return sch


def generate_pro():
    return json.dumps({
        "meta": {
            "filename": "station.kicad_pro",
            "version": 1
        },
        "project": {
            "created": "2026-04-07 00:00:00",
            "meta": {
                "version": 2
            },
            "net_settings": {
                "classes": [{
                    "bus_width": 12,
                    "clearance": 0.2,
                    "diff_pair_gap": 0.25,
                    "diff_pair_via_gap": 0.25,
                    "diff_pair_width": 0.2,
                    "line_style": 0,
                    "microvia_diameter": 0.3,
                    "microvia_drill": 0.1,
                    "name": "Default",
                    "pcb_color": "rgba(0, 0, 0, 0.000)",
                    "schematic_color": "rgba(0, 0, 0, 0.000)",
                    "track_width": 0.2,
                    "via_diameter": 0.6,
                    "via_drill": 0.3,
                    "wire_width": 6
                }]
            },
            "schematic": {
                "legacy_lib_dir": "",
                "legacy_lib_list": []
            },
            "sheets": []
        }
    }, indent=2)


if __name__ == "__main__":
    out_dir = os.path.dirname(os.path.abspath(__file__))

    sch_path = os.path.join(out_dir, "station.kicad_sch")
    with open(sch_path, "w", encoding="utf-8") as f:
        f.write(generate())
    print(f"Written: {sch_path}")

    pro_path = os.path.join(out_dir, "station.kicad_pro")
    with open(pro_path, "w", encoding="utf-8") as f:
        f.write(generate_pro())
    print(f"Written: {pro_path}")

    print("Done. Open station.kicad_pro in KiCad 8.")
