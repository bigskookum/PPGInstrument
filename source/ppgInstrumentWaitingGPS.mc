using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Position;
using Toybox.System;
using Toybox.Attention;

class ppgInstrumentWaitingGPS extends WatchUi.View {

	var waitTimer = new Timer.Timer();
	const countInitValue = 5;
	var count = countInitValue;

    function initialize() {
        View.initialize();
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
    
    function timerCallback() {
   		
	    var positionInfo = Position.getInfo();
	    
	    View.findDrawableById("output").setText(positionInfo.accuracy.toString() + "/5");
	    
		if (positionInfo.accuracy < 4) {
			count = countInitValue;
			View.findDrawableById("count").setText("");
		} else {
			count--;
			View.findDrawableById("count").setText((count / 10f).format("%1.1f"));
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
