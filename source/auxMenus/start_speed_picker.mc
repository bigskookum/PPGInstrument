using Toybox.Application.Properties;
import Toybox.WatchUi;

class start_speed_picker extends WatchUi.Picker {

    public function initialize() {
    	var title = new WatchUi.Text({	:text=>$.Rez.Strings.start_speed_title_short,
    									:locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            							:locY=>WatchUi.LAYOUT_VALIGN_BOTTOM,
            							:color=>Graphics.COLOR_WHITE
            							});
		var factory = new $.NumberFactory(0, 99, 1, {}); // start, stop, increment, format, font
		
		// set initial value to current stored value.
		var start_speed;
		if ( Toybox.Application has :Storage ) {
			start_speed = Properties.getValue("start_speed");
		} else {
			start_speed = Application.getApp().getProperty("start_speed");
		}
    	var defaults = [factory.getIndex(start_speed)];
    
    	Picker.initialize({:title=>title, :pattern=>[factory], :defaults=>defaults});
    }

    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }
}

class start_speed_pickerDelegate extends WatchUi.PickerDelegate {

    public function initialize() {
        PickerDelegate.initialize();
    }

    public function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    public function onAccept(values as Array<Number?>) as Boolean {
		if ( Toybox.Application has :Storage ) {
			Properties.setValue("start_speed", values[0]);
		} else {
			Application.getApp().setProperty("start_speed", values[0]);
		}

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

}
