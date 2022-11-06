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

		// CLASSES (FUNKIN);
		set('Boyfriend', gameObjects.Boyfriend);
		set('Character', gameObjects.Character);
		set('Conductor', meta.data.Conductor);
		set('FNFSprite', meta.data.dependency.FNFSprite);
		set('HealthIcon', gameObjects.userInterface.HealthIcon);
		set('Stage', gameObjects.Stage);

		// CLASSES (FOREVER);
		set('Init', Init);
		set('ForeverAssets', ForeverAssets);
		set('ForeverTools', ForeverTools);
		set('Paths', Paths);
	}
}
