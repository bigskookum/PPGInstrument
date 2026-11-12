import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Lang;

class auxMenu_units_vspeedDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_units_vspeed_mps) {
        	setSetting("units_vspeed", 0);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_units_vspeed_fpm) {
        	setSetting("units_vspeed", 1);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
