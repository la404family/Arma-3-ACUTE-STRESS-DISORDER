/*
    client_request_vehicule.sqf
    
    Description:
    Script client pour demander une livraison de véhicule.
    Exécuté via le menu de communication (0-8).
    Envoie la position au serveur pour le spawn.
*/

// Trouver une position sûre à 50m max du joueur (évite le drop SUR le joueur)
private _pos = [player, 10, 50, 5, 0, 20, 0] call BIS_fnc_findSafePos;

// Notification immédiate au joueur
hint (localize "STR_LIVRAISON_REQUESTED");

// Envoyer l'exécution au SERVEUR uniquement (ID 2 = serveur)
[_pos] remoteExec ["MN_fnc_serverDrop", 2];

diag_log format ["[LIVRAISON] Demande envoyée pour position: %1", _pos];
