import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Lang;

class auxMenu_units_distanceDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_units_distance_km) {
        	setSetting("units_distance", 0);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_units_distance_mi) {
        	setSetting("units_distance", 1);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
