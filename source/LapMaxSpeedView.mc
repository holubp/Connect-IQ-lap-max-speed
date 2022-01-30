import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.FitContributor;
import Toybox.System;

class LapMaxSpeedView extends WatchUi.DataField {

    hidden var appVersion = "1.4.2";
    hidden var label;
    hidden var _M_paused;
    hidden var _M_stopped; 
    hidden var _lap_max_speed;
    hidden var _lastlap_max_speed;
    hidden var _current_lap = 0;
    hidden var MAX_SPEED_CHECK as Number = 2000;
    //hidden var TEST_LAYOUT = false;
    //hidden var YSHIM_MAX as Number = 13;
    //hidden var YSHIM_MAXAVG as Number = 10;
    hidden var speedMultiplier = 3.6;

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

    hidden var layoutInitialized as Boolean = false;
    hidden var dynMainXShim;
    hidden var dynMainYShim = 13;
    hidden var dynSubXShim;
    hidden var dynSubYShim = 10;
    hidden var showLastLap = true;
    hidden var showAvgWindow = true;

    function getPropertyValue(name as String) {
        try {
            if (Application has :Properties) {
                return Application.Properties.getValue(name);
            }
            else if (Application has :getApp) {
                return Application.getApp().getProperty(name);
            }
        }
        catch (ex) {}
        return 0;
    }

    hidden var _max_speed_floatavg;
    hidden var speedFloatAvgField = null;
    hidden var maxSpeedFloatAvgField = null;

