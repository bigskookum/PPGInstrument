using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Timer;
using Toybox.ActivityRecording;

	var session as Session;

class ppgInstrumentApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        session = ActivityRecording.createSession({:name=>"PPG", :sport=>ActivityRecording.SPORT_GENERIC});
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	if (session.isRecording()) {
    		session.stop();
    		session.save();
    	}
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new ppgInstrumentMain(), new ppgInstrumentMainDelegate() ];
    }
}
