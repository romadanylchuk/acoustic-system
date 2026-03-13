// ============================================================
// АКУСТИЧНА СТАНЦІЯ — Електронний відсік
// ------------------------------------------------------------
// Вміст: ESP32-S3 + макетна плата 70×90мм
//         nRF24L01 PA+LNA + DS3231 + Mini360 + 2S BMS
// З'єднання з акумуляторним відсіком: 4× гвинт М3
// З'єднання з мікрофонною кришкою: 4× гвинт М3
// Матеріал: PETG або ASA
// ============================================================

// --- ПАРАМЕТРИ КОМПОНЕНТІВ ----------------------------------

// Макетна плата 7×9см (основа монтажу)
pcb_x        = 90.0;
pcb_y        = 70.0;
pcb_h        = 1.6;
pcb_comp_h   = 15.0;  // висота компонентів над платою

// ESP32-S3-DevKitC-1
esp_x        = 57.15;
esp_y        = 27.94;
esp_h        = 10.0;
esp_usb_w    = 9.0;   // ширина USB-C роз'єму
esp_usb_h    = 4.0;   // висота USB-C роз'єму

// nRF24L01 PA+LNA
nrf_x        = 40.8;
nrf_y        = 15.3;
nrf_h        = 10.0;
nrf_sma_d    = 9.0;   // діаметр SMA роз'єму

// DS3231 RTC
rtc_x        = 45.0;
rtc_y        = 23.0;
rtc_h        = 14.0;

// Mini360 DC-DC
mini_x       = 18.0;
mini_y       = 12.0;
mini_h       = 8.0;   // з підстроювальним резистором

// 2S BMS
bms_x        = 47.4;
bms_y        = 23.6;
bms_h        = 4.0;

// --- ПАРАМЕТРИ КОРПУСУ --------------------------------------

wall         = 2.5;
floor_h      = 3.0;
top_flange   = 8.0;   // фланець для кріплення мікрофонної кришки

// Внутрішній розмір — під макетну плату + зазор
inner_x      = pcb_x + 4.0;
inner_y      = pcb_y + 4.0;
inner_z      = pcb_h + pcb_comp_h + 6.0;  // плата + компоненти + запас

// Зовнішній розмір
outer_x      = inner_x + wall * 2;
outer_y      = inner_y + wall * 2;
outer_z      = inner_z + floor_h;

// Гвинти М3
screw_d      = 3.2;
screw_head_d = 6.0;
screw_head_h = 3.0;
boss_d       = 8.0;
boss_h       = floor_h + 3.0;

// Отвір для дротів з акумуляторного відсіку
wire_hole_d  = 6.0;

// Антена nRF24 — бічний отвір SMA
sma_d        = 10.0;

// USB-C отвір для програмування
usb_w        = 10.0;
usb_h        = 5.0;

echo("=== РОЗМІРИ ЕЛЕКТРОННОГО ВІДСІКУ ===");
echo("Зовнішній X:", outer_x, "мм");
echo("Зовнішній Y:", outer_y, "мм");
echo("Зовнішній Z:", outer_z, "мм");
echo("Внутрішній X:", inner_x, "мм");
echo("Внутрішній Y:", inner_y, "мм");
echo("=====================================");

// --- МОДУЛІ -------------------------------------------------

// Бобишка під гвинт М3
module screw_boss(h = boss_h, with_countersink = false) {
    difference() {
        cylinder(d = boss_d, h = h, $fn = 32);
        translate([0, 0, -0.1])
            cylinder(d = screw_d, h = h + 0.2, $fn = 20);
        if (with_countersink)
            translate([0, 0, h - screw_head_h])
            cylinder(d = screw_head_d, h = screw_head_h + 0.1, $fn = 24);
    }
}

// 4 бобишки по кутах — нижні (з'єднання з акумулятором)
module bottom_bosses() {
    margin = boss_d / 2 + 1.5;
    positions = [
        [ outer_x/2 - margin,  outer_y/2 - margin],
        [-outer_x/2 + margin,  outer_y/2 - margin],
        [ outer_x/2 - margin, -outer_y/2 + margin],
        [-outer_x/2 + margin, -outer_y/2 + margin]
    ];
    for (p = positions)
        translate([p[0], p[1], 0])
        screw_boss(h = boss_h, with_countersink = false);
}

// 4 бобишки по кутах — верхні (з'єднання з мікрофонною кришкою)
module top_bosses() {
    margin = boss_d / 2 + 1.5;
    positions = [
        [ outer_x/2 - margin,  outer_y/2 - margin],
        [-outer_x/2 + margin,  outer_y/2 - margin],
        [ outer_x/2 - margin, -outer_y/2 + margin],
        [-outer_x/2 + margin, -outer_y/2 + margin]
    ];
    for (p = positions)
        translate([p[0], p[1], outer_z - 2])
        cylinder(d = boss_d, h = top_flange + 2, $fn = 32);
}

// Стійки під макетну плату (4 кути)
module pcb_standoffs() {
    h     = floor_h + 4.0;  // висота стійки
    d_out = 5.0;
    d_in  = 2.5;            // М2.5 або просто тримає плату
    positions = [
        [ pcb_x/2 - 3,  pcb_y/2 - 3],
        [-pcb_x/2 + 3,  pcb_y/2 - 3],
        [ pcb_x/2 - 3, -pcb_y/2 + 3],
        [-pcb_x/2 + 3, -pcb_y/2 + 3],
    ];
    for (p = positions)
        translate([p[0], p[1], 0])
        difference() {
            cylinder(d = d_out, h = h, $fn = 24);
            translate([0, 0, -0.1])
            cylinder(d = d_in, h = h + 0.2, $fn = 20);
        }
}

