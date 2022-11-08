function eventPreload(params)
{
	var char:Character = new Character(false);
	char.setCharacter(0, 0, params[1]);
	PlayState.characterGroup.add(char);
}

function eventNoteHit(params)
{
	var changeTimer:FlxTimer;
	var timer:Float = Std.parseFloat(params[2]);
	if (Math.isNaN(timer))
		timer = 0;

	changeTimer = new FlxTimer().start(timer, function(tmr:FlxTimer)
	{
		switch (params[0])
		{
			case 'bf', 'boyfriend', 'player', '0':
				PlayState.boyfriend.setCharacter(770, 450, params[1]);
				PlayState.uiHUD.iconP1.updateIcon(params[1], true);
				PlayState.boyfriend.dance(true);
			case 'gf', 'girlfriend', 'spectator', '2':
				PlayState.gf.setCharacter(300, 100, params[1]);
				PlayState.gf.dance(true);
			default:
				PlayState.opponent.setCharacter(100, 100, params[1]);
				PlayState.uiHUD.iconP2.updateIcon(params[1], false);
				PlayState.opponent.dance(true);
		}
		PlayState.uiHUD.reloadHealthBar();
	});
}

function returnDescription()
	return
		"Sets the current Character to a new one\nValue 1: Character to change (dad, bf, gf, defaults to dad)\nValue 2: New character's name\nValue 3: Delay to Change Characters (in Milliseconds)";

function returnValue3()
	return true;
