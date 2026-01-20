/*
    initServer.sqf
    
    Description:
    Exécuté automatiquement côté serveur au démarrage de la mission.
    Compile et publie la fonction de livraison pour remoteExec.
*/

// Compiler la fonction de livraison véhicule
MN_fnc_serverDrop = compile preprocessFileLineNumbers "functions\fn_livraison_vehicule.sqf";

// Publier la fonction pour qu'elle soit accessible via remoteExec
publicVariable "MN_fnc_serverDrop";

diag_log "[SERVER] Fonction MN_fnc_serverDrop compilée et publiée";
