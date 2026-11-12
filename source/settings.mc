import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Lang;

// App settings access.
//
// Watches on Connect IQ 2.4 and later use Application.Properties. Older watches do not
// have it and must use the deprecated AppBase.getProperty / setProperty.
// Only one pair of functions is compiled for each watch: monkey.jungle excludes
// (:legacySettings) by default and (:modernSettings) for the old watches listed there.

(:modernSettings)
function getSetting(key as String) {
	return Properties.getValue(key);
}

(:modernSettings)
function setSetting(key as String, value as Application.PropertyValueType) as Void {
	Properties.setValue(key, value);
}

(:legacySettings)
function getSetting(key as String) {
	return Application.getApp().getProperty(key);
}

(:legacySettings)
function setSetting(key as String, value as Application.PropertyValueType) as Void {
	Application.getApp().setProperty(key, value);
}
