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

class ppgInstrumentMain extends WatchUi.View {

	var B612Bold_75 as FontResource?;
	var B612Bold_65 as FontResource?;
	var B612Bold_40 as FontResource?;
	var B612Bold_25 as FontResource?;

	var lblVs;
	var lblVsLbl;
	var lblSpeed;
	var lblSpeedLblk;
	var lblSpeedLblm;
	var lblSpeedLblh;
	var lblHeading;
	var lblHeadingLbl;
	var lblAltMsl;
	var lblAltMslLbl;
	var lblCurrentTime;
	var lblMissionTimer;
	var lblDistHome;
	var lblDistHomeLbl;
	var lblDistTrack;
	var lblDistTrackLbl;
	
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
        
        settings = System.getDeviceSettings();
        w = settings.screenWidth;
        h = settings.screenHeight;

        B612Bold_75 = WatchUi.loadResource($.Rez.Fonts.B612Bold_75) as FontResource;
        B612Bold_65 = WatchUi.loadResource($.Rez.Fonts.B612Bold_65) as FontResource;
        B612Bold_40 = WatchUi.loadResource($.Rez.Fonts.B612Bold_40) as FontResource;
        B612Bold_25 = WatchUi.loadResource($.Rez.Fonts.B612Bold_25) as FontResource;
        