    // Set the label of the data field here.
    function initialize() {
        DataField.initialize();
        label = "Lap max speed v" + appVersion;
        _M_paused = false;
        _M_stopped = true; 

        var lap_speed_array_size = getPropertyValue("avgPeriod");
        if (lap_speed_array_size == null || lap_speed_array_size <= 0) {
            lap_speed_array_size = 10;
        }
        _lap_speed_array = new AveragingBoundedArray(lap_speed_array_size);

        if (Toybox.System.DeviceSettings.paceUnits == System.UNIT_STATUTE) {
            speedMultiplier = 2.23694;
        }

        _max_speed_floatavg = 0.0;
        // Create the custom FIT data field we want to record.
        speedFloatAvgField = createField(
            "speed_floatavg_" + lap_speed_array_size + "s",
            0,
            FitContributor.DATA_TYPE_FLOAT,
            // I don't know yet how to make Connect use unit system flexibly based on user's preference - only fixed units possible AFAIK
            // {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=> (speedMultiplier == 3.6) ? "km/h" : "mph"}
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=> "km/h"}
        );
        speedFloatAvgField.setData(0.0);
        maxSpeedFloatAvgField = createField(
            "max_speed_floatavg_" + lap_speed_array_size + "s",
            1,
            FitContributor.DATA_TYPE_FLOAT,
            // I don't know yet how to make Connect use unit system flexibly based on user's preference - only fixed units possible AFAIK
            // {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=> (speedMultiplier == 3.6) ? "km/h" : "mph"}
            {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=> "km/h"}
        );
        maxSpeedFloatAvgField.setData(0.0);
    }

    function onTimerPause() {
        //System.println("Pause");
        _M_paused = true;
    }

    function onTimerResume() {
        //System.println("Resume");
        _M_paused = false;
    }

    function onTimerStart() {
        //System.println("Start");
        _M_stopped = false;
    }

    function onTimerStop() {
        //System.println("Stop");
        _M_stopped = true;
    }

    function onTimerLap() {
        //System.println("Lap");
        _current_lap++;
        _lastlap_max_speed = _lap_max_speed;
        _lastlap_maxfloatavg_speed = _lap_maxfloatavg_speed;
        _lap_max_speed = null;
        _lap_maxfloatavg_speed = null;
        _lap_speed_array.clear();
    }

    function speedToKmh(s as Lang.Float or Null) {
        if (s == null) {
            return "-";
        }
        return (s * speedMultiplier).format("%0.1f");
    }

    function getMaximum(a as Number, b as Number) as Number {
        return (a > b) ? a : b;
    }

    function shimValues(cur_max as Number, cur_maxavg as Number, last_max as Number, last_maxavg as Number, value_avgwindow as Number) {
        var valueView;
        //valueView = View.findDrawableById("value");
        //valueView.locY = valueView.locY - dynMainYShim;
        valueView = View.findDrawableById("value_cur_max");
        valueView.locX = valueView.locX + cur_max;
        valueView.locY = valueView.locY - dynMainYShim;
        valueView = View.findDrawableById("value_cur_maxavg");
        valueView.locX = valueView.locX + cur_maxavg;
        valueView.locY = valueView.locY + dynSubYShim;
        valueView = View.findDrawableById("value_last_max");
        valueView.locX = valueView.locX + last_max;
        valueView.locY = valueView.locY - dynMainYShim;
        valueView = View.findDrawableById("value_last_maxavg");
        valueView.locX = valueView.locX + last_maxavg;
        valueView.locY = valueView.locY + dynSubYShim;
        valueView = View.findDrawableById("value_avgwindow");
        valueView.locX = valueView.locX + value_avgwindow;
        valueView.locY = valueView.locY + dynSubYShim;
    }

    function initLayout(dc as Dc) as Void {
        var optimumMainTextDimensions = dc.getTextDimensions("887.8  888.8", Graphics.FONT_TINY);
        var mainTextComponentDimensions = dc.getTextDimensions("887.8", Graphics.FONT_TINY);
        var optimumSubTextDimensions = dc.getTextDimensions("887.8 888s 888.8", Graphics.FONT_XTINY);
        var subTextComponentDimensions = dc.getTextDimensions("887.8", Graphics.FONT_XTINY);
        dynMainXShim = ( (optimumMainTextDimensions[0] / 2) - (mainTextComponentDimensions[0] / 2)).toNumber();
        dynSubXShim = ( (optimumSubTextDimensions[0] / 2) - (subTextComponentDimensions[0] / 2)).toNumber();
        dynMainYShim = ( (mainTextComponentDimensions[1] / 2 )).toNumber();
        dynSubYShim = ( (subTextComponentDimensions[1] / 2)).toNumber();

        if (optimumSubTextDimensions[0] > dc.getWidth()) {
            optimumSubTextDimensions = dc.getTextDimensions("887.8  888.8", Graphics.FONT_XTINY);
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
        layoutInitialized = true;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        if (! layoutInitialized) {
            initLayout(dc);
        }

        showLastLap = true;
        showAvgWindow = true;
        View.setLayout(Rez.Layouts.MainLayout(dc));

        var labelView = View.findDrawableById("label");
        labelView.locY = labelView.locY - 22;


        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT) || (obscurityFlags == OBSCURE_LEFT) ) {
            showLastLap = false;
            showAvgWindow = true;
            shimValues (0, 0, 0, 0, -dynSubXShim);
        }
        // Top right quadrant so we'll use the top right layout
        else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT) || (obscurityFlags == OBSCURE_RIGHT)) {
            showLastLap = false;
            showAvgWindow = true;
            shimValues (0, 0, 0, 0, dynSubXShim);
        }
        // Bottom left quadrant so we'll use the bottom left layout
        // Bottom right quadrant so we'll use the bottom right layout
        else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT) || obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            showLastLap = false;
            showAvgWindow = false;
            shimValues (0, 0, 0, 0, 0);
        }
        else {
            if (!showLastLap) {
                shimValues (0, 0, 0, 0, dynSubXShim);
            }
            else {
                shimValues (-dynMainXShim, -dynSubXShim, dynMainXShim, dynSubXShim, 0);
            }
        }

        //(View.findDrawableById("label") as Text).setText(label);
    }

    function setValueColors(c as Array<Graphics.ColorValue>) {
        (View.findDrawableById("value")).setColor(c[0]);
        (View.findDrawableById("value_cur_max")).setColor(c[1]);
        (View.findDrawableById("value_cur_maxavg")).setColor(c[2]);
        (View.findDrawableById("value_last_max")).setColor(c[3]);
        (View.findDrawableById("value_last_maxavg")).setColor(c[4]);
        (View.findDrawableById("value_avgwindow")).setColor(c[5]);
    }

    function setValueTexts(t as Array<Text>) {
        (View.findDrawableById("label")).setText(t[0]);
        (View.findDrawableById("value")).setText(t[1]);
        (View.findDrawableById("value_cur_max")).setText(t[2]);
        (View.findDrawableById("value_cur_maxavg")).setText(t[3]);
        (View.findDrawableById("value_last_max")).setText(t[4]);
        (View.findDrawableById("value_last_maxavg")).setText(t[5]);
        (View.findDrawableById("value_avgwindow")).setText(t[6]);
    }

    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            setValueColors([Graphics.COLOR_WHITE, Graphics.COLOR_WHITE, Graphics.COLOR_WHITE, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY, Graphics.COLOR_DK_GRAY]);
        } else {
            setValueColors([Graphics.COLOR_BLACK, Graphics.COLOR_BLACK, Graphics.COLOR_BLACK, Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY, Graphics.COLOR_LT_GRAY]);
        }

        if (_M_paused || _M_stopped) {
            if (_lap_max_speed == null && _lastlap_max_speed == null) {
                setValueTexts([label, "ready to start", "", "", "", "", ""]);
            }
            else if (_lap_max_speed == null && _lastlap_max_speed != null) {
                setValueTexts(["", "", "",
                            (showLastLap) ? "" : "stopped",
                            (showLastLap) ? speedToKmh(_lastlap_max_speed) : "",
                            (showLastLap) ? speedToKmh(_lastlap_maxfloatavg_speed) : "",
                            (showLastLap) ? "stopped" : "" ]);
            }
            else {
                setValueTexts(["", "", speedToKmh(_lap_max_speed),
                            (showLastLap) ? speedToKmh(_lap_maxfloatavg_speed) : "stopped",
                            (showLastLap) ? speedToKmh(_lastlap_max_speed) : "",
                            (showLastLap) ? "stopped" : "",
                            ""]);
            }
        }
        else {
                setValueTexts(["", "", speedToKmh(_lap_max_speed),
                            speedToKmh(_lap_maxfloatavg_speed),
                            (showLastLap) ? speedToKmh(_lastlap_max_speed) : "",
                            (showLastLap) ? speedToKmh(_lastlap_maxfloatavg_speed) : "",
                            (showAvgWindow) ? _lap_speed_array.getSize().format("%3d")+"s" : ""]);
        }

        /*
        if (TEST_LAYOUT) {
            value.setText("");
            value_cur_max.setText("999.9");
            value_cur_maxavg.setText("999.8");
            value_last_max.setText((showLastLap) ? "998.8" : "");
            value_last_maxavg.setText((showLastLap) ? "988.8" : "");
            value_avgwindow.setText((showAvgWindow) ? "120s" : "");
        }
        */

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

            if (s != null && s < MAX_SPEED_CHECK.toFloat()) {
                // this is basic sanity check - the sometimes this can generate non-sense values like 4763019.5
                if (_lap_max_speed == null || _lap_max_speed < s) {
                    _lap_max_speed = s;
                }
                _lap_speed_array.store(s);
            }

            var lastRunningAvg = _lap_speed_array.getAverage();
            if (lastRunningAvg != null) {
                // I don't know yet how to make Connect use unit system flexibly based on user's preference - only fixed units possible AFAIK
                //maxSpeedFloatAvgField.setData(lastRunningAvg * speedMultiplier);
                speedFloatAvgField.setData(lastRunningAvg * 3.6);
                if (_max_speed_floatavg < lastRunningAvg) {
                    _max_speed_floatavg = lastRunningAvg;
                    maxSpeedFloatAvgField.setData(_max_speed_floatavg * 3.6);
                }
                if (_lap_maxfloatavg_speed == null || lastRunningAvg > _lap_maxfloatavg_speed) {
                    _lap_maxfloatavg_speed = lastRunningAvg;
                }
            }
        }
    }

}