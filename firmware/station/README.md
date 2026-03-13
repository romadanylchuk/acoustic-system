# Прошивка автономної станції (ESP32-S3)

## Етап 1 — TODO

- [ ] Синхронний запис 4 каналів I2S (4× INMP441)
- [ ] Кільцевий буфер 10-15 сек в PSRAM
- [ ] GCC-PHAT алгоритм для TDOA між мікрофонами
- [ ] Попередня класифікація події

## Етап 2 — TODO

- [ ] LoRa передача метаданих (Ra-02 SX1278)
- [ ] Прийом запиту з базової станції
- [ ] Передача аудіофрагменту по nRF24L01

## Підключення

### INMP441 мікрофони (I2S)

| INMP441 | ESP32-S3 | Примітка |
|---------|----------|----------|
| VDD | 3.3В | |
| GND | GND | |
| SCK | GPIO 14 | I2S шина 0 |
| WS | GPIO 15 | I2S шина 0 |
| SD | GPIO 16 | M1 (L/R=GND) |
| SD | GPIO 17 | M2 (L/R=3.3В) |
| SCK | GPIO 18 | I2S шина 1 |
| WS | GPIO 19 | I2S шина 1 |
| SD | GPIO 20 | M3 (L/R=GND) |
| SD | GPIO 21 | M4 (L/R=3.3В) |

### Ra-02 LoRa (SPI)

| Ra-02 | ESP32-S3 |
|-------|----------|
| MOSI | GPIO 11 |
| MISO | GPIO 13 |
| SCK | GPIO 12 |
| NSS | GPIO 10 |
| DIO0 | GPIO 9 |
| RST | GPIO 8 |

### nRF24L01 (SPI — спільна шина з LoRa)

| nRF24 | ESP32-S3 |
|-------|----------|
| MOSI | GPIO 11 |
| MISO | GPIO 13 |
| SCK | GPIO 12 |
| CSN | GPIO 7 |
| CE | GPIO 6 |
| IRQ | GPIO 5 |

### DS3231 RTC (I2C)

| DS3231 | ESP32-S3 |
|--------|----------|
| SDA | GPIO 3 |
| SCL | GPIO 4 |
| VCC | 3.3В |
| GND | GND |
