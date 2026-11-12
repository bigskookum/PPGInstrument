import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Lang;

class auxMenu_clock_typeDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_clock_type_system) {
        	setSetting("clock_type", 0);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_clock_type_24h) {
        	setSetting("clock_type", 1);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_clock_type_12h) {
        	setSetting("clock_type", 2);
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
