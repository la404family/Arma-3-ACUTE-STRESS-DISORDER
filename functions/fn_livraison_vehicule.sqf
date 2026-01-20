/*
    fn_livraison_vehicule.sqf
    
    Description:
    Fonction serveur pour la livraison de véhicule par hélicoptère (sling load).
    Un Huron transporte un Prowler jusqu'à la position demandée.
    
    Paramètres:
    _targetPos - Position ATL de livraison
    
    Exécution:
    [_pos] remoteExec ["MN_fnc_serverDrop", 2];
*/

if (!isServer) exitWith {};

params ["_targetPos"];

// --- CONFIGURATION ---
private _spawnDist = 2000;
private _helicoClass = "B_Heli_Transport_03_F"; // Huron (CH-67)
private _vehClass = "B_LSV_01_unarmed_F"; // Prowler (désarmé)
private _flyHeight = 150;

// Calcul du point de départ (direction aléatoire depuis la cible)
private _dir = random 360;
private _spawnPos = _targetPos getPos [_spawnDist, _dir];
_spawnPos set [2, _flyHeight];

// 1. SPAWN HÉLICOPTÈRE - directement en vol
private _heli = createVehicle [_helicoClass, _spawnPos, [], 0, "FLY"];
_heli setPos _spawnPos;
_heli setDir (_dir + 180);
_heli flyInHeight _flyHeight;

// Créer l'équipage
private _group = createGroup [WEST, true];
private _crew = [];

// Pilote
private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_pilot moveInDriver _heli;
_crew pushBack _pilot;

// Co-pilote
private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_copilot moveInTurret [_heli, [0]];
_crew pushBack _copilot;

// Configuration IA - Comportement logistique
_group setBehaviour "CARELESS";
_group setCombatMode "BLUE";
_group setSpeedMode "FULL";

// Désactiver complètement le combat et rendre INDESTRUCTIBLE
{
    _x disableAI "AUTOCOMBAT";
    _x disableAI "AUTOTARGET";
    _x disableAI "TARGET";
    _x disableAI "FSM";
    _x setCaptive true;
    _x allowDamage false; // Équipage indestructible (permanent)
} forEach _crew;

// Hélicoptère indestructible (permanent)
_heli allowDamage false;

// 2. VÉHICULE & SLING LOAD
private _cargo = createVehicle [_vehClass, [0,0,0], [], 0, "NONE"];
_cargo setPos (_heli modelToWorld [0, 0, -10]);
_cargo allowDamage false; // Véhicule indestructible pendant transport
_heli setSlingLoad _cargo;

// Message radio global
(localize "STR_LIVRAISON_INBOUND") remoteExec ["systemChat", 0];

diag_log format ["[LIVRAISON] Hélicoptère créé en %1, direction cible %2", _spawnPos, _targetPos];

// 3. BOUCLE DE GESTION
[_heli, _cargo, _targetPos, _group, _crew, _spawnPos] spawn {
    params ["_heli", "_cargo", "_targetPos", "_group", "_crew", "_homeBase"];
    
    // Créer un waypoint pour forcer le mouvement
    private _wp1 = _group addWaypoint [_targetPos, 0];
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointBehaviour "CARELESS";
    _wp1 setWaypointCombatMode "RED";
    _wp1 setWaypointSpeed "FULL";
    
    _heli doMove _targetPos;
    
    // -- Phase d'approche --
    waitUntil { sleep 1; (_heli distance2D _targetPos) < 300 || !alive _heli };
    
    if (!alive _heli) exitWith {
        diag_log "[LIVRAISON] Hélicoptère détruit pendant l'approche";
    };

    // Supprimer le waypoint précédent
    deleteWaypoint _wp1;
    
    // FORCER la descente avec plusieurs méthodes
    _heli flyInHeight 20;
    _heli flyInHeightASL [20, 20, 20];
    
    // Nouveau waypoint à basse altitude
    private _wp2 = _group addWaypoint [_targetPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointBehaviour "CARELESS";
    
    _heli doMove _targetPos;
    
    diag_log "[LIVRAISON] Début descente pour largage";
    
    // Attente position précise
    private _timeout = 0;
    waitUntil { 
        sleep 0.5; 
        _timeout = _timeout + 0.5;
        ((_heli distance2D _targetPos) < 100) || _timeout > 60 || !alive _heli 
    };
    
    if (!alive _heli) exitWith {
        diag_log "[LIVRAISON] Hélicoptère détruit pendant la descente";
    };

    // Arrêt stationnaire forcé
    doStop _heli;
    _heli flyInHeight 10;
    
    // Attendre que l'hélico soit assez bas ou timeout
    private _dropTimeout = 0;
    waitUntil {
        sleep 0.5;
        _dropTimeout = _dropTimeout + 0.8;
        ((getPos _heli select 2) < 50) || _dropTimeout > 15
    };
    
    sleep 2; // Stabilisation
    
    // -- Largage --
    if (alive _heli && alive _cargo) then {
        _heli setSlingLoad objNull;
        
        // Véhicule devient DESTRUCTIBLE après largage
        _cargo allowDamage true;
        
        (localize "STR_LIVRAISON_DROPPED") remoteExec ["systemChat", 0];
        diag_log format ["[LIVRAISON] Véhicule largué en %1 - Véhicule maintenant destructible", _targetPos];
    };
    
    sleep 3;
    
    // -- Retour base (hélico reste INDESTRUCTIBLE) --
    deleteWaypoint [_group, 0];
    
    _heli flyInHeight 150;
    
    private _wpHome = _group addWaypoint [_homeBase, 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";
    
    _heli doMove _homeBase;
    
    // -- Nettoyage --
    waitUntil { 
        sleep 5; 
        (_heli distance2D _targetPos > 2000) || !alive _heli
    };
    
    // Suppression propre
    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;
    
    diag_log "[LIVRAISON] Hélicoptère et équipage supprimés";
};
