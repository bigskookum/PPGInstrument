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
        // No sport is given, so the watch records a generic activity (the documented default).
        // Do not use Activity.SPORT_FLYING: it restarts the Venu X1 when recording starts,
        // and there is no way to tell which watches accept it.
        session = ActivityRecording.createSession({:name=>"PPG"});
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
