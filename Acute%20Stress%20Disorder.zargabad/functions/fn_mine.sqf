/*
    File: fn_mine.sqf
    Description: Spawns 10 ATMine_Range_Mag (ATMine) randomly in regular mine_00..13 markers.
    MP Optimization: Server-side only. Created mines are automatically networked.
*/

if (!isServer) exitWith {};

// List of markers
private _markers = [];
for "_i" from 0 to 13 do {
    _markers pushBack format ["mine_%1", if (_i < 10) then {"0" + str _i} else {str _i}];
};

{
    private _currentMarker = _x;
    
    // Check if marker exists to avoid errors
    if (getMarkerColor _currentMarker != "") then {
        
        // Spawn 10 mines
        for "_j" from 1 to 10 do {
            // Custom Random Position in Marker (Square/Rectangle support)
            private _mPos = getMarkerPos _currentMarker;
            private _mSize = getMarkerSize _currentMarker;
            private _mDir = markerDir _currentMarker;
            _mSize params ["_a", "_b"];
            
            // Random point in rectangle (local space)
            private _rx = (random (_a * 2)) - _a;
            private _ry = (random (_b * 2)) - _b;
            
            // Rotate if needed
            private _pos = if (_mDir != 0) then {
                [
                    (_mPos select 0) + (_rx * cos _mDir) - (_ry * sin _mDir),
                    (_mPos select 1) + (_rx * sin _mDir) + (_ry * cos _mDir),
                    0
                ]
            } else {
                [(_mPos select 0) + _rx, (_mPos select 1) + _ry, 0]
            };
            
            // Validation: Check if position is actually in the marker (for ellipses)
            if (!( _pos inArea _currentMarker)) then {
                _pos = _mPos; // Fallback to center if math fails (rare)
            };
            
            // createMine creates the mine trigger/object directly
            // APERSMine is the vehicle class for ATMine_Range_Mag
            private _mine = createMine ["APERSMine", _pos, [], 0];
            
            _mine setDir (random 360);
            
            // Optional: Bury it slightly or tilt it for realism? 
            // Default placement is usually fine for mines.
        };
        
    };
} forEach _markers;
