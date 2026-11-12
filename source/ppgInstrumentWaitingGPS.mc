import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Position;
import Toybox.System;
import Toybox.Attention;
import Toybox.Lang;

class ppgInstrumentWaitingGPS extends WatchUi.View {

	var waitTimer = new Timer.Timer();
	const countInitValue = 5;
	var count = countInitValue;

    function initialize() {
        View.initialize();
    }

    // Layout labels are all WatchUi.Text; findDrawableById only promises a Drawable.
    function label(id as String) as Text {
        return View.findDrawableById(id) as Text;
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WaitingGPSLayout(dc));
        waitTimer.start(method(:timerCallback), 100, true);
    	count = countInitValue; // used to be 40 for 4 seconds but fuggit
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
    
    function timerCallback() as Void {
   		
	    var positionInfo = Position.getInfo();
	    
	    label("output").setText(positionInfo.accuracy.toString() + "/5");
	    
		if (positionInfo.accuracy < 4) {
			count = countInitValue;
			label("count").setText("");
		} else {
			count--;
			label("count").setText((count / 10f).format("%1.1f"));
			if (count == 0) { // four seconds of good gps data
				if (Attention has :playTone) {
				   Attention.playTone(Attention.TONE_ALERT_HI);
				}
				if (Attention has :vibrate) {
					var vibeData = [new Attention.VibeProfile(50, 1000)];
					Attention.vibrate(vibeData);
				}
				waitTimer.stop();
				WatchUi.popView(WatchUi.SLIDE_UP);
			}
		}
		
		WatchUi.requestUpdate();
    }
}
