# Battery Compartment — File Structure

## Files

| File | Purpose |
|------|---------|
| `station_battery_params.scad` | Shared parameters and computed dimensions — **edit here only** |
| `station_battery_mount.scad` | Body + stake mount — `include`s params |
| `station_battery_lid.scad` | Lid — `include`s params |

## Dependency

```
station_battery_params.scad
    ├── include → station_battery_mount.scad  (renders body + stake mount)
    └── include → station_battery_lid.scad    (renders lid)
```

## Coupling points — change both files when modifying these

| Parameter / feature | Where defined | Affects |
|---------------------|--------------|---------|
| `boss_pos` (screw boss positions) | `params.scad` | Body: tap holes in corner columns; Lid: through-holes, countersinks, lip cutouts |
| `boss_d` (boss diameter) | `params.scad` | Body: column diameter; Lid: lip cutout diameter (`boss_d + 0.4`) |
| `outer_x/y` (box footprint) | `params.scad` (computed) | Body: outer cube; Lid: plate size |
| `inner_x/y` (cavity footprint) | `params.scad` (computed) | Body: cavity cutout; Lid: lip size (`inner_x - lid_lip_gap*2`) |
| `body_z` (body height) | `params.scad` (computed) | Body: column and tap hole depth; Lid: nothing directly |
| `lid_lip_h` (lip height) | `params.scad` | Lid: lip protrusion; Body: must have matching open top |
| `lid_lip_gap` (lip clearance) | `params.scad` | Lid: lip fit in body cavity |
| `screw_depth` (tap hole depth) | `params.scad` | Body: tap hole start = `body_z - screw_depth`; Lid: screw length selection |
| `wire_hole_d` (wire hole) | `params.scad` | Lid: center hole; Body: no hole (wires exit through open top) |

## Assembly

- 4× M3×16 flat-head screws through lid countersinks into body corner boss tap holes
- Lip fits into cavity with `lid_lip_gap = 0.25mm` sliding fit
- Seal perimeter with silicone or epoxy after battery insertion

## Slicing

Print separately:
- **Body** (`station_battery_mount.scad`): flat bottom down, open top up
- **Lid** (`station_battery_lid.scad`): plate face down (lip pointing up during print)
- **Stake mount** (part of mount file): stake hole down, separate print
