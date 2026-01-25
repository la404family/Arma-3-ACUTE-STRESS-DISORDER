/*
    File: fn_task_x_revival.sqf
    Author: la404family
    Description:
    Ajoute une action au joueur pour ordonner aux IA de son groupe de se soigner.
    Utilise condition de l'action pour la visibilité (optimisé, pas de boucle).
*/

params ["_unit"];

// Sécurité
if (!hasInterface) exitWith {};
if (isNull _unit) exitWith {};

// Anti-doublon
if (_unit getVariable ["MISSION_RevivalActionAdded", false]) exitWith {};
_unit setVariable ["MISSION_RevivalActionAdded", true];

_unit addAction [
    "<t color='#ffffffff'>" + (localize "STR_ACTION_HEAL_YOURSELVES") + "</t>", 
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        {
            // Vérifie si l'IA est blessée et a un kit de soin
            if (alive _x && !isPlayer _x && damage _x >= 0.1 && (("FirstAidKit" in (items _x)) || ("Medikit" in (items _x)))) then {
                _x action ["HealSoldierSelf", _x];
            };
        } forEach (units group _caller);
        
        systemChat (localize "STR_ACTION_HEAL_ORDER_SENT");
    },
    nil,
    1.5, 
    false, 
    true,
    "",
    "leader group _target == _target && { !isPlayer _x } count (units group _target) > 0" // Condition string: Chef de groupe + a des IA
];

diag_log format ["[REVIVAL] Action ajoutée pour %1", name _unit];
