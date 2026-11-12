import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Timer;
import Toybox.ActivityRecording;
import Toybox.Activity;

	var session as Session?;

class ppgInstrumentApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        // Record as a flying activity where the watch knows that sport (Connect IQ 3.2+).
        // Older watches fall back to the default, which is a generic activity.
        if (Toybox.Activity has :SPORT_FLYING) {
        	session = ActivityRecording.createSession({:name=>"PPG", :sport=>Activity.SPORT_FLYING});
        } else {
        	session = ActivityRecording.createSession({:name=>"PPG"});
        }
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	var s = session;
    	if (s != null && s.isRecording()) {
    		s.stop();
    		s.save();
    	}
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new ppgInstrumentMain(), new ppgInstrumentMainDelegate() ];
    }
}
