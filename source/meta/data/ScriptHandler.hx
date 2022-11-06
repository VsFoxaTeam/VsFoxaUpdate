package meta.data;

using StringTools;

class ScriptHandler extends SScript
{
	// this just kinda sets up script variables and such;
	// probably gonna clean it up later;
	public function new(file:String, ?preset:Bool = true)
	{
		super(file, preset);
		traces = false;
	}

	override public function preset():Void
	{
		super.preset();

		// CLASSES (FLIXEL);
		set('FlxG', flixel.FlxG);
		set('FlxBasic', flixel.FlxBasic);
		set('FlxObject', flixel.FlxObject);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);

		// CLASSES (FUNKIN);
		set('Boyfriend', gameObjects.Boyfriend);
		set('Character', gameObjects.Character);
		set('Conductor', meta.data.Conductor);
		set('HealthIcon', gameObjects.userInterface.HealthIcon);
		set('Paths', Paths);

		// CLASSES (FOREVER);
		set('Init', Init);
		set('Main', Main);
		set('Stage', gameObjects.Stage);
		set('FNFSprite', meta.data.dependency.FNFSprite);
		set('ForeverAssets', ForeverAssets);
		set('ForeverTools', ForeverTools);
	}

	public static function callScripts(moduleArray:Array<ScriptHandler>):Array<ScriptHandler>
	{
		var dirs:Array<Array<String>> = [
			CoolUtil.absoluteDirectory('scripts'),
			CoolUtil.absoluteDirectory('songs/${CoolUtil.swapSpaceDash(meta.state.PlayState.SONG.song.toLowerCase())}')
		];

		var pushedModules:Array<String> = [];

		for (directory in dirs)
		{
			for (script in directory)
			{
				if (directory != null && directory.length > 0)
				{
					for (ext in Paths.scriptExts)
					{
						if (!pushedModules.contains(script) && script != null && script.endsWith('.$ext'))
						{
							pushedModules.push(script);
							moduleArray.push(new ScriptHandler(script));
							trace('new module loaded: ' + script);
						}
					}
				}
			}
		}

		if (moduleArray != null)
		{
			for (i in moduleArray)
				i.call('create', []);
		}

		return moduleArray;
	}
}
