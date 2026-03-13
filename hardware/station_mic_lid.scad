// ============================================================
// АКУСТИЧНА СТАНЦІЯ — Мікрофонна кришка
// ------------------------------------------------------------
// 4× INMP441 Ø14мм в тетраедральному розташуванні:
//   M1 — центр, спрямований вгору (0°)
//   M2, M3, M4 — по колу, нахил 30° вниз від горизонталі,
//                азимут 0°, 120°, 240°
// З'єднання з електронним відсіком: 4× гвинт М3
// Матеріал: PETG або ASA
// ============================================================

// --- ПАРАМЕТРИ ----------------------------------------------

// Мікрофон INMP441 (кругла плата Ø14мм)
mic_d        = 14.0;
mic_hole     = 14.4;   // отвір з зазором 0.4мм
mic_depth    = 4.0;    // глибина посадки
mic_pcb_h    = 3.5;    // висота плати мікрофона

// Геометрія тетраедрального масиву
mic_radius   = 40.0;   // радіус розміщення бічних мікрофонів
                        // (відстань від центру до M2/M3/M4)
mic_tilt     = 30.0;   // нахил бічних мікрофонів від горизонталі

// Розмір кришки — відповідає електронному відсіку
// outer_x і outer_y з попереднього файлу
// Розраховуємо тут самостійно

wall         = 2.5;
pcb_x        = 90.0;
pcb_y        = 70.0;
inner_x      = pcb_x + 4.0;
inner_y      = pcb_y + 4.0;
outer_x      = inner_x + wall * 2;
outer_y      = inner_y + wall * 2;

lid_h        = 35.0;   // висота кришки (від фланця до верху)
dome_r       = 8.0;    // заокруглення верхніх кутів

// Фланець
flange_h     = 8.0;    // висота фланця (відповідає top_flange)
flange_x     = outer_x;
flange_y     = outer_y;

// Гвинти М3
screw_d      = 3.2;
screw_head_d = 6.5;
screw_head_h = 3.5;
boss_d       = 8.0;

// Захисні решітки над мікрофонами
grid_bar_w   = 1.2;    // ширина перемички решітки
grid_depth   = 1.5;    // глибина решітки над мікрофоном

// Кабельний канал від мікрофонів до електроніки
cable_d      = 4.0;

echo("=== РОЗМІРИ МІКРОФОННОЇ КРИШКИ ===");
echo("Зовнішній X:", outer_x, "мм");
echo("Зовнішній Y:", outer_y, "мм");
echo("Висота кришки:", lid_h, "мм");
echo("Радіус масиву мікрофонів:", mic_radius, "мм");
d_between = mic_radius * sqrt(2 - 2*cos(120));
echo("Відстань між бічними мікрофонами:", d_between, "мм");
echo("===================================");

// --- МОДУЛІ -------------------------------------------------

// Захисна решітка над отвором мікрофона
module mic_grid(d = mic_hole, depth = grid_depth) {
    difference() {
        cylinder(d = d, h = depth, $fn = 40);
        // Хрестоподібні прорізи
        for (angle = [0, 45, 90, 135])
            rotate([0, 0, angle])
            translate([-d/2, -grid_bar_w/2, -0.1])
            cube([d, grid_bar_w, depth + 0.2]);
        // Центральний круглий отвір
        cylinder(d = d * 0.3, h = depth + 0.2, $fn = 30);
    }
}

// Посадочне місце для мікрофона INMP441
module mic_seat(with_grid = true) {
    difference() {
        // Виступ навколо отвору для жорсткості
        cylinder(d = mic_d + wall * 2, h = mic_depth + 2, $fn = 40);
        // Отвір під плату мікрофона
        translate([0, 0, -0.1])
        cylinder(d = mic_hole, h = mic_depth + 2.1, $fn = 40);
    }
    // Решітка (якщо потрібна)
    if (with_grid)
        translate([0, 0, mic_depth])
        mic_grid();
}

// Позиції 4 мікрофонів у тетраедральному розташуванні
// M1 — центр, вертикально вгору
// M2, M3, M4 — під кутом mic_tilt, через 120°
function mic_pos(i) =
    i == 0 ? [0, 0, 0] :
    [mic_radius * cos((i-1)*120) * cos(mic_tilt),
     mic_radius * sin((i-1)*120) * cos(mic_tilt),
     mic_radius * sin(mic_tilt)];

function mic_rot(i) =
    i == 0 ? [0, 0, 0] :
    [mic_tilt, 0, (i-1)*120];

