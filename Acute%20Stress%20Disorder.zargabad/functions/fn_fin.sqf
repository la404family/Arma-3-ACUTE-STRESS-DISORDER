/*
    fn_fin.sqf
    
    Description:
    Système de fin de mission avec extraction par hélicoptère.
    Optimisé pour le MULTIPLAYER.
    - Création de tache "EXTRACTION"
    - Compteur de joueurs (Joueur X / Y prêt)
    - Hélicoptère CARELESS mais combat mode RED (défensif)
    - Invisibilité des joueurs une fois dans l'hélicoptère
*/

if (!isServer) exitWith {};

diag_log "[FIN_MISSION] === Démarrage du système de fin de mission ===";

// --- CONFIGURATION ---
private _delayBeforeMessage = 1800 + floor(random 900); // 30 à 45 minutes
private _heliClass = "B_Heli_Transport_03_F"; // CH-67 Huron
private _flyTime = 120; // 120 secondes de vol avant fin de mission

// Position d'atterrissage - objet invisible heli_fin
private _heliFinObj = missionNamespace getVariable ["heli_fin", objNull];
private _landingPos = [0, 0, 0];

if (!isNull _heliFinObj) then {
    _landingPos = getPos _heliFinObj;
    diag_log "[FIN_MISSION] Objet heli_fin trouvé !";
} else {
    diag_log "[FIN_MISSION] ERREUR: Objet heli_fin non trouvé! Recherche de marker_4...";
    if (getMarkerColor "marker_4" != "") then {
        _landingPos = getMarkerPos "marker_4";
    } else {
        diag_log "[FIN_MISSION] ERREUR: marker_4 non trouvé! Utilisation de respawn_west";
        _landingPos = getMarkerPos "respawn_west";
    };
};

if (_landingPos isEqualTo [0,0,0]) then {
    diag_log "[FIN_MISSION] ERREUR CRITIQUE: Aucun point d'atterrissage trouvé! Abandon.";
    _landingPos = getPos (allPlayers select 0);
};

diag_log format ["[FIN_MISSION] Position atterrissage: %1", _landingPos];

// Position de spawn hélico (2km de la base)
private _spawnDir = random 360;
private _heliSpawnPos = _landingPos getPos [2000, _spawnDir];
_heliSpawnPos set [2, 150];

diag_log format ["[FIN_MISSION] Hélico spawn prévu en: %1", _heliSpawnPos];
diag_log format ["[FIN_MISSION] Extraction dans %1 secondes (%2 minutes)", _delayBeforeMessage, _delayBeforeMessage / 60];

