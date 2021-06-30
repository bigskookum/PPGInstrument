using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Timer;
using Toybox.System;
using Toybox.Math;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.Sensor;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Attention;

// TODO: make activity recording selectable: on minspeed, always, never.
// TODO: make colours configurable.
// TODO: play with the backlight while flying to see if it makes a difference.
// TODO: auto zero altitude on takeoff option for people who want AGL.
// TODO: check for TODOs.

var homeTrianglePoints;

class dhomeTriangle extends WatchUi.Drawable {

	public function initialize(params as Dictionary) {
		Drawable.initialize(params);
	}

    function draw(dc as Dc) as Void {
    	dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
    	if (homeTrianglePoints != null) {
        	dc.fillPolygon(homeTrianglePoints);
        }
    }
}

class ppgInstrumentMain extends WatchUi.View {

	var B612Bold_xl as FontResource?;
	var B612Bold_l as FontResource?;
	var B612Bold_m as FontResource?;
	var B612Bold_s as FontResource?;
	
	var altForVSpeed = new[5];
	var vSpeedVal;
	var vSpeedValValidCount = 5;
	var homeAngleRad = 0;
	
	var settings;
    var w;
    var h;
	
	var recordingState = 0;
	var startMoment as Moment;
	var startLocation as Location;
	
	var oneSecondTimer;

    function initialize() {
        View.initialize();
        
        B612Bold_xl = WatchUi.loadResource($.Rez.Fonts.B612Bold_xl) as FontResource;
        B612Bold_l = WatchUi.loadResource($.Rez.Fonts.B612Bold_l) as FontResource;
        B612Bold_m = WatchUi.loadResource($.Rez.Fonts.B612Bold_m) as FontResource;
        B612Bold_s = WatchUi.loadResource($.Rez.Fonts.B612Bold_s) as FontResource;
        
        settings = System.getDeviceSettings();
        w = settings.screenWidth;
        h = settings.screenHeight;

        for (var i = 0; i < 5; i++) {
        	altForVSpeed[i] = 0;
        }
    }

