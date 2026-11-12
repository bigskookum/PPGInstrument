import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Lang;

class auxMenu_units_altitudeDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_units_altitude_m) {
        	setSetting("units_altitude", 0);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_units_altitude_ft) {
        	setSetting("units_altitude", 1);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
