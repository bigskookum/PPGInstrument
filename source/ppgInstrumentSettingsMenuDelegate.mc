using Toybox.WatchUi;

class settingsMenuDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :settingsMenu_units_altitude) {
			WatchUi.pushView(new $.Rez.Menus.auxMenu_units_altitude(), new $.auxMenu_units_altitudeDelegate(), WatchUi.SLIDE_LEFT);
        } else if (item == :settingsMenu_units_speed) {
			WatchUi.pushView(new $.Rez.Menus.auxMenu_units_speed(), new $.auxMenu_units_speedDelegate(), WatchUi.SLIDE_LEFT);
        } else if (item == :settingsMenu_units_vspeed) {
			WatchUi.pushView(new $.Rez.Menus.auxMenu_units_vspeed(), new $.auxMenu_units_vspeedDelegate(), WatchUi.SLIDE_LEFT);
        } else if (item == :settingsMenu_units_distance) {
			WatchUi.pushView(new $.Rez.Menus.auxMenu_units_distance(), new $.auxMenu_units_distanceDelegate(), WatchUi.SLIDE_LEFT);
        } else if (item == :settingsMenu_start_speed) {
        	WatchUi.pushView(new $.start_speed_picker(), new $.start_speed_pickerDelegate(), WatchUi.SLIDE_LEFT);
        } else if (item == :settingsMenu_clock_type) {
        	WatchUi.pushView(new $.Rez.Menus.auxMenu_clock_type(), new $.auxMenu_clock_typeDelegate(), WatchUi.SLIDE_LEFT);
        } else if (item == :settingsMenu_in_device_menu) {
        	WatchUi.pushView(new $.Rez.Menus.auxMenu_in_device_menu(), new $.auxMenu_in_device_menuDelegate(), WatchUi.SLIDE_LEFT);
        }
    }
}