        lblVs = new WatchUi.Text({:text=>"-000", :font=>B612Bold_40, :color=>Graphics.COLOR_BLACK, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.36), :locY=>(h*0.25)});
        lblVsLbl = new WatchUi.Text({:text=>"fpm", :font=>Graphics.FONT_XTINY, :color=>Graphics.COLOR_DK_BLUE, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.36), :locY=>(h*0.15)});
        lblSpeed = new WatchUi.Text({:text=>"00", :font=>B612Bold_75, :color=>Graphics.COLOR_BLACK, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.3), :locY=>(h*0.38)});
        lblSpeedLblk = new WatchUi.Text({:text=>"k", :font=>Graphics.FONT_XTINY, :color=>Graphics.COLOR_DK_BLUE, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.36), :locY=>(h*0.38)});
        lblSpeedLblm = new WatchUi.Text({:text=>"m", :font=>Graphics.FONT_XTINY, :color=>Graphics.COLOR_DK_BLUE, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.36), :locY=>(h*0.47)});
        lblSpeedLblh = new WatchUi.Text({:text=>"h", :font=>Graphics.FONT_XTINY, :color=>Graphics.COLOR_DK_BLUE, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.36), :locY=>(h*0.56)});
        lblHeading = new WatchUi.Text({:text=>"000", :font=>B612Bold_40, :color=>Graphics.COLOR_BLACK, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.35), :locY=>(h*0.64)});
        lblHeadingLbl = new WatchUi.Text({:text=>"track", :font=>Graphics.FONT_XTINY, :color=>Graphics.COLOR_DK_BLUE, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.35), :locY=>(h*0.76)});
        lblAltMsl = new WatchUi.Text({:text=>"0000", :font=>B612Bold_75, :color=>Graphics.COLOR_BLACK, :justification=>Graphics.TEXT_JUSTIFY_LEFT, :locX=>(w*0.39), :locY=>(h*0.38)});
        lblAltMslLbl = new WatchUi.Text({:text=>"ft", :font=>Graphics.FONT_XTINY, :color=>Graphics.COLOR_DK_BLUE, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.95), :locY=>(h*0.56)});
        lblCurrentTime = new WatchUi.Text({:text=>"00:00:00", :font=>B612Bold_25, :color=>Graphics.COLOR_BLACK, :justification=>Graphics.TEXT_JUSTIFY_CENTER, :locX=>(w*0.5), :locY=>(h*0.87)});
        lblMissionTimer = new WatchUi.Text({:text=>"-:--", :font=>B612Bold_75, :color=>Graphics.COLOR_BLACK, :justification=>Graphics.TEXT_JUSTIFY_LEFT, :locX=>(w*0.39), :locY=>(h*0.12)});
        
        lblDistHome = new WatchUi.Text({:text=>"00.0", :font=>B612Bold_40, :color=>Graphics.COLOR_BLACK, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.70), :locY=>(h*0.64)});
        lblDistHomeLbl = new WatchUi.Text({:text=>"home", :font=>Graphics.FONT_XTINY, :color=>Graphics.COLOR_DK_BLUE, :justification=>Graphics.TEXT_JUSTIFY_LEFT, :locX=>(w*0.71), :locY=>(h*0.66)});
        lblDistTrack = new WatchUi.Text({:text=>"000", :font=>B612Bold_40, :color=>Graphics.COLOR_BLACK, :justification=>Graphics.TEXT_JUSTIFY_RIGHT, :locX=>(w*0.62), :locY=>(h*0.74)});
        lblDistTrackLbl = new WatchUi.Text({:text=>"tot km", :font=>Graphics.FONT_XTINY, :color=>Graphics.COLOR_DK_BLUE, :justification=>Graphics.TEXT_JUSTIFY_LEFT, :locX=>(w*0.63), :locY=>(h*0.76)});
        
        oneSecondTimer = new Timer.Timer();
        
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:gpsUpdatedCallback));
        
        Sensor.setEnabledSensors([] as Array<SensorType>);
        Sensor.enableSensorEvents(method(:sensorCallback));
        
        for (var i = 0; i < 5; i++) {
        	altForVSpeed[i] = 0;
        }
    }

    function onLayout(dc) {
        pushView(new ppgInstrumentWaitingGPS(), new ppgInstrumentWaitingDelegate(), WatchUi.SLIDE_IMMEDIATE);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
    }
    
    function onShow() {
    	oneSecondTimer.start(method(:oneSecondTimerCallback), 1000, true);
    }
    
    function onUpdate(dc) {    	
    	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, h*0.39, w, h*0.39); // horiz upper line
        dc.drawLine(0, h*0.66, w, h*0.66); // horiz lower line
        dc.drawLine(w*0.37, h*0.15, w*0.37, h*0.88); // vertical line
        dc.drawLine(0, h*0.88, w, h*0.88); // horiz lowest line
        
        if (recordingState >= 1) {
	        var screenCenterPoint = [w/2, h/2] as Array<Number>;
	    	dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
	    	dc.fillPolygon(generateHomeTriangleCoordinates(screenCenterPoint, homeAngleRad - Math.PI, 30, 50, w/2)); // centerpoint, angleRad, height, width, offset
	    	
	    	lblDistHome.draw(dc);
			lblDistHomeLbl.draw(dc);
	    	lblDistTrack.draw(dc);
			lblDistTrackLbl.draw(dc);
    	}
        
        lblVs.draw(dc);
        lblVsLbl.draw(dc);
        lblSpeed.draw(dc);
        lblSpeedLblk.draw(dc);
        lblSpeedLblm.draw(dc);
        lblSpeedLblh.draw(dc);
        lblHeading.draw(dc);
        lblHeadingLbl.draw(dc);
        lblAltMsl.draw(dc);
        lblAltMslLbl.draw(dc);
        lblCurrentTime.draw(dc);
        lblMissionTimer.draw(dc);
    }
    
    function onHide() {
    	oneSecondTimer.stop();
    }
    
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
    			lblSpeedLblk.setText("k");
    			lblSpeedLblm.setText("m");
    		} else { // ==1 is mph
    			speed = info.speed * 2.23694f; // convert m/s to mph
    			lblSpeedLblk.setText("m");
    			lblSpeedLblm.setText("p");
    		}
    		
    		lblSpeed.setText(speed.format("%2.0f"));
			lblHeading.setText(headingDeg.format("%3.0f")); // source in true degrees
			
			if (recordingState >= 1) {
				var distHome;
				var startLocationRads = startLocation.toRadians();
				var thisLocationRads = info.position.toRadians();
				distHome = distance_rad_m(startLocationRads[0], startLocationRads[1], thisLocationRads[0], thisLocationRads[1]) ;
				homeAngleRad = bearing_rad_rad(startLocationRads[0], startLocationRads[1], thisLocationRads[0], thisLocationRads[1]) - info.heading;
				
				var actInfo = Activity.getActivityInfo();
				
				if (actInfo.elapsedDistance != null) { // TODO: fix this workaround. seems to only occur with the simulator.
				
				var units_distance;
				
				if ( Toybox.Application has :Storage ) {
					units_distance = Properties.getValue("units_distance");
				} else {
					units_distance = Application.getApp().getProperty("units_distance");
				}
				
					if (units_distance == 0) { // 0 == km
						lblDistHome.setText((Math.floor(distHome / 100.0f)/10).format("%2.1f"));
						lblDistTrack.setText(Math.floor(actInfo.elapsedDistance / 1000f).format("%3.0f"));
						lblDistTrackLbl.setText("tot km");
					} else { // 1 == mi
						lblDistHome.setText((Math.floor(distHome / 160.934f)/10).format("%2.1f"));
						lblDistTrack.setText(Math.floor(actInfo.elapsedDistance / 1609.34f).format("%3.0f"));
						lblDistTrackLbl.setText("tot mi");
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
			}
			
			//Toybox.System.println(info.heading.toString());
    		WatchUi.requestUpdate();
    	}
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
    	lblCurrentTime.setText(nowString);
    	
    	if (recordingState >= 1) {
    		var timerDuration = Time.now().subtract(startMoment);
    		var timerString = (timerDuration.value() / 3600).format("%01.0f") + ":" + (timerDuration.value() / 60).format("%02.0f");
    		lblMissionTimer.setText(timerString);
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
    		lblAltMslLbl.setText("");
    		lblAltMsl.setText((alt).format("%.0f"));
			lblAltMsl.setFont(B612Bold_75);
			if (alt < 1000.0f) {
				lblAltMslLbl.setText("m");
			} else {
				lblAltMslLbl.setText("");
			}
    	} else { // ==1 is ft
    		alt = Math.round(info.altitude * 3.28084f / 10.0f) * 10.0f; // convert m to ft
    		if (alt >= 10000.0f) {
				alt = alt / 1000.0f;
				lblAltMslLbl.setText("k ft");
				lblAltMsl.setText((alt).format("%2.2f"));
				lblAltMsl.setFont(B612Bold_65);
				lblAltMslLbl.setLocation(w*0.95,h*0.56);
			} else {
				if (alt < 1000.0f) {
					lblAltMslLbl.setText("ft");
				} else {
					lblAltMslLbl.setText("");
				}
				lblAltMsl.setText((alt).format("%.0f"));
				lblAltMsl.setFont(B612Bold_75);
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
	    		lblVs.setText(vSpeedVal.format("%+3.0f"));
	    		lblVsLbl.setText("fpm");
    		} else {
    			lblVs.setText(vSpeedVal.format("%+.1f"));
    			lblVsLbl.setText("m/s");
    		}
		} else {
			vSpeedValValidCount--;
		}
    
    	//Toybox.System.println((info.altitude * 3.28084f).toString() + " ft");
    	//Toybox.System.println((info.speed * 3.6f).toString() + " km/h");
    	WatchUi.requestUpdate();
    }
    
    // note: zero angle is pointing DOWN.
	function generateHomeTriangleCoordinates(centerPoint as Array<Number>, angle as Float, height as Number, width as Number, offset as Number) as Array< Array<Float> > {
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
	
	// 1 = start location, 2 = this location
	// bearing points from this to start
	function bearing_rad_rad(lat1, lon1, lat2, lon2) {
		var y = Math.sin(lon1-lon2) * Math.cos(lat1);
		var x = Math.cos(lat2) * Math.sin(lat1) - Math.sin(lat2) * Math.cos(lat1) * Math.cos(lon1-lon2);
		var theta = Math.atan2(y, x);
		return theta;
		//return (theta * 180 / Math.PI + 360).toNumber() % 360; // in degrees
	}
}