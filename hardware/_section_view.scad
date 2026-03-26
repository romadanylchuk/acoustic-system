use <station_mic_lid.scad>

difference() {
    mic_lid();
    // Cut away the back half to reveal vertical cross-section
    translate([-200, -200, -10])
    cube([400, 200, 200]);
}
