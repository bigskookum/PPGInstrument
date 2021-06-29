using Toybox.WatchUi;

class ppgInstrumentWaitingDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

	function onKey(evt)
	{
		if(evt.getKey() == WatchUi.KEY_ESC)
		{
			var cd = new WatchUi.Confirmation( "Really quit?" );
			WatchUi.pushView( cd, new QuitDelegate(), WatchUi.SLIDE_IMMEDIATE );
		}
		return true;
	}
	
	class QuitDelegate extends WatchUi.ConfirmationDelegate
	{
		function initialize()
		{
			ConfirmationDelegate.initialize();
		}
		
		function onResponse(value)
		{
			if( value == CONFIRM_YES )
			{
				// this isn't the top level view so we just quit.
				System.exit();
			}
			
			return true;
		}
	}

}