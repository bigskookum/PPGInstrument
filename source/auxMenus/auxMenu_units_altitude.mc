using Toybox.WatchUi;
using Toybox.Application.Properties;

class auxMenu_units_altitudeDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_units_altitude_m) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("units_altitude" ,0);
    		} else {
				Application.getApp().setProperty("units_altitude", 0);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_units_altitude_ft) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("units_altitude", 1);
    		} else {
				Application.getApp().setProperty("units_altitude", 1);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
