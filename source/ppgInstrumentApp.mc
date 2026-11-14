import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.ActivityRecording;
import Toybox.Activity;

	var session as Session?;

	// Switches off everything the app turned on. The watch is supposed to do this itself
	// when an app exits, but GPS left running after exit drains the battery until the
	// watch is restarted, so do it explicitly. Safe to call more than once.
	function shutDown() as Void {
		var s = session;
		session = null;
		if (s != null) {
			if (s.isRecording()) {
				s.stop();
				s.save();
			} else {
				// Never started (quit before the start trigger): nothing worth keeping.
				s.discard();
			}
		}
		Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
		Sensor.enableSensorEvents(null);
	}

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
    	shutDown();
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new ppgInstrumentMain(), new ppgInstrumentMainDelegate() ];
    }
}
