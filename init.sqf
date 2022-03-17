//init script for mission
#define S(ARRAY,INDEX) (ARRAY select INDEX)
#define index(ARRAY) (ARRAY select _forEachIndex)
#define setVar setVariable
#define getVar getVariable
#define nsMission missionNamespace
player addAction ["View my stats", {
	/*
	Potential stats(per helicopter):
		Number spawned
		Time in flight
		Successful landing
		Catastrohpic damage (can't fly anymore but not destroyed)
		Crashes
		Soldiers transported
		Soldiers killed
	*/
}, nil, 6, false, true];
player addAction [
	"Spawn Hummingbird",{
		_heli = createVehicle ["B_Heli_Light_01_F", player modelToWorld [0,-500,0], [], 0, "FLY"];
		_heli setDir direction player;
		player moveInDriver _heli;
		_heli setVelocityModelSpace [0,50,0];
	},nil,1,false,true,"",
	"missionNamespace getVariable ['PLAYER_HAS_TELEPORTED', false] && {_originalTarget == _target}"
];
player addAction ["Fix Heli",{
	(vehicle player) setDamage 0;
},nil,1,false,true,"",
"_originalTarget != _target && {getDammage _target > 0}"];
player addAction ["Change practice area", {
	player setPosATL [14648.7,16748.9,0]; 
	player setDir 326.641;
	nsMission setVar ["PLAYER_HAS_TELEPORTED", false];
}, nil, 1, false, true, "", "missionNamespace getVariable ['PLAYER_HAS_TELEPORTED', false]"];


createWithRotation = {
	private ["_prop","_pos"];
	_pos = S(_this, 1);
	_prop = createVehicle [S(_this, 0), _pos, [], 0, "CAN_COLLIDE"];
	_prop allowDamage false;
	_prop enableSimulation false;
	_prop setVectorUp [0,0,1];
	_prop setDir S(_this, 2);
	_prop setPosATL _pos;
	_prop;
};
rebuildComposition = {
	private ["_prop","_propList","_first"];
	_first = S(S(_this, 2), 0);
	_prop = [S(_first, 0), S(_this, 0) vectorAdd S(_first, 1), S(_this, 1) + S(_first, 2)] call createWithRotation;
	{
		if (_forEachIndex == 0) then { continue };
		[S(_x, 0), _prop modelToWorld S(_x, 1), S(_this, 1) + S(_x, 2)] call createWithRotation;
	} foreach S(_this, 2);
	_prop;
};
addToComposition = {

	[S(S(_this, 1), 0), S(_this,0) modelToWorld S(S(_this, 1), 1), (getDir S(_this,0)) + S(S(_this, 1), 2)] call createWithRotation;
};
_propList = [
	["Land_i_Addon_03mid_V1_F", [0,0,0], 0],
	["Land_i_Addon_03_V1_F", [-0.01,-7.411,-0.909], 0],
	["Land_i_Addon_04_V1_F", [-0.01,7.162,-0.909], 180],
	["Land_CampingTable_F", [3.5,9,-0.0124245], 0],
	["MapBoard_altis_F", [-1,9,-0.0121918], 330]
];
_laptop = ["Land_Laptop_03_black_F", [3.5,9,0.801048], 0];

//main = [[13671,15027,0], 30, _propList] call rebuildComposition;


_pos = getPosASL main;
removeAllWeapons player;
player allowDamage false;
//player setPosASL [S(_pos, 0), S(_pos, 1), S(_pos, 2) + .9];
//player setDir direction gardenMiddle;

_towns = [];
{
	_towns pushBack (configFile >> "CfgWorlds" >> "Altis" >> "Names" >> _x);
} foreach ["AgiosDionysios","Athira","Chalkeia","Charkia","Kavala","Neochori","Paros","Pyrgos","Sofia","Zaros"];
	
player setPosATL [14648.7,16748.9,0];
player setDir 326.641;
	
_spawnList = [
	[[10416.3,17493.5,1,0],[9548.99,14088.4,0,0],[6589.63,15906.5,0,0]], //AgiosDionysios
	[[13633.5,19999,0,72],[12644.2,17442.6,0,0],[15342.9,18520.1,0,0]], //Athira
	[[21167.1,11083.6,0,0],[21026.8,13156.1,0,0],[18966.8,10998.3,0,0]], //Chalkeia
	[[17539.1,14275.3,0,0],[17542.2,16125.1,0,0],[19727.6,15089.2,0,0]], //Charkia
	[[6200.38,12769.9,0,0],[4360.08,14919,0,0],[3716.31,10732.8,0,0]], //Kavala
	[[11311.3,15324.8,0,208],[11666.1,12818,0,303],[13663.8,15014.3,0,0]],//Neochori
	[[22343.7,16634.1,0,0],[21013.1,18124.2,0,0],[19847.5,15891.9,0,0]], //Paros
	[[18138.7,11691.3,0,0],[17380.9,13743.1,0,0],[16062.5,11425.1,0,0]], //Pyrgos
	[[23748.7,21883.9,0,0],[25970.9,20004.5,0,0],[26733.5,22749.6,0,0]], //Sofia
	[[8956.45,10608.2,0,0],[9977.78,12747,0,0],[7506.09,12200.9,0,0]] //Zaros
];
spawnGuy allowDamage false;
removeBackpack spawnGuy;
spawnGuy addAction [
	"Reset Selection", {
		missionNamespace setVariable ["SELECTED_TOWN", ""];
		missionNamespace setVariable ["SELECTED_SIDE", ""];
	},_currentName,1,false,true,"",
	"(missionNamespace getVariable ['SELECTED_TOWN','']) != ''"
];