// Бобишки під гвинти М3 на фланці
module flange_bosses() {
    margin = boss_d / 2 + 1.5;
    positions = [
        [ flange_x/2 - margin,  flange_y/2 - margin],
        [-flange_x/2 + margin,  flange_y/2 - margin],
        [ flange_x/2 - margin, -flange_y/2 + margin],
        [-flange_x/2 + margin, -flange_y/2 + margin]
    ];
    for (p = positions)
        translate([p[0], p[1], 0])
        difference() {
            cylinder(d = boss_d, h = flange_h, $fn = 32);
            // Отвір під гвинт з потаєм
            translate([0, 0, flange_h - screw_head_h])
            cylinder(d = screw_head_d, h = screw_head_h + 0.1, $fn = 24);
            translate([0, 0, -0.1])
            cylinder(d = screw_d, h = flange_h + 0.2, $fn = 20);
        }
}

// --- ОСНОВНА ДЕТАЛЬ -----------------------------------------

module mic_lid() {
    difference() {
        union() {
            // Фланець (нижня частина — кріплення до електронного відсіку)
            translate([-flange_x/2, -flange_y/2, 0])
            cube([flange_x, flange_y, flange_h]);

            // Основне тіло кришки
            translate([-flange_x/2, -flange_y/2, flange_h])
            cube([flange_x, flange_y, lid_h]);

            // Бобишки на фланці
            flange_bosses();
        }

        // Внутрішня порожнина кришки
        translate([-flange_x/2 + wall,
                   -flange_y/2 + wall,
                   flange_h + wall])
        cube([flange_x - wall*2,
              flange_y - wall*2,
              lid_h]);

        // Отвори та посадки для 4 мікрофонів
        // M1 — центр, вгору (на верхній поверхні)
        translate([0, 0, flange_h + lid_h - mic_depth])
        cylinder(d = mic_hole, h = mic_depth + 0.1, $fn = 40);

        // M2, M3, M4 — бічні отвори під кутом
        for (i = [1, 2, 3]) {
            p = mic_pos(i);
            r = mic_rot(i);
            translate([p[0], p[1], flange_h + lid_h/2 + p[2]])
            rotate([r[0], r[1], r[2]])
            translate([0, 0, -wall - 0.1])
            cylinder(d = mic_hole, h = wall + mic_depth + 0.1, $fn = 40);
        }

        // Кабельний канал донизу
        translate([0, 0, flange_h - 0.1])
        cylinder(d = cable_d, h = wall + 0.2, $fn = 24);

        // Невеликий зазор по периметру фланця для ущільнювача
        translate([-flange_x/2 + wall + 0.5,
                   -flange_y/2 + wall + 0.5,
                   -0.1])
        cube([flange_x - wall*2 - 1,
              flange_y - wall*2 - 1,
              1.2]);
    }

    // Посадкові виступи для мікрофонів
    // M1 — вгорі по центру
    translate([0, 0, flange_h + lid_h - mic_depth - 2])
    difference() {
        cylinder(d = mic_d + wall*2, h = 2, $fn = 40);
        translate([0, 0, -0.1])
        cylinder(d = mic_hole, h = 2.2, $fn = 40);
    }

    // Решітки над бічними мікрофонами
    for (i = [1, 2, 3]) {
        p = mic_pos(i);
        r = mic_rot(i);
        translate([p[0], p[1], flange_h + lid_h/2 + p[2]])
        rotate([r[0], r[1], r[2]])
        translate([0, 0, mic_depth - 0.5])
        mic_grid();
    }

    // Решітка над верхнім мікрофоном M1
    translate([0, 0, flange_h + lid_h - 0.5])
    mic_grid();
}

// --- РЕНДЕР -------------------------------------------------

mic_lid();

// Для перевірки — показати позиції мікрофонів:
/*
color("red", 0.8) {
    // M1 — центр вгору
    translate([0, 0, flange_h + lid_h - mic_depth])
    cylinder(d = mic_d, h = mic_pcb_h, $fn = 40);

    // M2, M3, M4 — бічні
    for (i = [1, 2, 3]) {
        p = mic_pos(i);
        r = mic_rot(i);
        translate([p[0], p[1], flange_h + lid_h/2 + p[2]])
        rotate([r[0], r[1], r[2]])
        cylinder(d = mic_d, h = mic_pcb_h, $fn = 40);
    }
}
*/

// ============================================================
// ПРИМІТКИ ДЛЯ ДРУКУ:
// - Друкувати фланцем вниз
// - Підтримки: потрібні під бічними отворами мікрофонів
// - Заповнення: 30% gyroid
// - Периметри: 3
// - Після друку: heat inserts М3 у бобишки фланця
// - Мікрофони фіксуються на силіконовий герметик
// - Вітрозахисні насадки надягаються після встановлення
// ============================================================
