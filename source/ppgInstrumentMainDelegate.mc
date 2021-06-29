using Toybox.WatchUi;

class ppgInstrumentMainDelegate extends WatchUi.BehaviorDelegate {

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
				// pop the confirmation dialog associated with this delegate
				WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
				
				// the system will automatically pop the top level dialog
			}
			
			return true;
		}
	}
}