using Toybox.WatchUi;
using Toybox.Application.Properties;

class auxMenu_in_device_menuDelegate extends WatchUi.MenuInputDelegate {

    public function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onMenuItem(item as Symbol) as Void {
        if (item == :auxMenu_in_device_menu_enable) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("in_device_menu", true);
    		} else {
				Application.getApp().setProperty("in_device_menu", true);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (item == :auxMenu_in_device_menu_disable) {
        	if ( Toybox.Application has :Storage ) {
        		Properties.setValue("in_device_menu", false);
    		} else {
				Application.getApp().setProperty("in_device_menu", false);
			}
			WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