getConfigFromArray = {
	private ["_selectedTown","_config"];
	_selectedTown = 0;
	_config = configFile;
	{
		if (S(_this, 1) == getText (_x >> S(_this, 2))) then {
		_selectedTown = _forEachIndex;
		_config = _x;
		break;
		};
	} foreach S(_this, 0);
	[_selectedTown, _config];
};
setMarker = {
	deleteWaypoint [group player, 0];
	_wp = (group player) addWaypoint [S(_this, 0), 0];
	_wp setWaypointType "UNLOAD";
	_wp setWaypointDescription "AO";
	(group player) lockWP true;
	_m = createMarker ["AOMarker", S(_this,0)];
	_m setMarkerShape "ELLIPSE";
	_m setMarkerSize S(_this, 1);
};
lSelect = {
	private "_output";
	_output = _this select 0;
	for "_i" from 1 to ((count _this) - 1) do {
		_output = _output select (_this select _i);
	};
	_output;
};
goButtonCode = {
	private ["_array","_selectedSIde","_selected","_centerObject","_laptop","_vehicle"];
	_array = [S(S(_this, 3), 0), missionNamespace getVariable ["SELECTED_TOWN",""], "name"] call getConfigFromArray;
	_selectedSide = switch (missionNamespace getVariable ["SELECTED_SIDE",""]) do {
		case "WEST": { 0 };
		case "EAST": { 1 };
		case "GUER": { 2 };
	};
	
	_selected = [_this, 3, 1, S(_array, 0), _selectedSide] call lSelect;
	_centerObject = [[S(_selected, 0),S(_selected, 1),S(_selected, 2)], S(_selected, 3), S(S(_this, 3), 2)] call rebuildComposition;
	_laptop = [_centerObject, S(S(_this, 3),3)] call addToComposition;
	{
		_laptop addAction [format ["Create %1", getText (configFile >> "CfgVehicles" >> _x >> "displayName")], {
			_vehicle = createVehicle [S(_this, 3), S(_this, 0) modelToWorld [5,5,0]];
			player setDir (player getDir _vehicle);
		}, _x, 1, false, true];
	} foreach ["B_Heli_Transport_03_unarmed_F","B_Heli_Light_01_F","B_Heli_Transport_01_F","O_Heli_Transport_04_bench_F","O_Heli_Light_02_unarmed_F","I_Heli_Transport_02_F","I_Heli_light_03_unarmed_F"];
	
	player setPosATL ((getPosATL _centerObject) vectorAdd [0,0,0.9]);
	missionNamespace setVariable ["PLAYER_HAS_TELEPORTED", true];
	
	[getArray (S(_array, 1) >> "position"),[getNumber (S(_array, 1) >> "radiusA"),getNumber (S(_array, 1) >> "radiusA")]] call setMarker;
};

spawnGuy addAction [ "<t color='#00FF00'>GO</t>", goButtonCode, [_towns,_spawnList, _propList, _laptop], 6, false, true, "", "(missionNamespace getVariable ['SELECTED_TOWN','']) != '' && {(missionNamespace getVariable ['SELECTED_SIDE','']) != ''}"];
	
{ //create town menu options
	_currentName = getText (_x >> "name");
	spawnGuy addAction [format ["Select %1", _currentName], {
			missionNamespace setVariable ["SELECTED_TOWN", S(_this, 3)];
			S(_this, 0) setUserActionText [S(_this, 2), format ["<t color='#FFFF00'>Select %1</t>", S(_this, 3)]];
		},_currentName,1,false,false,"","(missionNamespace getVariable ['SELECTED_TOWN','']) == ''"
	];
} foreach _towns;
{ //create side menu options
	_sideItem = _x;
	spawnGuy addAction [format ["Select %1 spawn", _sideItem], {
			missionNamespace setVariable ["SELECTED_SIDE", S(_this,3)];
			S(_this, 0) setUserActionText [S(_this, 2), format ["<t color='#FFFF00'>Select %1 spawn</t>", S(_this, 3)]];
		},_sideItem,1,false,false,"","(missionNamespace getVariable ['SELECTED_TOWN','']) != ''"
	];
} foreach ["WEST","EAST","GUER"];

execVM "DE_diagnostic.sqf";