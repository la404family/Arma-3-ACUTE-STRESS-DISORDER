/*
    File: fn_ezan.sqf
    Description: Plays the ezan sound from 5 minarets every 30 minutes.
    OPTIMIZATION: Only sends network traffic to players within audible range (2000m).
*/

if (!isServer) exitWith {}; // Only run on server

// --- CONFIGURATION ---
private _soundRange = 2500; // Portée du son en mètres
// Liste des noms de variables des objets minarets
private _minaretsVars = ["bouteille_ezan_1", "bouteille_ezan_2", "bouteille_ezan_3", "bouteille_ezan_4", "bouteille_ezan_0"];

// Attente initiale (aléatoire entre 250s et 15min)
sleep (250 + (random 900));

while {true} do {
    
    {
        private _varName = _x;
        // Récupérer l'objet via son nom de variable
        private _minaretObj = missionNamespace getVariable [_varName, objNull];
        
        if (!isNull _minaretObj) then {
            // OPTIMISATION NETWORK : Trouver les joueurs à portée audio uniquement
            private _nearbyPlayers = allPlayers select { (_x distance _minaretObj) < _soundRange };
            
            // Si des joueurs sont à portée, envoyer le son UNIQUEMENT à eux
            if (count _nearbyPlayers > 0) then {
                [_minaretObj, ["ezan", _soundRange, 1]] remoteExec ["say3D", _nearbyPlayers];
                // diag_log format ["[EZAN] Son joué sur %1 pour %2 joueurs", _varName, count _nearbyPlayers];
            };
        };
        
        // Décalage léger entre les minarets pour effet d'écho réaliste
        sleep 0.5;
        
    } forEach _minaretsVars;
    
    // Attendre 30 minutes avant le prochain appel
    sleep 1800;
};
