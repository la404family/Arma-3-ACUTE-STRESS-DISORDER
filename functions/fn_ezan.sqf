/*
    File: fn_ezan.sqf
    Description: Plays the ezan sound from 5 minarets every 30 minutes with a staggered start.
*/

if (!isServer) exitWith {}; // Only run on server to avoid duplicate sounds in MP

// Wait between 250 seconds and 15 minutes (900s) after mission start
sleep (250 + (random 900));

while {true} do {
    // Play sound on minaret 1
    if (!isNil "bouteille_ezan_1") then {
        [bouteille_ezan_1, ["ezan", 2500, 1]] remoteExec ["say3D", 0];
    };
    
    sleep 0.1;
    
    // Play sound on minaret 2
    if (!isNil "bouteille_ezan_2") then {
        [bouteille_ezan_2, ["ezan", 2500, 1]] remoteExec ["say3D", 0];
    };
    
    sleep 0.1;
    
    // Play sound on minaret 3
    if (!isNil "bouteille_ezan_3") then {
        [bouteille_ezan_3, ["ezan", 2500, 1]] remoteExec ["say3D", 0];
    };
    sleep 0.1;

    // Play sound on minaret 4
    if (!isNil "bouteille_ezan_4") then {
        [bouteille_ezan_4, ["ezan", 2500, 1]] remoteExec ["say3D", 0];
    };
    
    sleep 0.1;
    
    // Play sound on minaret 0
    if (!isNil "bouteille_ezan_0") then {
        [bouteille_ezan_0, ["ezan", 2500, 1]] remoteExec ["say3D", 0];
    };
    
    sleep 0.1;
    
    // Wait 30 minutes
    sleep 1800;
};
