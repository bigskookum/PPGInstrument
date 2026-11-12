import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Lang;

class auxMenu_units_speedDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_units_speed_kmh) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("units_speed", 0);
    		} else {
				Application.getApp().setProperty("units_speed", 0);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_units_speed_mph) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("units_speed", 1);
    		} else {
				Application.getApp().setProperty("units_speed", 1);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
