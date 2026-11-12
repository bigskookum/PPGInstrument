import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.Activity;
import Toybox.Lang;

// Throwaway test app: shows the three altitude values Connect IQ offers, side by side,
// to find out whether Position.Info.altitude is real GPS altitude on a barometer watch.

class AltTestApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new AltTestView() ];
    }
}

class AltTestView extends WatchUi.View {

    var posAlt as Float?;
    var posQuality as Number = 0;
    var sensAlt as Float?;
    var maxDiff as Float = 0.0f;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        Sensor.setEnabledSensors([] as Array<Sensor.SensorType>);
        Sensor.enableSensorEvents(method(:onSensor));
    }

    function onHide() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        Sensor.enableSensorEvents(null);
    }

    function onPosition(info as Position.Info) as Void {
        posAlt = info.altitude;
        posQuality = info.accuracy as Number;
        WatchUi.requestUpdate();
    }

    function onSensor(info as Sensor.Info) as Void {
        sensAlt = info.altitude;
        WatchUi.requestUpdate();
    }

    function fmt(v as Float?) as String {
        if (v == null) {
            return "--";
        }
        return v.format("%.1f") + " m";
    }

    function onUpdate(dc as Dc) as Void {
        var actAlt = null;
        var pressure = null;
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null) {
            actAlt = actInfo.altitude;
            if (actInfo has :ambientPressure) {
                pressure = actInfo.ambientPressure;
            }
        }

        var p = posAlt;
        var s = sensAlt;
        var diffText = "--";
        if (p != null && s != null) {
            var diff = p - s;
            if (diff.abs() > maxDiff) {
                maxDiff = diff.abs();
            }
            diffText = diff.format("%+.1f") + " m";
        }

        var lines = [
            "GPS fix " + posQuality + "/4",
            "Position: " + fmt(p),
            "Sensor: " + fmt(s),
            "Activity: " + fmt(actAlt),
            "Pos - Sens: " + diffText,
            "max: " + maxDiff.format("%.1f") + " m",
            (pressure != null) ? (pressure / 100.0f).format("%.1f") + " hPa" : "pressure --"
        ] as Array<String>;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var font = Graphics.FONT_SMALL;
        var lineH = dc.getFontHeight(font);
        var y = (dc.getHeight() - lineH * lines.size()) / 2;
        for (var i = 0; i < lines.size(); i++) {
            // highlight the two values being compared.
            dc.setColor((i == 1 || i == 2) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, y + i * lineH, font, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
