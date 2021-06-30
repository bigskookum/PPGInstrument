using Toybox.WatchUi;
using Toybox.Application.Properties;

class auxMenu_clock_typeDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_clock_type_system) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("clock_type", 0);
    		} else {
				Application.getApp().setProperty("clock_type", 0);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_clock_type_24h) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("clock_type", 1);
    		} else {
				Application.getApp().setProperty("clock_type", 1);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_clock_type_12h) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("clock_type", 2);
    		} else {
				Application.getApp().setProperty("clock_type", 2);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
