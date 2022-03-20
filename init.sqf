//init script for mission
#define S(ARRAY,INDEX) (ARRAY select INDEX)
#define index(ARRAY) (ARRAY select _forEachIndex)
#define setVar setVariable
#define getVar getVariable
#define nsMission missionNamespace

//player addAction ["Run Test", {
//	_vehicle = vehicle player;
//	_startTime = time;
//	for "_i" from 0 to 1000000 do {
//		_vehicle emptyPositions "cargo";
//	};
//	_endTime = time;
//	systemChat format ["emptyPositions: %1", _endTime - _startTime];
//	_startTime = time;
//	for "_i" from 0 to 1000000 do {
//		fullCrew [_vehicle, "cargo", true];
//	};
//	_endTime = time;
//	systemChat format ["fullCrew(true): %1", _endTime - _startTime];
//	_startTime = time;
//	for "_i" from 0 to 1000000 do {
//		fullCrew [_vehicle, "cargo", false];
//	};
//	_endTime = time;
//	systemChat format ["fullCrew(false): %1", _endTime - _startTime];
//}];
//
//ra1 addAction [ "On" , {
//	_globalSoundSource = missionNamespace getVariable ["CURRENT_SOUND", objNull]; 
//	if (!(_globalSoundSource isEqualTo objNull)) then { 
//		deleteVehicle _globalSoundSource; 
//	}; 
//	[ra1, "Audioger", 50, 1] remoteExec ["playSoundGlobal", [0, -2] select isDedicated];
//}];

player addRating 9001;
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
	hintSilent "";
	MISSION_PROGRESS = 0;
	PLAYER_HAS_TELEPORTED = false;
	deleteVehicle (missionNamespace getVar ["PLAYER_VEHICLE", objNull]);
	SCRIPTS apply {terminate _x;};
	Soldiers apply {deleteVehicle _x;};
	PLAYER_CARGO = [];
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
	SPAWNPOINT = _centerObject;
	_laptop = [_centerObject, S(S(_this, 3),3)] call addToComposition;
	{
		_laptop addAction [format ["Create %1", getText (configFile >> "CfgVehicles" >> _x >> "displayName")], {
			deleteVehicle (missionNamespace getVar ["PLAYER_VEHICLE", objNull]);
			_vehicle = createVehicle [S(_this, 3), S(_this, 0) modelToWorld [10,10,0], [], 0];
			_pos = getPos _vehicle;
			_vehicle setPos [_pos select 0, _pos select 1, 0];
			PLAYER_VEHICLE = _vehicle;
			player setDir (player getDir _vehicle);
			MISSION_PROGRESS = 1;
			soldiers = (missionNamespace getVariable ["PLAYER_CARGO", []]) + (missionNamespace getVariable ["soldiers", []]);
			PLAYER_CARGO = [];
		}, _x, 1, false, true];
	} foreach ["B_Heli_Transport_03_unarmed_F","B_Heli_Light_01_F","B_Heli_Transport_01_F","O_Heli_Transport_04_bench_F","O_Heli_Light_02_unarmed_F","I_Heli_Transport_02_F","I_Heli_light_03_unarmed_F"];
	
	player setPosATL ((getPosATL _centerObject) vectorAdd [0,0,0.9]);
	missionNamespace setVariable ["PLAYER_HAS_TELEPORTED", true];
	
	[getArray (S(_array, 1) >> "position"),[getNumber (S(_array, 1) >> "radiusA"),getNumber (S(_array, 1) >> "radiusB")]] call setMarker;
	OBJECTIVE = getArray (S(_array, 1) >> "position");
	PLAYER_CARGO = [];
	SCRIPTS = [];
	SCRIPTS pushBack (_centerObject spawn soldierSpawner);
	//SCRIPTS pushBack ([] spawn mainScript);
	SCRIPTS pushBack ([] spawn progressEvaluator);
};
//mainScript = {
//	//TODO: get progression conditions out of here
//	MISSION_PROGRESS = missionNamespace getVar ["MISSION_PROGRESS",0];
//	//Get a chopper
//	
//	waitUntil {MISSION_PROGRESS == 1};
//	//Get in chopper
//	
//	
//	//sleep 1;
//	waitUntil {MISSION_PROGRESS == 2};
//	//Wait for people to get in
//	
//	while {true} do {
//		waitUntil {MISSION_PROGRESS == 3};
//	
//		waitUntil {MISSION_PROGRESS == 4};
//		
//		//Land at AO (calculate score)
//		waitUntil {((getPosATL player) select 2) < 2};
//		soldiers allowGetIn false;
//		soldiers apply { moveOut _x; };
//		
//		waitUntil {MISSION_PROGRESS == 5};
//	}
//};

//[] spawn {
//	while {true} do {
//		hintSilent str (missionNamespace getVariable ["PLAYER_CARGO", []]);
//	}
//};

