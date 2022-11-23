package dependency;

import flixel.FlxGame;
import flixel.FlxState;

class FNFGame extends FlxGame
{
	public function forceSwitch(next:FlxState)
	{
		_requestedState = next;
		switchState();
	}
}
