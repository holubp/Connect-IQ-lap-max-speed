import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class LapMaxSpeedView extends WatchUi.SimpleDataField {

    hidden var _M_previous;
    hidden var _M_elapsed;
    hidden var _M_paused;
    hidden var _M_stopped; 
    hidden var _lap_max_speed;
    hidden var _lastlap_max_speed;
    hidden var _current_lap = 0;
    const MAX_SPEED_CHECK = 2000;

    class AveragingBoundedArray {
        hidden var _size;
        hidden var _array;
        hidden var _current_index;
        hidden var _initialized_size;
        
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

    hidden var _lap_speed_array = new AveragingBoundedArray(10);
    hidden var _lap_maxfloatavg_speed;
    hidden var _lastlap_maxfloatavg_speed;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "Lap max speed";
        _M_paused = false;
        _M_stopped = true; 
    }

/*
    function onStart(state) {
        SimpleDataField.onStart(state);
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
                s = 0;
        }
        return (s * 3.6).format("%0.1f");
    }

    function formatOutput(s as Lang.Float or Lang.String or Null, s10s as Lang.Float or Lang.String or Null, t as Lang.Float or Lang.Number or Lang.String or Null, t10s as Lang.Float or Lang.Number or Lang.String or Null) as String {
        var o = "";
        if (s == null or s instanceof Lang.Float) {
                o += speedToKmh(s);
        }
        else if (s instanceof Lang.String) {
                o += s;
        }
        else {
            if (s has :toString) {
                o += s.toString();
            }
            else {
                o += "unknown";
            }
        }
        o += " ";
        if (s10s == null or s10s instanceof Lang.Float) {
                o += speedToKmh(s10s);
        }
        else if (s10s instanceof Lang.String) {
                o += s10s;
        }
        else {
            if (s10s has :toString) {
                o += s10s.toString();
            }
            else {
                o += "unknown";
            }
        }
        o += " ";
        if (t == null) {}
        // info.currentSpeed is Lang.Float
        else if (t instanceof Lang.Float) {
                o += speedToKmh(t);
        }
        // results of System.getTimer() are Lang.Number
        else if (t instanceof Lang.Number) {
                var diff = new Time.Duration(t / 1000);
                o += diff.value();
        }
        else if (t instanceof Lang.String) {
                o += t;
        }
        else {
            if (t has :toString) {
                o += t.toString();
            }
            else {
                o += "unknown";
            }
        }
        o += " ";
        if (t10s == null or t10s instanceof Lang.Float) {
                o += speedToKmh(t10s);
        }
        else if (t10s instanceof Lang.String) {
                o += t10s;
        }
        else {
            if (t10s has :toString) {
                o += t10s.toString();
            }
            else {
                o += "unknown";
            }
        }
        return o;
    }

    function valToDash(v) {
        if (v == null) {
            return "-";
        }
        else {
            return (v);
        }
    }


    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        if (_M_paused || _M_stopped) {
            if (_lap_max_speed == null && _lastlap_max_speed == null) {
                return formatOutput("ready to start", "", "", "");
            }
            else if (_lap_max_speed == null && _lastlap_max_speed != null) {
                return formatOutput("stopped", "", valToDash(_lastlap_max_speed), "");
            }
            else {
                return formatOutput(valToDash(_lap_max_speed), valToDash(_lap_maxfloatavg_speed), "stopped", "");
            }
        }

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

        //System.println("_M_elapsed=" + _M_elapsed);
        //System.println("_M_previous=" + _M_previous);

        return formatOutput(valToDash(_lap_max_speed), valToDash(_lap_maxfloatavg_speed), valToDash(_lastlap_max_speed), valToDash(_lastlap_maxfloatavg_speed));
    }

}