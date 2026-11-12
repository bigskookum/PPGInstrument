import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Timer;
import Toybox.System;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.Time;
import Toybox.Sensor;
import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.Lang;

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
	
	var altForVSpeed as Array<Float> = [0.0f, 0.0f, 0.0f, 0.0f, 0.0f] as Array<Float>;
	var vSpeedVal as Float = 0.0f;
	var vSpeedValValidCount = 5;
	var homeAngleRad = 0;
	
	var settings;
    var w;
    var h;
	
	var recordingState = 0;
	var startMoment as Moment?;
	var startLocation as Location?;
	
	var oneSecondTimer;

	// Altitude drift correction. Barometric altitude drifts as the weather changes during
	// a flight. GPS altitude does not drift, but it is noisy, slow, and offset from sea level
	// by a fixed amount. So GPS is only used to measure how the gap between the two changes
	// over time; that change is the drift, and it is subtracted from the barometric altitude.
	const ALT_BASELINE_SAMPLES = 60;   // seconds of level data averaged to get the starting gap.
	const ALT_DRIFT_TAU = 300.0f;      // smoothing time constant, in seconds.
	const ALT_LEVEL_VSPEED = 0.5f;     // m/s. GPS altitude lags, so only compare when roughly level.
	var gpsAltitude as Float?;         // latest GPS altitude; null when there is no good fix.
	var altGapSum as Float = 0.0f;
	var altGapCount as Number = 0;
	var altGapStart as Float?;         // baro minus GPS at the start; null until the baseline is done.
	var altGapFiltered as Float = 0.0f;
	var altCorrection as Float = 0.0f; // metres of drift, subtracted from the displayed altitude.

    function initialize() {
        View.initialize();
        
        B612Bold_xl = WatchUi.loadResource($.Rez.Fonts.B612Bold_xl) as FontResource;
        B612Bold_l = WatchUi.loadResource($.Rez.Fonts.B612Bold_l) as FontResource;
        B612Bold_m = WatchUi.loadResource($.Rez.Fonts.B612Bold_m) as FontResource;
        B612Bold_s = WatchUi.loadResource($.Rez.Fonts.B612Bold_s) as FontResource;
        
        settings = System.getDeviceSettings();
        w = settings.screenWidth;
        h = settings.screenHeight;
    }

    // Layout labels are all WatchUi.Text; findDrawableById only promises a Drawable.
    function label(id as String) as Text {
        return View.findDrawableById(id) as Text;
    }

    function onLayout(dc) {
    	setLayout($.Rez.Layouts.mainLayout(dc));
    	
    	Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:gpsUpdatedCallback));
        
        Sensor.setEnabledSensors([] as Array<SensorType>);
        Sensor.enableSensorEvents(method(:sensorCallback));
        
        oneSecondTimer = new Timer.Timer();
    	
    	label("lblVs").setFont(B612Bold_m);
    	label("lblSpeed").setFont(B612Bold_xl);
    	label("lblHeading").setFont(B612Bold_m);
    	label("lblAltMsl").setFont(B612Bold_xl);
    	label("lblCurrentTime").setFont(B612Bold_s);
    	label("lblMissionTimer").setFont(B612Bold_xl);
    	label("lblDistHome").setFont(B612Bold_m);
    	label("lblDistTrack").setFont(B612Bold_m);
    
    	// on startup, go immediately to GPS wait screen.
        pushView(new ppgInstrumentWaitingGPS(), new ppgInstrumentMainDelegate(), WatchUi.SLIDE_IMMEDIATE);
        
    }
    
    function onShow() {
    	oneSecondTimer.start(method(:oneSecondTimerCallback), 1000, true);
    }
    
    function onUpdate(dc) {

        if (recordingState < 1) {
        	// blank out data.
        	label("lblDistHome").setText("");
        	label("lblDistHomeLbl").setText("");
        	label("lblDistTrack").setText("");
        	label("lblDistTrackLbl").setText("");
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
    
    function gpsUpdatedCallback(info as Position.Info) as Void {
    	var speed;
    	var heading = info.heading;
    	var gpsSpeed = info.speed;
    	var position = info.position;
    	
    	gpsAltitude = (info.accuracy == 4) ? info.altitude : null;
    	
    	if (info.accuracy == 4 && heading != null && gpsSpeed != null && position != null) {
    		var headingDeg = Math.toDegrees(heading);
    		if (headingDeg < 0) {
    			headingDeg += 360;
    		}
    		
    		var units_speed;
    		
    		units_speed = getSetting("units_speed");
    		
    		if (units_speed == 0 ) { // km/h
    			speed = gpsSpeed * 3.6f; // convert m/s to km/h
    			label("lblSpeedLblk").setText("k");
    			label("lblSpeedLblm").setText("m");
    		} else { // ==1 is mph
    			speed = gpsSpeed * 2.23694f; // convert m/s to mph
    			label("lblSpeedLblk").setText("m");
    			label("lblSpeedLblm").setText("p");
    		}
    		
    		label("lblSpeed").setText(speed.format("%2.0f"));
			label("lblHeading").setText(headingDeg.format("%3.0f")); // source in true degrees
			
			var home = startLocation;
			if (recordingState >= 1 && home != null) {
				var distHome;
				var startLocationRads = home.toRadians();
				var thisLocationRads = position.toRadians();
				distHome = distance_rad_m(startLocationRads[0], startLocationRads[1], thisLocationRads[0], thisLocationRads[1]) ;
				homeAngleRad = bearing_rad_rad(startLocationRads[0], startLocationRads[1], thisLocationRads[0], thisLocationRads[1]) - heading;
				
		    	// the arrow tip sits on the edge of the screen, whatever its shape.
		    	var screenCenterPoint = [w/2, h/2] as Array<Number>;
		    	var arrowAngle = homeAngleRad - Math.PI;
		    	// arrow size scales with the screen: 30 x 50 pixels on a 240 pixel screen.
		    	var minDim = (w < h) ? w : h;
				homeTrianglePoints = generateHomeTriangleCoordinates(screenCenterPoint, arrowAngle, minDim / 8, minDim * 5 / 24, distanceToScreenEdge(arrowAngle));
				
				var actInfo = Activity.getActivityInfo();
				
				var elapsedDistance = (actInfo != null) ? actInfo.elapsedDistance : null;
				if (elapsedDistance != null) { // can be null before the activity has distance (seen in the simulator).
				
				var units_distance;
				
				units_distance = getSetting("units_distance");
				
					if (units_distance == 0) { // 0 == km
						label("lblDistHome").setText((Math.floor(distHome / 100.0f)/10).format("%2.1f"));
						label("lblDistTrack").setText(Math.floor(elapsedDistance / 1000f).format("%3.0f"));
						label("lblDistTrackLbl").setText("tot km");
					} else { // 1 == mi
						label("lblDistHome").setText((Math.floor(distHome / 160.934f)/10).format("%2.1f"));
						label("lblDistTrack").setText(Math.floor(elapsedDistance / 1609.34f).format("%3.0f"));
						label("lblDistTrackLbl").setText("tot mi");
					}
				}
				//Toybox.System.println(distHome.format("%.1f"));
				//Toybox.System.println(angleHome.format("%3.0f"));
				
			}
			
			var start_speed;
			
			start_speed = getSetting("start_speed");
			
			if ((speed >= (start_speed as Number)) and (recordingState == 0)) {
				startMoment = Time.now();
				startLocation = position;
				var s = session;
				if (s != null) {
					s.start();
				}
				recordingState = 1;
				
				label("lblDistHomeLbl").setText("home");
				label("lblDistTrackLbl").setText("tot");
			}
			
			//Toybox.System.println(info.heading.toString());
    		WatchUi.requestUpdate();
    	} // if (info.accuracy == 4)
    }
    
    function oneSecondTimerCallback() as Void {

    	var clockMode24h = System.getDeviceSettings().is24Hour;
    	var clock_type;
    	
    	clock_type = getSetting("clock_type");
    	
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
    	label("lblCurrentTime").setText(nowString);
    	
    	var start = startMoment;
    	if (recordingState >= 1 && start != null) {
    		var timerDuration = Time.now().subtract(start) as Time.Duration;
    		var elapsedSeconds = timerDuration.value();
    		// h:mm, with minutes wrapping at the hour.
    		var timerString = (elapsedSeconds / 3600).format("%d") + ":" + ((elapsedSeconds % 3600) / 60).format("%02d");
    		label("lblMissionTimer").setText(timerString);
    	}
    	
    	var positionInfo = Position.getInfo();
    	if (positionInfo.accuracy < 4) {
    		gpsAltitude = null; // do not correct altitude against a poor fix.
    		if (Attention has :playTone) {
			   Attention.playTone(Attention.TONE_ALERT_LO);
			}
			if (Attention has :vibrate) {
				var vibeData = [new Attention.VibeProfile(50, 1000)];
				Attention.vibrate(vibeData);
			}
    		pushView(new ppgInstrumentWaitingGPS(), new ppgInstrumentMainDelegate(), WatchUi.SLIDE_IMMEDIATE);
    	}
    	
    	WatchUi.requestUpdate();
    }
    
    function sensorCallback(info as Sensor.Info) as Void {
    	var alt;
    	var altitude = info.altitude;
    	var units_altitude;
    	
    	if (altitude == null) {
    		return; // no altitude source yet (e.g. barometer not ready).
    	}
    	
    	var alt_correction;
    	alt_correction = getSetting("alt_correction");
		// displayed altitude; vertical speed below keeps using the raw barometric value.
    	var shownAltitude = (alt_correction == false) ? altitude : altitude - altCorrection;
    	
    	units_altitude = getSetting("units_altitude");
    	
    	if (units_altitude == 0 ) { // m
    		alt = shownAltitude;
    		// we ignore the case where altitude is greater than 10 km.
    		label("lblAltMslLbl").setText("");
    		label("lblAltMsl").setText((alt).format("%.0f"));
			label("lblAltMsl").setFont(B612Bold_xl);
			if (alt < 1000.0f) {
				label("lblAltMslLbl").setText("m");
			} else {
				label("lblAltMslLbl").setText("");
			}
    	} else { // ==1 is ft
    		alt = Math.round(shownAltitude * 3.28084f / 10.0f) * 10.0f; // convert m to ft
    		if (alt >= 10000.0f) {
				alt = alt / 1000.0f;
				label("lblAltMslLbl").setText("k ft");
				label("lblAltMsl").setText((alt).format("%2.2f"));
				label("lblAltMsl").setFont(B612Bold_l);
				// lblAltMslLbl.setLocation(w*0.95,h*0.56); // forget why this was here.
			} else {
				if (alt < 1000.0f) {
					label("lblAltMslLbl").setText("ft");
				} else {
					label("lblAltMslLbl").setText("");
				}
				label("lblAltMsl").setText((alt).format("%.0f"));
				label("lblAltMsl").setFont(B612Bold_xl);
			}
    	}
		
		// update the array of last 5 altitudes, for vertical speed averaging.
		// standard boxcar filter.
    	altForVSpeed = altForVSpeed.slice(1,null);
    	altForVSpeed.add(altitude); // appended to end; latest data is always at the end.
    	
    	vSpeedVal = 0.0f;
    	for (var i = 0; i < 4; i++) {
    		vSpeedVal += altForVSpeed[i+1] - altForVSpeed[i];
    	}
    	vSpeedVal = vSpeedVal / 4; // altitude is in m, so meters per second.
    	
    	updateAltCorrection(altitude);
    	
    	
    		
    	if (vSpeedValValidCount < 1) {
    	
    		var units_vspeed;
    	
    		units_vspeed = getSetting("units_vspeed");
    	
    		if (units_vspeed == 1 ) { // 0 == mps; 1 == fpm
    			vSpeedVal = vSpeedVal * 196.85f; // convert to feet per minute
	    		label("lblVs").setText(vSpeedVal.format("%+3.0f"));
	    		label("lblVsLbl").setText("fpm");
    		} else {
    			label("lblVs").setText(vSpeedVal.format("%+.1f"));
    			label("lblVsLbl").setText("m/s");
    		}
		} else {
			vSpeedValValidCount--;
		}
    
    	//Toybox.System.println((info.altitude * 3.28084f).toString() + " ft");
    	//Toybox.System.println((info.speed * 3.6f).toString() + " km/h");
    	WatchUi.requestUpdate();
    }
    
    
    // Called once per second with the raw barometric altitude.
    function updateAltCorrection(baroAltitude as Float) as Void {
    	var gps = gpsAltitude;
    	if (gps == null || vSpeedVal.abs() > ALT_LEVEL_VSPEED) {
    		return;
    	}
    	
    	var gap = baroAltitude - gps;
    	var start = altGapStart;
    	if (start == null) {
    		// still averaging the starting gap; no correction yet.
    		altGapSum += gap;
    		altGapCount++;
    		if (altGapCount >= ALT_BASELINE_SAMPLES) {
    			altGapFiltered = altGapSum / altGapCount;
    			altGapStart = altGapFiltered;
    		}
    	} else {
    		altGapFiltered += (gap - altGapFiltered) / ALT_DRIFT_TAU;
    		altCorrection = altGapFiltered - start;
    	}
    }
    
    
    /*****************************************************
                     UTILITY FUNCTIONS
                    distanceToScreenEdge
               generateHomeTriangleCoordinates
                      distance_rad_m
                      bearing_rad_rad
    *****************************************************/
    
	// Distance in pixels from the screen centre to the screen edge, in the direction the
	// home arrow points for the given angle (zero is straight down, as in
	// generateHomeTriangleCoordinates).
	function distanceToScreenEdge(angle) {
		var halfW = w / 2.0f;
		var halfH = h / 2.0f;
		var shape = settings.screenShape;
		
		if (shape == System.SCREEN_SHAPE_ROUND) {
			return (halfW < halfH) ? halfW : halfH;
		}
		
		var sin = Math.sin(angle);
		var cos = Math.cos(angle);
		if (sin < 0) { sin = -sin; }
		if (cos < 0) { cos = -cos; }
		
		// how far until the top or bottom edge is reached, and how far until a side is reached.
		var toTopOrBottom = (cos > 0.001f) ? halfH / cos : 100000.0f;
		var toSide = (sin > 0.001f) ? halfW / sin : 100000.0f;
		
		if (shape == System.SCREEN_SHAPE_SEMI_ROUND) {
			// a circle with the top and bottom cut off flat.
			toSide = halfW;
		}
		return (toSide < toTopOrBottom) ? toSide : toTopOrBottom;
	}
	
	function generateHomeTriangleCoordinates(centerPoint as Array<Number>, angle as Float, height as Number, width as Number, offset as Numeric) as Array< Array<Float> > {
		// generates the points for a triagle, pointing a certain angle, near the edge of the screen.
		 // note: zero angle is pointing DOWN.
		
        // Map out the coordinates of the triangle
        var coords = [[0, 0+offset] as Array<Numeric>,
                      [-(width / 2), -height+offset] as Array<Numeric>,
                      [(width / 2), -height+offset] as Array<Numeric>] as Array< Array<Numeric> >;
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