// Напрямні ребра для фіксації макетної плати
module pcb_guides() {
    rib_h = floor_h + pcb_h + 1.0;
    rib_w = 2.0;
    // По довжині X
    for (sy = [-1, 1])
        translate([-pcb_x/2, sy * (pcb_y/2 - rib_w/2) - rib_w/2, 0])
        cube([pcb_x, rib_w, rib_h]);
}

// --- ОСНОВНА ДЕТАЛЬ -----------------------------------------

module electronics_compartment() {
    difference() {
        union() {
            // Основний корпус
            translate([-outer_x/2, -outer_y/2, 0])
            cube([outer_x, outer_y, outer_z]);

            // Фланець зверху під мікрофонну кришку
            translate([-outer_x/2, -outer_y/2, outer_z])
            cube([outer_x, outer_y, top_flange]);

            // Бобишки нижні (до акумулятора)
            bottom_bosses();

            // Бобишки верхні (до мікрофонної кришки)
            top_bosses();

            // Стійки під макетну плату
            pcb_standoffs();
        }

        // Внутрішня порожнина
        translate([-inner_x/2, -inner_y/2, floor_h])
        cube([inner_x, inner_y, inner_z + top_flange + 0.1]);

        // Отвір для дротів знизу (з акумулятора)
        translate([0, 0, -0.1])
        cylinder(d = wire_hole_d, h = floor_h + 0.2, $fn = 30);

        // Отвір USB-C для програмування ESP32
        // (на передній стінці, Y+)
        translate([-usb_w/2, outer_y/2 - 0.1, floor_h + 8])
        cube([usb_w, wall + 0.2, usb_h]);

        // Отвір SMA антени nRF24
        // (на правій стінці, X+)
        translate([outer_x/2 - 0.1,
                   -nrf_y/2,
                   floor_h + pcb_h + 4 + nrf_h/2])
        rotate([0, 90, 0])
        cylinder(d = sma_d, h = wall + 0.2, $fn = 30);

        // Отвір антени LoRa Ra-02 (IPEX кабель до SMA на кришці)
        // на верхньому фланці — прохід кабелю
        translate([-3, outer_y/2 - wall - 0.1,
                   outer_z + top_flange/2])
        cube([6, wall + 0.2, top_flange/2 + 0.1]);

        // Гвинти М3 верхнього фланця (наскрізні)
        top_screw_holes();

        // Гвинти М3 нижнього фланця (наскрізні)
        bottom_screw_holes();

        // Зрізати напрямні ребра з внутрішньої порожнини
        translate([-inner_x/2, -inner_y/2, floor_h])
        cube([inner_x, inner_y, inner_z]);
    }

    // Напрямні ребра (додаємо після різниці)
    // pcb_guides();  // розкоментуй якщо потрібні
}

// Наскрізні отвори для верхніх гвинтів
module top_screw_holes() {
    margin = boss_d / 2 + 1.5;
    positions = [
        [ outer_x/2 - margin,  outer_y/2 - margin],
        [-outer_x/2 + margin,  outer_y/2 - margin],
        [ outer_x/2 - margin, -outer_y/2 + margin],
        [-outer_x/2 + margin, -outer_y/2 + margin]
    ];
    for (p = positions)
        translate([p[0], p[1], outer_z - 0.1])
        cylinder(d = screw_d, h = top_flange + 0.2, $fn = 20);
}

// Наскрізні отвори для нижніх гвинтів
module bottom_screw_holes() {
    margin = boss_d / 2 + 1.5;
    positions = [
        [ outer_x/2 - margin,  outer_y/2 - margin],
        [-outer_x/2 + margin,  outer_y/2 - margin],
        [ outer_x/2 - margin, -outer_y/2 + margin],
        [-outer_x/2 + margin, -outer_y/2 + margin]
    ];
    for (p = positions)
        translate([p[0], p[1], -0.1])
        cylinder(d = screw_d, h = boss_h + 0.2, $fn = 20);
}

// --- РЕНДЕР -------------------------------------------------

electronics_compartment();

// Для перевірки розміщення компонентів —
// розкоментуй блок нижче:

/*
color("green", 0.3)
translate([-pcb_x/2, -pcb_y/2, floor_h + 4])
cube([pcb_x, pcb_y, pcb_h]);  // макетна плата

color("red", 0.5)
translate([-esp_x/2, -esp_y/2, floor_h + 4 + pcb_h])
cube([esp_x, esp_y, esp_h]);   // ESP32-S3

color("blue", 0.5)
translate([-bms_x/2, -bms_y/2 - 20, floor_h + 4 + pcb_h])
cube([bms_x, bms_y, bms_h]);   // BMS

color("yellow", 0.5)
translate([-rtc_x/2, pcb_y/2 - rtc_y - 5, floor_h + 4 + pcb_h])
cube([rtc_x, rtc_y, rtc_h]);   // DS3231

color("orange", 0.5)
translate([pcb_x/2 - mini_x - 5, pcb_y/2 - mini_y - 5,
           floor_h + 4 + pcb_h])
cube([mini_x, mini_y, mini_h]); // Mini360
*/

// ============================================================
// ПРИМІТКИ ДЛЯ ДРУКУ:
// - Друкувати дном вниз
// - Підтримки: не потрібні
// - Заповнення: 40% gyroid
// - Периметри: 3
// - Після друку: heat inserts М3 у всі бобишки
// - USB-C отвір: для підключення програматора
// - SMA отвір: для антени nRF24L01
// ============================================================
