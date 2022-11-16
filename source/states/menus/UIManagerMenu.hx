package states.menus;

import dependency.FNFSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import gameObjects.Boyfriend;
import gameObjects.Character;
import gameObjects.Stage;

/**
	Unifies UI Options (e.g: UI Skin, Note Skin, Simply Judgements, etc) into a single class;
	with a neat little editor of sorts;
**/
class UIManagerMenu extends MusicBeatState
{
	public var gameStage:Stage;

	public var boyfriend:Boyfriend;
	public var opponent:Character;
	public var gf:Character;

	public var world:FlxCamera;
	public var ui:FlxCamera;

	public var judgement:FNFSprite;
	public var comboNum:FlxSpriteGroup;

	override function create()
	{
		super.create();

		// initialize cameras;
		world = new FlxCamera();
		FlxG.cameras.reset(world);

		ui = new FlxCamera();
		ui.bgColor.alpha = 0;
		FlxG.cameras.add(ui, false);

		FlxG.cameras.setDefaultDrawTarget(world, true);

		// initialize main elements;
		gameStage = new Stage('stage');
		add(gameStage);

		gf.setCharacter(300, 100, 'gf');
		gf.scrollFactor.set(0.95, 0.95);

		opponent.setCharacter(100, 100, 'dad');
		boyfriend.setCharacter(770, 450, 'bf');

		add(gf);
		add(opponent);
		add(boyfriend);

		// force them to dance
		opponent.dance();
		gf.dance();
		boyfriend.dance();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Controls.getPressEvent("back"))
			Main.switchState(this, new OptionsMenu());
	}
}
