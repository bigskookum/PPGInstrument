import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Lang;

class auxMenu_units_vspeedDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_units_vspeed_mps) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("units_vspeed", 0);
    		} else {
				Application.getApp().setProperty("units_vspeed", 0);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_units_vspeed_fpm) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("units_vspeed", 1);
    		} else {
				Application.getApp().setProperty("units_vspeed", 1);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