    function onLayout(dc) {
    	setLayout($.Rez.Layouts.mainLayout(dc));
    	
    	Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:gpsUpdatedCallback));
        
        Sensor.setEnabledSensors([] as Array<SensorType>);
        Sensor.enableSensorEvents(method(:sensorCallback));
        
        oneSecondTimer = new Timer.Timer();
    	
    	View.findDrawableById("lblVs").setFont(B612Bold_m);
    	View.findDrawableById("lblSpeed").setFont(B612Bold_xl);
    	View.findDrawableById("lblHeading").setFont(B612Bold_m);
    	View.findDrawableById("lblAltMsl").setFont(B612Bold_xl);
    	View.findDrawableById("lblCurrentTime").setFont(B612Bold_s);
    	View.findDrawableById("lblMissionTimer").setFont(B612Bold_xl);
    	View.findDrawableById("lblDistHome").setFont(B612Bold_m);
    	View.findDrawableById("lblDistTrack").setFont(B612Bold_m);
    
    	// on startup, go immediately to GPS wait screen.
        pushView(new ppgInstrumentWaitingGPS(), new ppgInstrumentWaitingDelegate(), WatchUi.SLIDE_IMMEDIATE);
        
    }
    
    function onShow() {
    	oneSecondTimer.start(method(:oneSecondTimerCallback), 1000, true);
    }
    
    function onUpdate(dc) {

        if (recordingState < 1) {
        	// blank out data.
        	View.findDrawableById("lblDistHome").setText("");
        	View.findDrawableById("lblDistHomeLbl").setText("");
        	View.findDrawableById("lblDistTrack").setText("");
        	View.findDrawableById("lblDistTrackLbl").setText("");
    	}

        View.onUpdate(dc);
    }
    
    function onHide() {
    	oneSecondTimer.stop();
    }
    
    
    /*****************************************************
                         CALLBACKS
                     gpsUpdatedCallback
                   oneSecondTimerCallback
                      sensorCallback
    *****************************************************/
    
    function gpsUpdatedCallback(info) {
    	var speed as float;
    	
    	if (info.accuracy == 4) {
    		var headingDeg = Math.toDegrees(info.heading);
    		if (headingDeg < 0) {
    			headingDeg += 360;
    		}
    		
    		var units_speed;
    		
    		if ( Toybox.Application has :Storage ) {
				units_speed = Properties.getValue("units_speed");
			} else {
				units_speed = Application.getApp().getProperty("units_speed");
			}
    		
    		if (units_speed == 0 ) { // km/h
    			speed = info.speed * 3.6f; // convert m/s to km/h
    			View.findDrawableById("lblSpeedLblk").setText("k");
    			View.findDrawableById("lblSpeedLblm").setText("m");
    		} else { // ==1 is mph
    			speed = info.speed * 2.23694f; // convert m/s to mph
    			View.findDrawableById("lblSpeedLblk").setText("m");
    			View.findDrawableById("lblSpeedLblm").setText("p");
    		}
    		
    		View.findDrawableById("lblSpeed").setText(speed.format("%2.0f"));
			View.findDrawableById("lblHeading").setText(headingDeg.format("%3.0f")); // source in true degrees
			
			if (recordingState >= 1) {
				var distHome;
				var startLocationRads = startLocation.toRadians();
				var thisLocationRads = info.position.toRadians();
				distHome = distance_rad_m(startLocationRads[0], startLocationRads[1], thisLocationRads[0], thisLocationRads[1]) ;
				homeAngleRad = bearing_rad_rad(startLocationRads[0], startLocationRads[1], thisLocationRads[0], thisLocationRads[1]) - info.heading;
				
				// there are both screens that are wider than tall (fr920xt) and taller than wide (vivoactive HR)
		    	// so find the smallest dimension before drawing the circle.
		    	// TODO: have the arrow go all the way to the edge on rectangular devices.
		    	var minDim = w > h ? h : w;
		    	var screenCenterPoint = [w/2, h/2] as Array<Number>;
				homeTrianglePoints = generateHomeTriangleCoordinates(screenCenterPoint, homeAngleRad - Math.PI, 30, 50, minDim/2);
				
				var actInfo = Activity.getActivityInfo();
				
				if (actInfo.elapsedDistance != null) { // TODO: fix this workaround. seems to only occur with the simulator.
				
				var units_distance;
				
				if ( Toybox.Application has :Storage ) {
					units_distance = Properties.getValue("units_distance");
				} else {
					units_distance = Application.getApp().getProperty("units_distance");
				}
				
					if (units_distance == 0) { // 0 == km
						View.findDrawableById("lblDistHome").setText((Math.floor(distHome / 100.0f)/10).format("%2.1f"));
						View.findDrawableById("lblDistTrack").setText(Math.floor(actInfo.elapsedDistance / 1000f).format("%3.0f"));
						View.findDrawableById("lblDistTrackLbl").setText("tot km");
					} else { // 1 == mi
						View.findDrawableById("lblDistHome").setText((Math.floor(distHome / 160.934f)/10).format("%2.1f"));
						View.findDrawableById("lblDistTrack").setText(Math.floor(actInfo.elapsedDistance / 1609.34f).format("%3.0f"));
						View.findDrawableById("lblDistTrackLbl").setText("tot mi");
					}
				}
				//Toybox.System.println(distHome.format("%.1f"));
				//Toybox.System.println(angleHome.format("%3.0f"));
				
			}
			
			var start_speed;
			
			if ( Toybox.Application has :Storage ) {
				start_speed = Properties.getValue("start_speed");
			} else {
				start_speed = Application.getApp().getProperty("start_speed");
			}
			
			if ((speed >= start_speed) and (recordingState == 0)) {
				startMoment = Time.now();
				startLocation = info.position;
				session.start();
				recordingState = 1;
				
				View.findDrawableById("lblDistHomeLbl").setText("home");
				View.findDrawableById("lblDistTrackLbl").setText("tot");
			}
			
			//Toybox.System.println(info.heading.toString());
    		WatchUi.requestUpdate();
    	} // if (info.accuracy == 4)
    }
    
    function oneSecondTimerCallback() {

    	var clockMode24h = System.getDeviceSettings().is24Hour;
    	var clock_type;
    	
    	if ( Toybox.Application has :Storage ) {
			clock_type = Properties.getValue("clock_type");
		} else {
			clock_type = Application.getApp().getProperty("clock_type");
		}
    	
    	if (clock_type == 1) { // 0 = use system setting. 1 = force 24h
    		clockMode24h = true;
    	} else if (clock_type == 2) { // 2 = force 12h
    		clockMode24h = false;
    	}
    	
    	var now = System.getClockTime();
    	var nowString;
    	if (clockMode24h) {
    		nowString = now.hour.format("%02d") + ":" + now.min.format("%02d") + ":" + now.sec.format("%02d");
    	} else {
    		var ampm = "am";
    		if (now.hour == 0) {
    			now.hour = 12;
			} else if (now.hour >= 12) {
				ampm = "pm";
				if (now.hour > 12) {
					now.hour = now.hour - 12;
				}
			}
			nowString = now.hour.format("%d") + ":" + now.min.format("%02d") + ":" + now.sec.format("%02d") + ampm;
    	}
    	View.findDrawableById("lblCurrentTime").setText(nowString);
    	
    	if (recordingState >= 1) {
    		var timerDuration = Time.now().subtract(startMoment);
    		var timerString = (timerDuration.value() / 3600).format("%01.0f") + ":" + (timerDuration.value() / 60).format("%02.0f");
    		View.findDrawableById("lblMissionTimer").setText(timerString);
    	}
    	
    	var positionInfo = Position.getInfo();
    	if (positionInfo.accuracy < 4) {
    		if (Attention has :playTone) {
			   Attention.playTone(Attention.TONE_ALERT_LO);
			}
			if (Attention has :vibrate) {
				var vibeData = [new Attention.VibeProfile(50, 1000)];
				Attention.vibrate(vibeData);
			}
    		pushView(new ppgInstrumentWaitingGPS(), new ppgInstrumentWaitingDelegate(), WatchUi.SLIDE_IMMEDIATE);
    	}
    	
    	WatchUi.requestUpdate();
    }
    
    function sensorCallback(info) {
    	var alt as float;
    	var units_altitude;
    	
    	if ( Toybox.Application has :Storage ) {
    		units_altitude = Properties.getValue("units_altitude");
		} else {
			units_altitude = Application.getApp().getProperty("units_altitude");
		}
    	
    	if (units_altitude == 0 ) { // m
    		alt = info.altitude;
    		// we ignore the case where altitude is greater than 10 km.
    		View.findDrawableById("lblAltMslLbl").setText("");
    		View.findDrawableById("lblAltMsl").setText((alt).format("%.0f"));
			View.findDrawableById("lblAltMsl").setFont(B612Bold_xl);
			if (alt < 1000.0f) {
				View.findDrawableById("lblAltMslLbl").setText("m");
			} else {
				View.findDrawableById("lblAltMslLbl").setText("");
			}
    	} else { // ==1 is ft
    		alt = Math.round(info.altitude * 3.28084f / 10.0f) * 10.0f; // convert m to ft
    		if (alt >= 10000.0f) {
				alt = alt / 1000.0f;
				View.findDrawableById("lblAltMslLbl").setText("k ft");
				View.findDrawableById("lblAltMsl").setText((alt).format("%2.2f"));
				View.findDrawableById("lblAltMsl").setFont(B612Bold_l);
				// lblAltMslLbl.setLocation(w*0.95,h*0.56); // forget why this was here.
			} else {
				if (alt < 1000.0f) {
					View.findDrawableById("lblAltMslLbl").setText("ft");
				} else {
					View.findDrawableById("lblAltMslLbl").setText("");
				}
				View.findDrawableById("lblAltMsl").setText((alt).format("%.0f"));
				View.findDrawableById("lblAltMsl").setFont(B612Bold_xl);
			}
    	}
		
		// update the array of last 5 altitudes, for vertical speed averaging.
		// standard boxcar filter.
    	altForVSpeed = altForVSpeed.slice(1,null);
    	altForVSpeed.add(info.altitude); // appended to end; latest data is always at the end.
    	
    	vSpeedVal = 0;
    	for (var i = 0; i < 4; i++) {
    		vSpeedVal += altForVSpeed[i+1] - altForVSpeed[i];
    	}
    	vSpeedVal = vSpeedVal / 4; // altitude is in m, so meters per second.
    	
    	
    		
    	if (vSpeedValValidCount < 1) {
    	
    		var units_vspeed;
    	
    		if ( Toybox.Application has :Storage ) {
	    		units_vspeed = Properties.getValue("units_vspeed");
			} else {
				units_vspeed = Application.getApp().getProperty("units_vspeed");
			}
    	
    		if (units_vspeed == 1 ) { // 0 == mps; 1 == fpm
    			vSpeedVal = vSpeedVal * 196.85f; // convert to feet per minute
	    		View.findDrawableById("lblVs").setText(vSpeedVal.format("%+3.0f"));
	    		View.findDrawableById("lblVsLbl").setText("fpm");
    		} else {
    			View.findDrawableById("lblVs").setText(vSpeedVal.format("%+.1f"));
    			View.findDrawableById("lblVsLbl").setText("m/s");
    		}
		} else {
			vSpeedValValidCount--;
		}
    
    	//Toybox.System.println((info.altitude * 3.28084f).toString() + " ft");
    	//Toybox.System.println((info.speed * 3.6f).toString() + " km/h");
    	WatchUi.requestUpdate();
    }
    
    
    /*****************************************************
                     UTILITY FUNCTIONS
               generateHomeTriangleCoordinates
                      distance_rad_m
                      bearing_rad_rad
    *****************************************************/
    
	function generateHomeTriangleCoordinates(centerPoint as Array<Number>, angle as Float, height as Number, width as Number, offset as Number) as Array< Array<Float> > {
		// generates the points for a triagle, pointing a certain angle, near the edge of the screen.
		 // note: zero angle is pointing DOWN.
		
        // Map out the coordinates of the triangle
        var coords = [[0, 0+offset] as Array<Number>,
                      [-(width / 2), -height+offset] as Array<Number>,
                      [(width / 2), -height+offset] as Array<Number>] as Array< Array<Number> >;
        var result = new Array< Array<Float> >[3];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 3; i++) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y] as Array<Float>;
        }

        return result;
    }
	
	function distance_rad_m(lat1, lon1, lat2, lon2) {
		// computes the distance (in meters) beteween two coordinates (in radians).
		var dy = (lat2-lat1);
		var dx = (lon2-lon1);
		
		var sy = Math.sin(dy / 2);
		sy *= sy;
		
		var sx = Math.sin(dx / 2);
		sx *= sx;
		
		var a = sy + Math.cos(lat1) * Math.cos(lat2) * sx;
		
		var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
		
		var R = 6371000; // radius of earth in meters
		return R * c;
	}
	
	function bearing_rad_rad(lat1, lon1, lat2, lon2) {
		// computes the angle (in radians) between two coordinates (in radians) with north reference,
		// starting from the second coordinate, pointing to the first.
		var y = Math.sin(lon1-lon2) * Math.cos(lat1);
		var x = Math.cos(lat2) * Math.sin(lat1) - Math.sin(lat2) * Math.cos(lat1) * Math.cos(lon1-lon2);
		var theta = Math.atan2(y, x);
		return theta;
		//return (theta * 180 / Math.PI + 360).toNumber() % 360; // in degrees
	}
}