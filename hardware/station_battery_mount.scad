// ============================================================
// АКУСТИЧНА СТАНЦІЯ — Акумуляторний відсік + Кришка + Кріплення
// ------------------------------------------------------------
// Конфігурація: 4× 21700 Li-Ion (2S2P), 2×2 блок
// Кріплення: арматура Ø12мм, глибина 50мм
// З'єднання з електронним відсіком: 4× гвинт М3
// Матеріал друку: PETG або ASA
// Шар: 0.2мм, заповнення 40%, периметри 3
// ============================================================

// --- ПАРАМЕТРИ (змінюй тут) ---------------------------------

// Елемент 21700
cell_d       = 21.0;   // діаметр елемента
cell_l       = 70.0;   // довжина елемента
cell_gap     = 1.5;    // зазор між елементами
wall         = 2.5;    // товщина стінки
floor_h      = 3.0;    // товщина дна

// Кришка
lid_h        = 3.5;    // товщина кришки
lid_lip_h    = 2.5;    // висота центрувального бортику кришки
lid_lip_gap  = 0.25;   // зазор бортику (посадка ковзання)

// Кілок
stake_d      = 12.0;   // діаметр арматури
stake_hole   = 12.6;   // отвір з зазором
stake_depth  = 50.0;   // глибина посадки
stake_wall   = 4.0;    // товщина стінки кріплення кілка

// Хомут (пази)
hose_w       = 8.0;    // ширина пазу під хомут
hose_d       = 3.0;    // глибина пазу
hose_count   = 2;      // кількість пазів

// Гвинти М3
screw_d      = 3.2;    // наскрізний отвір у кришці (М3 clearance)
screw_tap_d  = 2.7;    // глухий отвір у бобишці (різьба М3 у пластик)
screw_head_d = 6.0;    // зенківка під голівку М3
screw_head_h = 3.0;    // глибина зенківки
screw_depth  = 12.0;   // глибина глухого отвору в бобишці
boss_d       = 8.0;    // діаметр бобишки

// Дріт між відсіками
wire_hole_d  = 6.0;    // отвір для дротів у кришці

// --- РОЗРАХУНКОВІ РОЗМІРИ -----------------------------------

// 2×2 блок акумуляторів
block_x = cell_d * 2 + cell_gap * 3;   // ~45мм
block_y = cell_d * 2 + cell_gap * 3;   // ~45мм

// Внутрішній розмір відсіку
inner_x = block_x;
inner_y = block_y;
inner_z = cell_l + 4.0;   // +2мм з кожного боку

// Зовнішній розмір відсіку
outer_x = inner_x + wall * 2;
outer_y = inner_y + wall * 2;
body_z  = inner_z + floor_h;   // висота корпусу (без кришки)

// Кріплення кілка
mount_od = stake_hole + stake_wall * 2;
mount_h  = stake_depth + 10.0;   // +10мм над землею

// Позиції бобишок (спільні для корпусу та кришки)
boss_margin = boss_d / 2 + 1.0;
boss_pos = [
    [ outer_x/2 - boss_margin,  outer_y/2 - boss_margin],
    [-outer_x/2 + boss_margin,  outer_y/2 - boss_margin],
    [ outer_x/2 - boss_margin, -outer_y/2 + boss_margin],
    [-outer_x/2 + boss_margin, -outer_y/2 + boss_margin]
];

echo("=== РОЗМІРИ ВІДСІКУ ===");
echo("Зовнішній X:", outer_x, "мм");
echo("Зовнішній Y:", outer_y, "мм");
echo("Корпус Z:", body_z, "мм  (без кришки)");
echo("Кришка Z:", lid_h, "мм");
echo("Загальна висота:", body_z + lid_h, "мм");
echo("Блок акумуляторів:", block_x, "×", block_y, "мм");
echo("======================");

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

// Бобишки під гвинти М3 — повна висота корпусу, слугують опорою для кришки
module screw_bosses_body() {
    for (p = boss_pos)
        translate([p[0], p[1], 0])
        cylinder(d = boss_d, h = body_z, $fn = 32);
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

// --- КОРПУС ВІДСІКУ (відкритий зверху) ----------------------

module battery_compartment() {
    difference() {
        union() {
            // Основний корпус
            translate([-outer_x/2, -outer_y/2, 0])
            cube([outer_x, outer_y, body_z]);
            // Бобишки від дна до верхнього краю
            screw_bosses_body();
        }

        // Внутрішня порожнина (повністю відкрита зверху — вставляємо акумулятори)
        translate([-inner_x/2, -inner_y/2, floor_h])
        cube([inner_x, inner_y, inner_z + 1]);

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

// --- КРИШКА -------------------------------------------------
// Плоска плита + центрувальний бортик знизу, що входить у порожнину корпусу

module battery_lid() {
    // Ширина бортику (вписується у внутрішню порожнину з зазором lid_lip_gap)
    lip_x = inner_x - lid_lip_gap * 2;
    lip_y = inner_y - lid_lip_gap * 2;

    difference() {
        union() {
            // Плита кришки
            translate([-outer_x/2, -outer_y/2, 0])
            cube([outer_x, outer_y, lid_h]);

            // Центрувальний бортик (виступає вниз, входить у корпус)
            translate([-lip_x/2, -lip_y/2, -lid_lip_h])
            cube([lip_x, lip_y, lid_lip_h]);
        }

        // Отвір для дротів до електронного відсіку (центр)
        translate([0, 0, -lid_lip_h - 0.1])
        cylinder(d = wire_hole_d, h = lid_h + lid_lip_h + 0.2, $fn = 30);

        // М3 наскрізні отвори + зенківка під голівку гвинта (зверху кришки)
        for (p = boss_pos) {
            // Наскрізний отвір
            translate([p[0], p[1], -lid_lip_h - 0.1])
            cylinder(d = screw_d, h = lid_h + lid_lip_h + 0.2, $fn = 20);
            // Зенківка під голівку
            translate([p[0], p[1], lid_h - screw_head_h])
            cylinder(d = screw_head_d, h = screw_head_h + 0.1, $fn = 24);
        }

        // Вирізи у бортику під бобишки корпусу (бортик їх обходить)
        for (p = boss_pos)
            translate([p[0], p[1], -lid_lip_h - 0.1])
            cylinder(d = boss_d + 0.4, h = lid_lip_h + 0.2, $fn = 32);
    }
}

// --- ЗБІРКА / ВИВІД ДЛЯ СЛАЙСЕРА ---------------------------

// Корпус відсіку
battery_compartment();

// Кріплення кілка — знизу відсіку
translate([0, 0, -mount_h + 5])
stake_mount();

// Кришка поруч (для слайсера — друкувати окремо)
translate([outer_x + 15, 0, lid_h])
rotate([180, 0, 0])
battery_lid();

// ============================================================
// ПРИМІТКИ ДЛЯ ДРУКУ:
// - Корпус: дном на стіл, верхній отвір догори — акумулятори вставляти зверху
// - Кришка: плитою на стіл (бортик дивиться вгору при друці)
// - Кріплення: кілком вниз, друкувати окремо
// - Підтримки: тільки під отвором кілка (у кріпленні кілка)
// - Заповнення: 40% gyroid, периметри 3
// - Збирання: вставити акумулятори, накрити кришкою, закрутити 4× М3×16
//              по периметру кришки нанести клей (силікон або епоксид)
// ============================================================