// --- BOUCLE PRINCIPALE ---
[_delayBeforeMessage, _heliClass, _flyTime, _landingPos, _heliSpawnPos] spawn {
    params ["_delayBeforeMessage", "_heliClass", "_flyTime", "_landingPos", "_heliSpawnPos"];
    
    // Attendre le délai configuré
    diag_log format ["[FIN_MISSION] Attente de %1 secondes...", _delayBeforeMessage];
    sleep _delayBeforeMessage;
    
    diag_log "[FIN_MISSION] === Délai écoulé - Lancement extraction ===";
    
    // ============================================================
    // CRÉATION DE LA TÂCHE D'EXTRACTION
    // ============================================================
    // Jargon militaire : Evacuation pending. Proceed to LZ.
    
    [
        true,                                     // Visible pour tout le monde
        "task_evacuation",                        // ID de la tâche
        [
            localize "STR_TASK_EVAC_DESC",        // Description
            localize "STR_TASK_EVAC_TITLE",       // Titre
            "EXTRACTION"                          // Marqueur HUD
        ],
        _landingPos,                              // Position de la tâche
        "CREATED",                                // État initial
        10,                                       // Priorité
        true,                                     // Notification
        "takeoff",                                // Type d'icône (héli décollant)
        true                                      // Toujours visible 3D
    ] call BIS_fnc_taskCreate;

    sleep 5;

    // ============================================================
    // SPAWN DE L'HÉLICOPTÈRE D'EXTRACTION
    // ============================================================
    
    diag_log format ["[FIN_MISSION] Création hélicoptère: %1 en %2", _heliClass, _heliSpawnPos];
    
    // Créer l'hélico en vol
    private _heli = createVehicle [_heliClass, _heliSpawnPos, [], 0, "FLY"];
    
    if (isNull _heli) then {
        diag_log "[FIN_MISSION] ERREUR: Échec création hélicoptère!";
    } else {
        diag_log format ["[FIN_MISSION] Hélicoptère créé avec succès: %1", _heli];
    };
    
    _heli setPos _heliSpawnPos;
    _heli setDir (_heliSpawnPos getDir _landingPos);
    _heli flyInHeight 100;
    _heli setFuel 1;
    
    // Créer l'équipage
    createVehicleCrew _heli;
    private _group = group driver _heli;
    private _crew = crew _heli;
    
    diag_log format ["[FIN_MISSION] Équipage créé: %1 membres", count _crew];
    
    // Configuration IA - CARELESS MAIS COMBAT MODE RED
    // L'hélico suit sa route (CARELESS) mais tire sur les ennemis (RED)
    _group setBehaviour "CARELESS";
    _group setCombatMode "RED";
    
    {
        _x setCaptive true;       // L'équipage ne se fait pas tirer dessus en priorité (optionnel)
        _x allowDamage false;     // Invulnérable pour garantir l'extraction
    } forEach _crew;
    
    _heli allowDamage false;      // Hélico invulnérable
    
    // Message radio via hint ou sous-titre
    // (localize "STR_FIN_HELI_INBOUND") remoteExec ["hint", 0];
    
    // ============================================================
    // VOL VERS LA BASE ET ATTERRISSAGE
    // ============================================================
    
    diag_log format ["[FIN_MISSION] Hélico en route vers %1", _landingPos];
    
    _heli doMove _landingPos;
    
    // Attendre l'approche
    waitUntil { sleep 1; (_heli distance2D _landingPos) < 200 || !alive _heli };
    
    diag_log "[FIN_MISSION] Hélico proche - Début atterrissage";
    
    // Forcer l'atterrissage
    _heli flyInHeight 0;
    _heli land "GET IN";
    
    waitUntil { sleep 2; (_heli distance2D _landingPos) < 80 };
    
    _heli setFuel 0; // Couper le carburant pour forcer l'atterrissage
    
    // Attendre que l'hélico soit au sol
    private _landTimeout = 0;
    waitUntil { 
        sleep 1; 
        _landTimeout = _landTimeout + 1;
        ((getPos _heli select 2) < 3) || _landTimeout > 60 
    };
    
    doStop _heli;
    _heli setVehicleLock "UNLOCKED"; // Déverrouiller pour être sûr
    
    // Ouvrir la rampe arrière (Huron)
    _heli animateSource ["door_rear_source", 1];
    _heli animateDoor ["door_rear_source", 1];
    
    diag_log "[FIN_MISSION] Hélicoptère posé - En attente des joueurs";
    
     // Mettre à jour la tâche pour indiquer d'embarquer / Marker sur l'hélico
    ["task_evacuation", _landingPos] call BIS_fnc_taskSetDestination;
    ["task_evacuation", "ASSIGNED"] call BIS_fnc_taskSetState;
    
    // ============================================================
    // BOUCLE D'ATTENTE ET COMPTEUR JOUEURS (Multiplayer Optimized)
    // ============================================================
    
    diag_log "[FIN_MISSION] En attente que tous les joueurs montent...";
    
    private _allPlayersInHeli = false;
    
    while {!_allPlayersInHeli} do {
        sleep 3;
        
        // Récupérer les joueurs réellement connectés et vivants
        private _activePlayers = allPlayers select { alive _x && isPlayer _x };
        private _totalPlayers = count _activePlayers;
        
        if (_totalPlayers == 0) then { continue }; // Pas de joueurs ? On attend.
        
        // Compter combien sont dans l'hélico
        private _playersInHeli = { (vehicle _x) == _heli } count _activePlayers;
        
        // Afficher le statut à tous les joueurs
        // Format: "Extraction Status: Player X / Y ready"
        private _msg = format [localize "STR_EVAC_PLAYER_COUNT", _playersInHeli, _totalPlayers];
        _msg remoteExec ["hintSilent", 0];
        
        // Condition de départ : Tout le monde est là ou (si plus de 1 joueur) 100% sont là
        if (_playersInHeli >= _totalPlayers && _totalPlayers > 0) then {
            _allPlayersInHeli = true;
            diag_log format ["[FIN_MISSION] Tous les joueurs à bord (%1)", _totalPlayers];
        };
    };
    
    // ============================================================
    // TOUT LE MONDE EST LÀ - INVISIBILITÉ ET DÉCOLLAGE
    // ============================================================
    
    // Message final
    (localize "STR_EVAC_ALL_ABOARD") remoteExec ["hint", 0]; // "All units secured. Dust off immediately."
    ["task_evacuation", "SUCCEEDED"] call BIS_fnc_taskSetState;
    
    // Rendre les joueurs invisibles une fois à l'intérieur
    {
        if (isPlayer _x && (vehicle _x) == _heli) then {
            // Rendre invisible (globalement) pour éviter les glitches visuels ou tirs
            [_x, true] remoteExec ["hideObjectGlobal", 2]; 
            _x allowDamage false;
        };
    } forEach allPlayers;
    
    diag_log "[FIN_MISSION] Joueurs sécurisés et cachés. Décollage.";
    
    // Annuler le mode atterrissage et stop
    _heli land "NONE";
    
    // Fermer la rampe arrière
    _heli animateSource ["door_rear_source", 0];
    _heli animateDoor ["door_rear_source", 0];
    sleep 2;
    
    // Restaurer le carburant et allumer le moteur
    _heli setFuel 1;
    _heli engineOn true;
    
    sleep 5; // Laisser le temps au moteur de démarrer
    
    // Destination: point 0,0 de la carte pour disparaitre
    private _exitPos = [0, 0, 0];
    
    _heli flyInHeight 200;
    _heli doMove _exitPos;
    _heli limitspeed 300;
    
    // Attendre le temps de vol
    diag_log format ["[FIN_MISSION] Vol vers extraction - %1 secondes restantes", _flyTime];
    
    sleep _flyTime;
    
    // ============================================================
    // FIN DE MISSION
    // ============================================================
    
    diag_log "[FIN_MISSION] === MISSION TERMINÉE - SUCCÈS ===";
    
    // Terminer la mission avec succès
    // "End1" est souvent une fin standard définie dans description.ext
    ["END1", true] remoteExec ["BIS_fnc_endMission", 0];
};

diag_log "[FIN_MISSION] Système initialisé avec succès";
