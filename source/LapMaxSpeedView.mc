import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class LapMaxSpeedView extends WatchUi.DataField {

    hidden var appVersion = "1.2";
    hidden var label;
    hidden var _M_previous;
    hidden var _M_elapsed;
    hidden var _M_paused;
    hidden var _M_stopped; 
    hidden var _lap_max_speed;
    hidden var _lastlap_max_speed;
    hidden var _current_lap = 0;
    hidden var MAX_SPEED_CHECK as Number = 2000;
    hidden var DEFAULT_AVG_PERIOD as Number = 120;
    hidden var TEST_LAYOUT = false;
    hidden var YSHIM_MAX as Number = 13;
    hidden var YSHIM_MAXAVG as Number = 10;

    class AveragingBoundedArray {
        hidden var _size as Number;
        hidden var _array as Array<Float>;
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

    hidden var obscurityFlags;
    hidden var optimumMainTextDimensions;
    hidden var mainTextComponentDimensions;
    hidden var optimumSubTextDimensions;
    hidden var subTextComponentDimensions;
    hidden var dynMainXShim;
    hidden var dynSubXShim;
    hidden var showLastLap = true;
    hidden var showAvgWindow = true;

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
        label = "Lap max speed" + (appVersion != null && appVersion != "") ? " v" + appVersion : "";
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

    // This does not work properly during the training anyway, disabling
    /*
    function onSettingsChanged() {
        var new_size = getPropertyValue("avgPeriod");
        if (new_size != null && new_size > 0 && new_size != _lap_speed_array.getSize()) {
            System.println("Reinitializing _lap_speed_array from " + _lap_speed_array.getSize() + " to " + new_size);
            _lap_speed_array = new AveragingBoundedArray(new_size);
        }
        setAppLabel();
    }
    */

/*
    function onStart(state) {
        DataField.onStart(state);
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }
    */

    function onTimerPause() {
        //System.println("Pause");
        _M_paused = true;
    }

    function onTimerResume() {
        //System.println("Resume");
        _M_paused = false;
        _M_previous = System.getTimer();
    }

    function onTimerStart() {
        //System.println("Start");
        _M_stopped = false;
        _M_previous = System.getTimer();
        _M_elapsed = 0;
    }

    function onTimerStop() {
        //System.println("Stop");
        _M_stopped = true;
    }

    function onTimerLap() {
        //System.println("Lap");
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
        //System.println("Reset");
        _M_elapsed = null;
    } 

    function speedToKmh(s as Lang.Float or Null) {
        if (s == null) {
            return "-";
        }
        return (s * 3.6).format("%0.1f");
    }

    function getMaximum(a as Number, b as Number) as Number {
        return (a > b) ? a : b;
    }

    function shimValues(cur_max as Number, cur_maxavg as Number, last_max as Number, last_maxavg as Number, value_avgwindow as Number) {
        var valueView;
        valueView = View.findDrawableById("value");
        valueView.locY = valueView.locY - YSHIM_MAX;
        valueView = View.findDrawableById("value_cur_max");
        valueView.locX = valueView.locX + cur_max;
        valueView.locY = valueView.locY - YSHIM_MAX;
        valueView = View.findDrawableById("value_cur_maxavg");
        valueView.locX = valueView.locX + cur_maxavg;
        valueView.locY = valueView.locY + YSHIM_MAXAVG;
        valueView = View.findDrawableById("value_last_max");
        valueView.locX = valueView.locX + last_max;
        valueView.locY = valueView.locY - YSHIM_MAX;
        valueView = View.findDrawableById("value_last_maxavg");
        valueView.locX = valueView.locX + last_maxavg;
        valueView.locY = valueView.locY + YSHIM_MAXAVG;
        valueView = View.findDrawableById("value_avgwindow");
        valueView.locX = valueView.locX + value_avgwindow;
        valueView.locY = valueView.locY + YSHIM_MAXAVG;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        obscurityFlags = DataField.getObscurityFlags();
        optimumMainTextDimensions = dc.getTextDimensions("888.8  888.8", Graphics.FONT_TINY);
        mainTextComponentDimensions = dc.getTextDimensions("888.8", Graphics.FONT_TINY);
        optimumSubTextDimensions = dc.getTextDimensions("888.8 888s 888.8", Graphics.FONT_XTINY);
        subTextComponentDimensions = dc.getTextDimensions("888.8", Graphics.FONT_XTINY);
        dynMainXShim = ( (optimumMainTextDimensions[0] / 2) - (mainTextComponentDimensions[0] / 2)).toNumber();
        dynSubXShim = ( (optimumSubTextDimensions[0] / 2) - (subTextComponentDimensions[0] / 2)).toNumber();

        showLastLap = true;
        showAvgWindow = true;
        if (optimumSubTextDimensions[0] > dc.getWidth()) {
            optimumSubTextDimensions = dc.getTextDimensions("888.8  888.8", Graphics.FONT_XTINY);
            showAvgWindow = false;
            dynSubXShim = ( (optimumSubTextDimensions[0] / 2) - (subTextComponentDimensions[0] / 2)).toNumber();
        }
        dynMainXShim = getMaximum(dynMainXShim, dynSubXShim);
        dynSubXShim = dynMainXShim;
        if (optimumMainTextDimensions[0] > dc.getWidth()) {
            optimumMainTextDimensions = dc.getTextDimensions("888.8", Graphics.FONT_TINY);
            optimumSubTextDimensions = dc.getTextDimensions("888.8 888s", Graphics.FONT_XTINY);
            showLastLap = false;
            dynMainXShim = 0;
            dynSubXShim = ((optimumSubTextDimensions[0] - subTextComponentDimensions[0])/2).toNumber();
        }

        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        labelView.locY = labelView.locY - 22;
        var valueView;

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT) || (obscurityFlags == OBSCURE_LEFT) ) {
            showLastLap = false;
            showAvgWindow = true;
            valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_cur_max");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_cur_maxavg");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
            valueView = View.findDrawableById("value_last_max");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_last_maxavg");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
            valueView = View.findDrawableById("value_avgwindow");
            valueView.locX = valueView.locX - dynSubXShim;
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
        }
        // Top right quadrant so we'll use the top right layout
        else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT) || (obscurityFlags == OBSCURE_RIGHT)) {
            showLastLap = false;
            showAvgWindow = true;
            valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_cur_max");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_cur_maxavg");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
            valueView = View.findDrawableById("value_last_max");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_last_maxavg");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
            valueView = View.findDrawableById("value_avgwindow");
            valueView.locX = valueView.locX + dynSubXShim;
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
        }
        // Bottom left quadrant so we'll use the bottom left layout
        else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            showLastLap = false;
            showAvgWindow = false;
            valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_cur_max");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_cur_maxavg");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
            valueView = View.findDrawableById("value_last_max");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_last_maxavg");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
            valueView = View.findDrawableById("value_avgwindow");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
        }
        // Bottom right quadrant so we'll use the bottom right layout
        else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            showLastLap = false;
            showAvgWindow = false;
            valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_cur_max");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_cur_maxavg");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
            valueView = View.findDrawableById("value_last_max");
            valueView.locY = valueView.locY - YSHIM_MAX;
            valueView = View.findDrawableById("value_last_maxavg");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
            valueView = View.findDrawableById("value_avgwindow");
            valueView.locY = valueView.locY + YSHIM_MAXAVG;
        }
        else {
            if (!showLastLap) {
                valueView = View.findDrawableById("value");
                valueView.locY = valueView.locY - YSHIM_MAX;
                valueView = View.findDrawableById("value_cur_max");
                valueView.locY = valueView.locY - YSHIM_MAX;
                valueView = View.findDrawableById("value_cur_maxavg");
                valueView.locY = valueView.locY + YSHIM_MAXAVG;
                valueView = View.findDrawableById("value_last_max");
                valueView.locY = valueView.locY - YSHIM_MAX;
                valueView = View.findDrawableById("value_last_maxavg");
                valueView.locY = valueView.locY + YSHIM_MAXAVG;
                valueView = View.findDrawableById("value_avgwindow");
                valueView.locX = valueView.locX + dynSubXShim;
                valueView.locY = valueView.locY + YSHIM_MAXAVG;
            }
            else {
                valueView = View.findDrawableById("value");
                valueView.locY = valueView.locY - YSHIM_MAX;
                valueView = View.findDrawableById("value_cur_max");
                valueView.locX = valueView.locX - dynMainXShim;
                valueView.locY = valueView.locY - YSHIM_MAX;
                valueView = View.findDrawableById("value_cur_maxavg");
                valueView.locX = valueView.locX - dynSubXShim;
                valueView.locY = valueView.locY + YSHIM_MAXAVG;
                valueView = View.findDrawableById("value_last_max");
                valueView.locX = valueView.locX + dynMainXShim;
                valueView.locY = valueView.locY - YSHIM_MAX;
                valueView = View.findDrawableById("value_last_maxavg");
                valueView.locX = valueView.locX + dynSubXShim;
                valueView.locY = valueView.locY + YSHIM_MAXAVG;
                valueView = View.findDrawableById("value_avgwindow");
                valueView.locY = valueView.locY + YSHIM_MAXAVG;
            }
        }

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
            value_last_max.setText((showLastLap) ? "998.8" : "");
            value_last_maxavg.setText((showLastLap) ? "988.8" : "");
            value_avgwindow.setText((showAvgWindow) ? "120s" : "");
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
                    value_cur_max.setText("");
                    value_cur_maxavg.setText((showLastLap) ? "" : "stopped");
                    value_last_max.setText((showLastLap) ? speedToKmh(_lastlap_max_speed) : "");
                    value_last_maxavg.setText((showLastLap) ? speedToKmh(_lastlap_maxfloatavg_speed) : "");
                    value_avgwindow.setText((showLastLap) ? "stopped" : "");
                }
                else {
                    labelView.setText("");
                    value.setText("");
                    value_avgwindow.setText("");
                    value_cur_max.setText(speedToKmh(_lap_max_speed));
                    value_cur_maxavg.setText((showLastLap) ? speedToKmh(_lap_maxfloatavg_speed) : "stopped");
                    value_last_max.setText((showLastLap) ? speedToKmh(_lastlap_max_speed) : "");
                    value_last_maxavg.setText((showLastLap) ? "stopped" : "");
                }
            }
            else {
                    labelView.setText("");
                    value.setText("");
                    value_avgwindow.setText((showAvgWindow) ? _lap_speed_array.getSize().format("%3d")+"s" : "");
                    value_cur_max.setText(speedToKmh(_lap_max_speed));
                    value_cur_maxavg.setText(speedToKmh(_lap_maxfloatavg_speed));
                    value_last_max.setText((showLastLap) ? speedToKmh(_lastlap_max_speed) : "");
                    value_last_maxavg.setText((showLastLap) ? speedToKmh(_lastlap_maxfloatavg_speed) : "");
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
            //System.println(speedToKmh(s));

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