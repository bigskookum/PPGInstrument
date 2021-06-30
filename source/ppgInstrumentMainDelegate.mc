using Toybox.WatchUi;
using Toybox.Application.Properties;

class ppgInstrumentMainDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    public function onMenu() as Boolean {
    	var in_device_menu;
    		
		if ( Toybox.Application has :Storage ) {
			in_device_menu = Properties.getValue("in_device_menu");
		} else {
			in_device_menu = Application.getApp().getProperty("in_device_menu");
		}
		if (in_device_menu == true) {
        	WatchUi.pushView(new $.Rez.Menus.settingsMenu(), new $.settingsMenuDelegate(), WatchUi.SLIDE_LEFT);
    	}
        return true;
    }
    
    function onKey(evt)
	{
		if(evt.getKey() == WatchUi.KEY_ESC)
		{
			var cd = new WatchUi.Confirmation( WatchUi.loadResource($.Rez.Strings.quitConf) );
			WatchUi.pushView( cd, new QuitDelegate(), WatchUi.SLIDE_IMMEDIATE );
		}
		return true;
	}
	
	function onBack() {
		// do the same thing as above.
		var cd = new WatchUi.Confirmation( WatchUi.loadResource($.Rez.Strings.quitConf) );
		WatchUi.pushView( cd, new QuitDelegate(), WatchUi.SLIDE_IMMEDIATE );
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
