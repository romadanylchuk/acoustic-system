// ============================================================
// АКУСТИЧНА СТАНЦІЯ — Акумуляторний відсік + Кріплення кілка
// ------------------------------------------------------------
// Конфігурація: 4× 21700 Li-Ion (2S2P), 2×2 блок
// Кріплення: арматура Ø12мм, глибина 50мм
// З'єднання з кришкою: 4× гвинт М3×16 у внутрішніх кутових бобишках
// Матеріал друку: PETG або ASA
// Шар: 0.2мм, заповнення 40%, периметри 3
//
// Параметри: station_battery_params.scad
// Кришка:    station_battery_lid.scad
// ============================================================

include <station_battery_params.scad>

// --- МОДУЛІ -------------------------------------------------

// Один циліндричний отвір під елемент 21700
module cell_hole(extra = 0.4) {
    cylinder(d = cell_d + extra, h = inner_z + 1, $fn = 60);
}

// 4 отвори під елементи в конфігурації 2×2
module cell_array() {
    step = cell_d + cell_gap;
    for (xi = [0, 1])
        for (yi = [0, 1])
            translate([
                xi * step - step/2 + step/2,
                yi * step - step/2 + step/2,
                floor_h
            ])
            cell_hole();
}

// Пази під хомут на кріпленні кілка
module hose_clamp_slots() {
    slot_positions = [mount_h * 0.3, mount_h * 0.7];
    for (z = slot_positions)
        translate([0, 0, z])
        rotate_extrude($fn = 64)
        translate([mount_od/2 - hose_d, 0, 0])
        square([hose_d + 0.1, hose_w], center = true);
}

// Кріплення під кілок
module stake_mount() {
    difference() {
        union() {
            cylinder(d = mount_od, h = mount_h, $fn = 64);
            translate([-outer_x/2, -outer_y/2, mount_h - 5])
            cube([outer_x, outer_y, 5]);
        }
        translate([0, 0, -0.1])
        cylinder(d = stake_hole, h = stake_depth + 0.1, $fn = 40);
        hose_clamp_slots();
    }
}

// Корпус відсіку (відкритий зверху)
module battery_compartment() {
    difference() {
        union() {
            // Корпус-оболонка: зовнішній куб мінус внутрішня порожнина
            // (вкладений difference — бобишки додаються після, щоб порожнина їх не зʼїдала)
            difference() {
                translate([-outer_x/2, -outer_y/2, 0])
                    cube([outer_x, outer_y, body_z]);
                translate([-inner_x/2, -inner_y/2, floor_h])
                    cube([inner_x, inner_y, inner_z + 1]);
            }
            // Внутрішні кутові бобишки — виступають у порожнину між елементами і стінкою
            for (p = boss_pos)
                translate([p[0], p[1], 0])
                    cylinder(d = boss_d, h = body_z, $fn = 32);
        }

        // Циліндричні напрямні під елементи
        translate([-block_x/2 + cell_gap + cell_d/2,
                   -block_y/2 + cell_gap + cell_d/2, 0])
        cell_array();

        // Глухі різьбові отвори М3 у бобишках (кришка кріпиться гвинтами зверху)
        for (p = boss_pos)
            translate([p[0], p[1], body_z - screw_depth])
            cylinder(d = screw_tap_d, h = screw_depth + 0.1, $fn = 20);
    }
}

// --- ВИВІД ДЛЯ СЛАЙСЕРА -------------------------------------

// Корпус відсіку
battery_compartment();

// Кріплення кілка — знизу відсіку
translate([0, 0, -mount_h + 5])
stake_mount();

// ============================================================
// ПРИМІТКИ ДЛЯ ДРУКУ:
// - Корпус: дном на стіл, верхній отвір догори — акумулятори вставляти зверху
// - Кріплення: кілком вниз, друкувати окремо
// - Підтримки: тільки під отвором кілка (у кріпленні кілка)
// - Заповнення: 40% gyroid, периметри 3
// - Збирання: вставити акумулятори, накрити кришкою (station_battery_lid.scad),
//              закрутити 4× М3×16; по периметру кришки нанести клей (силікон або епоксид)
// ============================================================
