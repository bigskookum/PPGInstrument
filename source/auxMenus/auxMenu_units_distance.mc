using Toybox.WatchUi;
using Toybox.Application.Properties;

class auxMenu_units_distanceDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_units_distance_km) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("units_distance", 0);
    		} else {
				Application.getApp().setProperty("units_distance", 0);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_units_distance_mi) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("units_distance", 1);
    		} else {
				Application.getApp().setProperty("units_distance", 1);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
