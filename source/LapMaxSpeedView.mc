import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class LapMaxSpeedView extends WatchUi.DataField {

    hidden var appVersion = "1.1";
    hidden var label;
    hidden var _M_previous;
    hidden var _M_elapsed;
    hidden var _M_paused;
    hidden var _M_stopped; 
    hidden var _lap_max_speed;
    hidden var _lastlap_max_speed;
    hidden var _current_lap = 0;
    const MAX_SPEED_CHECK = 2000;
    const DEFAULT_AVG_PERIOD = 10;
    const TEST_LAYOUT = false;
    const XSHIM = 32;
    const XSHIM_OBSCURE = 25;
    const YSHIM_MAX = 13;
    const YSHIM_MAXAVG = 10;

    class AveragingBoundedArray {
        hidden var _size as Number;
        hidden var _array;
        hidden var _current_index as Number;
        hidden var _initialized_size as Number;
        
        function initialize(size as Lang.Number) {
            _size = size;
            _array = new[size];
            _current_index = 0;
            _initialized_size = 0;
        }
        
        function clear() {
            for (var i = 0; i < _size; i++) {
                _array[i] = null;
            }
            _initialized_size = 0;
            _current_index = 0;
        }

        function store(e) {
            _array[_current_index] = e;
            if (_initialized_size < _size) {
                _initialized_size = _current_index + 1;
            }
            _current_index = (_current_index >= (_size - 1)) ? 0 : _current_index + 1;
        }

        function getSize() as Number {
            return _size;
        }

        // returns average once the array is fully initialized, otherwise returns null
        function getAverage() as Float or Null {
            if (_initialized_size == _size) {
                var sum = 0;
                for(var i = 0; i < _size; i++) {
                    sum += _array[i];
                }
                return sum/_initialized_size;
            }
            else {
                return null;
            }
        }
    }

    hidden var _lap_speed_array;
    hidden var _lap_maxfloatavg_speed;
    hidden var _lastlap_maxfloatavg_speed;

    function setAppLabel() {
        if (appVersion != null && appVersion != "") {
            label = "Lap max speed v" + appVersion;
        }
        else {
            label = "Lap max speed";
        }
    }

    function getPropertyValue(name as String) as String or Null {
        try {
            if (Application has :Properties) {
                return Application.Properties.getValue(name);
            }
            else if (Application has :getApp) {
                return Application.getApp().getProperty(name);
            }
        }
        catch (ex) {}
        return null;
    }

    // Set the label of the data field here.
    function initialize() {
        DataField.initialize();
        setAppLabel();
        _M_paused = false;
        _M_stopped = true; 

        var lap_speed_array_size = getPropertyValue("avgPeriod");
        if (lap_speed_array_size != null && lap_speed_array_size > 0) {
            _lap_speed_array = new AveragingBoundedArray(lap_speed_array_size);
        }
        else {
            _lap_speed_array = new AveragingBoundedArray(DEFAULT_AVG_PERIOD);
        }
    }

    function onSettingsChanged() {
        var new_size = Application.Properties.getValue("avgPeriod");
        if (new_size != null && new_size > 0 && new_size != _lap_speed_array.getSize()) {
            System.println("Reinitializing _lap_speed_array from " + _lap_speed_array.getSize() + " to " + new_size);
            _lap_speed_array = new AveragingBoundedArray(new_size);
        }
        setAppLabel();
    }

/*
    function onStart(state) {
        DataField.onStart(state);
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }
    */

    function onTimerPause() {
        System.println("Pause");
        _M_paused = true;
    }

    function onTimerResume() {
        System.println("Resume");
        _M_paused = false;
        _M_previous = System.getTimer();
    }

    function onTimerStart() {
        System.println("Start");
        _M_stopped = false;
        _M_previous = System.getTimer();
        _M_elapsed = 0;
    }

    function onTimerStop() {
        System.println("Stop");
        _M_stopped = true;
    }

    function onTimerLap() {
        System.println("Lap");
        _M_previous = System.getTimer();
        _M_elapsed = 0;
        _current_lap++;
        _lastlap_max_speed = _lap_max_speed;
        _lastlap_maxfloatavg_speed = _lap_maxfloatavg_speed;
        _lap_max_speed = null;
        _lap_maxfloatavg_speed = null;
        _lap_speed_array.clear();
    }

    function onTimerReset() {
        System.println("Reset");
        _M_elapsed = null;
    } 

    function speedToKmh(s as Lang.Float or Null) {
        if (s == null) {
            return "-";
        }
        return (s * 3.6).format("%0.1f");
    }

   // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        labelView.locY = labelView.locY - 22;
        var valueView = View.findDrawableById("value");
        valueView.locY = valueView.locY - YSHIM_MAX;
        valueView = View.findDrawableById("value_cur_max");
        valueView.locX = valueView.locX - XSHIM;
        valueView.locY = valueView.locY - YSHIM_MAX;
        valueView = View.findDrawableById("value_cur_maxavg");
        valueView.locX = valueView.locX - XSHIM;
        valueView.locY = valueView.locY + YSHIM_MAXAVG;
        valueView = View.findDrawableById("value_last_max");
        valueView.locX = valueView.locX + XSHIM;
        valueView.locY = valueView.locY - YSHIM_MAX;
        valueView = View.findDrawableById("value_last_maxavg");
        valueView.locX = valueView.locX + XSHIM;
        valueView.locY = valueView.locY + YSHIM_MAXAVG;
        valueView = View.findDrawableById("value_avgwindow");
        valueView.locY = valueView.locY + YSHIM_MAXAVG;

/*
        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            valueView = View.findDrawableById("value_cur_max");
            valueView.locX = valueView.locX + XSHIM_OBSCURE;
            valueView = View.findDrawableById("value_cur_maxavg");
            valueView.locX = valueView.locX + XSHIM_OBSCURE;
            valueView = View.findDrawableById("value_last_max");
            valueView.setFont(Graphics.FONT_SYSTEM_XTINY);
            valueView = View.findDrawableById("value_last_maxavg");
            valueView.setFont(Graphics.FONT_SYSTEM_XTINY);
        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {

        }
        */

        //(View.findDrawableById("label") as Text).setText(label);
    }

    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var labelView = View.findDrawableById("label") as Text;
        var value = View.findDrawableById("value") as Text;
        var value_cur_max = View.findDrawableById("value_cur_max") as Text;
        var value_cur_maxavg = View.findDrawableById("value_cur_maxavg") as Text;
        var value_last_max = View.findDrawableById("value_last_max") as Text;
        var value_last_maxavg = View.findDrawableById("value_last_maxavg") as Text;
        var value_avgwindow = View.findDrawableById("value_avgwindow") as Text;

        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
            value_cur_max.setColor(Graphics.COLOR_WHITE);
            value_cur_maxavg.setColor(Graphics.COLOR_WHITE);
            value_last_max.setColor(Graphics.COLOR_LT_GRAY);
            value_last_maxavg.setColor(Graphics.COLOR_LT_GRAY);
            value_avgwindow.setColor(Graphics.COLOR_DK_GRAY);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
            value_cur_max.setColor(Graphics.COLOR_BLACK);
            value_cur_maxavg.setColor(Graphics.COLOR_BLACK);
            value_last_max.setColor(Graphics.COLOR_DK_GRAY);
            value_last_maxavg.setColor(Graphics.COLOR_DK_GRAY);
            value_avgwindow.setColor(Graphics.COLOR_LT_GRAY);
        }

        if (TEST_LAYOUT) {
            value.setText("");
            value_cur_max.setText("999.9");
            value_cur_maxavg.setText("999.8");
            value_last_max.setText("998.8");
            value_last_maxavg.setText("988.8");
            value_avgwindow.setText("120s");
        }
        else {
            if (_M_paused || _M_stopped) {
                if (_lap_max_speed == null && _lastlap_max_speed == null) {
                    value_cur_max.setText("");
                    value_cur_maxavg.setText("");
                    value_last_max.setText("");
                    value_last_maxavg.setText("");
                    value_avgwindow.setText("");
                    labelView.setText(label);
                    value.setText("ready to start");
                }
                else if (_lap_max_speed == null && _lastlap_max_speed != null) {
                    labelView.setText("");
                    value.setText("");
                    value_avgwindow.setText("");
                    value_cur_max.setText("");
                    value_cur_maxavg.setText("stopped");
                    value_last_max.setText(speedToKmh(_lastlap_max_speed));
                    value_last_maxavg.setText(speedToKmh(_lastlap_maxfloatavg_speed));
                }
                else {
                    labelView.setText("");
                    value.setText("");
                    value_avgwindow.setText("");
                    value_cur_max.setText(speedToKmh(_lap_max_speed));
                    value_cur_maxavg.setText(speedToKmh(_lap_maxfloatavg_speed));
                    value_last_max.setText("");
                    value_last_maxavg.setText("stopped");
                }
            }
            else {
                    labelView.setText("");
                    value.setText("");
                    value_avgwindow.setText(_lap_speed_array.getSize().format("%3d")+"s");
                    value_cur_max.setText(speedToKmh(_lap_max_speed));
                    value_cur_maxavg.setText(speedToKmh(_lap_maxfloatavg_speed));
                    value_last_max.setText(speedToKmh(_lastlap_max_speed));
                    value_last_maxavg.setText(speedToKmh(_lastlap_maxfloatavg_speed));
            }
        }

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        if (!_M_paused && !_M_stopped) {
            var s = info.currentSpeed;
            System.println(speedToKmh(s));

            if (s < MAX_SPEED_CHECK) {
                // this is basic sanity check - the sometimes this can generate non-sense values like 4763019.5
                if (_lap_max_speed == null || _lap_max_speed < s) {
                    _lap_max_speed = s;
                }
            }

            var current = System.getTimer();
            if (_M_previous != null && _M_elapsed != null && current != null) {
                _M_elapsed += (current - _M_previous);
                _M_previous = current;
                if (s < MAX_SPEED_CHECK) {
                    _lap_speed_array.store(s);
                }
            }

            var lastRunningAvg = _lap_speed_array.getAverage();
            if (lastRunningAvg != null) {
                if (_lap_maxfloatavg_speed == null || lastRunningAvg > _lap_maxfloatavg_speed) {
                    _lap_maxfloatavg_speed = lastRunningAvg;
                }
            }
        }
    }

}