progressEvaluator = {
	//TODO: move progression conditions here and make message a global string variable
	private _progressMessage = "";
	while {true} do {
		switch (missionNamespace getVar ["MISSION_PROGRESS",0]) do {
			case 0: {
				_progressMessage = "Spawn a chopper from the laptop";
			};
			case 1: {
				_progressMessage = "1. Get in your heli";
				if (PLAYER_VEHICLE isEqualTo objNull) then { MISSION_PROGRESS = 0; };
				if (vehicle player != player) then { MISSION_PROGRESS = 2; };
			};
			case 2: {
				_progressMessage = "2. Wait for soldiers to get in";
				if (vehicle player == player) then { MISSION_PROGRESS = 1; };
				if (count (fullCrew PLAYER_VEHICLE) > 1) then { MISSION_PROGRESS = 3; };
				if (PLAYER_VEHICLE distance SPAWNPOINT < 100) then { CHOPPER_NEAR = true; };
			};
			case 3: {
				_progressMessage = "3. Takeoff and fly to the AO";
				if (vehicle player == player) then { MISSION_PROGRESS = 1; };
				if (PLAYER_VEHICLE distance SPAWNPOINT < 100) then { CHOPPER_NEAR = true; } else { CHOPPER_NEAR = false; };
				if (PLAYER_VEHICLE distance OBJECTIVE < 200) then { MISSION_PROGRESS = 4; };
			};
			case 4: {
				_progressMessage = "4. Fly to the waypoint and land";
				if (vehicle player == player) then { MISSION_PROGRESS = 1; };
				if (count (fullCrew PLAYER_VEHICLE) == 1) then { MISSION_PROGRESS = 5; };
				if (((getPos PLAYER_VEHICLE) select 2) < 1) then { { moveOut _x} foreach PLAYER_CARGO; PLAYER_CARGO orderGetIn false; soldiers orderGetIn false; };
			};
			case 5: {
				_progressMessage = "5. Fly back to spawn point and land";
				if (vehicle player == player) then { MISSION_PROGRESS = 1; };
				if (PLAYER_VEHICLE distance SPAWNPOINT < 100) then { MISSION_PROGRESS = 2; PLAYER_CARGO apply { deleteVehicle _x; }; PLAYER_CARGO = []; };
			};
		};
		hintSilent _progressMessage;
		sleep 1;
	};
};
soldierSpawner = {
	_initial = 2 + floor(random 7);
	_progress = missionNamespace getVar ["MISSION_PROGRESS",0];
	soldiers = [];
	for "_i" from 0 to _initial do {
		_newUnit = (createGroup west) createUnit ["B_Soldier_F", (getPosATL _this) vectorAdd [0,0,0.9], [], 3, "NONE"];
		_newUnit doMove (_this call getNewSpawnPos);
		soldiers pushBack _newUnit;
	};
	_this spawn soldierSimulator;
	while {true} do {
		//TODO: something
		if (!(missionNamespace getVar ["PLAYER_VEHICLE", objNull] isEqualTo objNull) && {count soldiers < (count (fullCrew [PLAYER_VEHICLE, "", true])) - 1}) then {
			_newUnit = (createGroup west) createUnit ["B_Soldier_F", (getPosATL _this) vectorAdd [0,0,0.9], [], 3, "NONE"];
			_newUnit doMove (_this call getNewSpawnPos);
			soldiers pushBack _newUnit;
		};
		sleep (random 5);
	}
};

//PLAYER_VEHICLE setPos (PLAYER_VEHICLE modelToWorldVisual [0,0,2000]);
//(vehicle player) setDammage 0;

soldierSimulator = {
	while {true} do {
		while {!(missionNamespace getVar ["CHOPPER_NEAR", false])} do {
			{
				if (speed _x < 1) then {
					_x doMove (_this call getNewSpawnPos);
				};
			} foreach soldiers;
			soldiers orderGetIn false;
			sleep 1;
		};
		while {missionNamespace getVar ["CHOPPER_NEAR", false]} do {
			{
				(group _x) addVehicle PLAYER_VEHICLE;
				_x assignAsCargo PLAYER_VEHICLE;
			} foreach soldiers;
			soldiers orderGetIn true;
			{
				if (vehicle _x isEqualTo (missionNamespace getVar ["PLAYER_VEHICLE", objNull])) then {
					PLAYER_CARGO pushBack _x;
				};
			} foreach soldiers;
			{
				soldiers deleteAt (soldiers find _x);
			} foreach PLAYER_CARGO;
		};
	};
};
getNewSpawnPos = {
	private _pos = _this getPos [random 10, random 360];
	_pos set [2, ((getPosATL _this) select 2) + 0.9];
	_pos;
};
_spawnList = [
	[[10416.3,17493.5,0.5,0],[9548.99,14088.4,0,0],[6589.63,15906.5,0,0]], //AgiosDionysios
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
_propList = [
	["Land_i_Addon_03mid_V1_F", [0,0,0], 0],
	["Land_i_Addon_03_V1_F", [-0.01,-7.411,-0.909], 0],
	["Land_i_Addon_04_V1_F", [-0.01,6.662,-0.909], 180],
	["Land_CampingTable_F", [3.5,8.5,-0.0124245], 0],
	["MapBoard_altis_F", [-1,8.5,-0.0121918], 330]
];
_laptop = ["Land_Laptop_03_black_F", [3.5,8.5,0.801048], 0];

//main = [[13671,15027,0], 30, _propList] call rebuildComposition;

removeAllWeapons player;
player allowDamage false;

_towns = [];
{
	_towns pushBack (configFile >> "CfgWorlds" >> "Altis" >> "Names" >> _x);
} foreach ["AgiosDionysios","Athira","Chalkeia","Charkia","Kavala","Neochori","Paros","Pyrgos","Sofia","Zaros"];
	
player setPosATL [14648.7,16748.9,0];
player setDir 326.641;

spawnGuy allowDamage false;
removeBackpack spawnGuy;
spawnGuy addAction [
	"Reset Selection", {
		missionNamespace setVariable ["SELECTED_TOWN", ""];
		missionNamespace setVariable ["SELECTED_SIDE", ""];
	},_currentName,1,false,true,"",
	"(missionNamespace getVariable ['SELECTED_TOWN','']) != ''"
];

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

//execVM "DE_diagnostic.sqf";