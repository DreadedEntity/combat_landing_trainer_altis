/////////////////////////////////////
// Function file for Armed Assault //
//    Created by: DreadedEntity    //
/////////////////////////////////////

getHexColor = //takes a number between 0-100 and converts it to a useable color.
{ //Starting from 0, green is at maximum and as the number goes up, more red is added. After 50, red is at maximum and green is lessened
//This has a cool transition effect from green to yellow to orange to red
	private ["_damage","_output","_redDec","_greenDec"];
	_damage = _this;
	_output = "";
	
	_redDec = 0;
	_greenDec = 0;
	
	if (_damage > 50) then
	{
		_greenDec = 255 - (round ((_damage - 50) * 5.1));
		_redDec = 255;
	}else
	{
		_redDec = round (_damage * 5.1);
		_greenDec = 255;
	};
	(_redDec call conDecNum) + (_greenDec call conDecNum) + "00";
};

conDecNum = //converts 0-255 into hex numbers (00-FF)
{
	private ["_conversion","_number","_hex","_buf","_buf2"];
	_conversion = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"];
	_number = _this;
	_buf = floor (_number / 16);
	_buf2 = _number - (_buf * 16);
	format ["%1%2",_conversion select _buf, _conversion select _buf2];
};

while {true} do
{
	waitUntil {!isNull cursorTarget};
	_script = [typeOf cursorTarget, cursorTarget] spawn
	{
		while {!isNull cursorTarget} do
		{
			_mainCFG = (configfile >> "CfgVehicles" >> _this select 0 >> "HitPoints");
			_allHitPoints = _mainCFG call BIS_fnc_getCfgSubClasses;
			_hint = composeText ["Diagnostic Tool:",lineBreak];
			_notFound = "";
			{
				_name = getText (_mainCFG >> _x >> "name");
				_damage = (_this select 1) getHit _name;
				if (!isNil "_damage") then
				{
					_hint = composeText [_hint,lineBreak];
					_hint = composeText [_hint, parseText (format ["<t color='#%1'>%2: %3%4</t>", (_damage * 100) call getHexColor, _x, (abs(_damage - 1) * 100), "%"])];
				}else
				{
					_notFound = composeText [_notFound, lineBreak];
					_notFound = composeText [_notFound, parseText (format ["<t color='#00FFFF'>%1: %2</t>", _x, "NOT FOUND"])];
				};
			}forEach _allHitPoints;
			hintSilent composeText [_hint,_notFound];
		};
	};
	waitUntil {scriptDone _script};
	hintSilent "";
};