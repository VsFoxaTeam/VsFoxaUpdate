package states;

import base.feather.ScriptHandler;
import song.MusicBeat.MusicBeatState;
import flixel.FlxBasic;
import flixel.FlxSubState;

/**
 * Here's a Custom Class for Scripts, you can customize it to your liking and add your own features to it!
**/
class ScriptableState extends MusicBeatState
{
	var stateScript:ScriptHandler;

	override public function new(className:String):Void
	{
		super();

		// here we actually create the main script
		stateScript = new ScriptHandler(Paths.module('states/$className'));
		stateScript.call('new', [className]);
		stateScript.set('controls', controls);
		stateScript.set('this', this);
		stateScript.set('add', add);
		stateScript.set('remove', remove);
		stateScript.set('kill', kill);
		stateScript.set('updatePresence', function(detailsTop:String, subDetails:String, ?iconRPC:String, ?updateTime:Bool = false, time:Float)
		{
			#if DISCORD_RPC
			dependency.Discord.changePresence(detailsTop, subDetails, iconRPC, updateTime, time);
			#end
		});
	}

	override public function create():Void
	{
		stateScript.call('create', []);
		super.create();
		stateScript.call('postCreate', []);
	}

	override public function update(elapsed:Float)
	{
		stateScript.call('update', [elapsed]);
		super.update(elapsed);
		stateScript.call('postUpdate', [elapsed]);
	}

	override public function beatHit():Void
	{
		super.beatHit();
		stateScript.call('beatHit', [curBeat]);
		stateScript.set('curBeat', curBeat);
	}

	override public function stepHit():Void
	{
		super.stepHit();
		stateScript.call('stepHit', [curStep]);
		stateScript.set('curStep', curStep);
	}

	override public function onFocus():Void
	{
		stateScript.call('onFocus', []);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		stateScript.call('onFocusLost', []);
		super.onFocusLost();
	}

	override public function destroy():Void
	{
		stateScript.call('destroy', []);
		super.destroy();
	}

	override function openSubState(SubState:FlxSubState):Void
	{
		stateScript.call('openSubState', []);
		super.openSubState(SubState);
	}

	override function closeSubState():Void
	{
		stateScript.call('closeSubState', []);
		super.closeSubState();
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, flixel.FlxSprite))
			cast(Object, flixel.FlxSprite).antialiasing = false;
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, flixel.text.FlxText))
			cast(Object, flixel.text.FlxText).antialiasing = false;
		return super.add(Object);
	}
}
