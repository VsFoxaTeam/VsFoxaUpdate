package states.menus;

import flixel.FlxG;
import gameObjects.gameFonts.Alphabet;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import states.data.BaseOptions;

class OptionsMenu extends BaseOptions
{
	override public function create()
	{
		super.create();

		var bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		bg.scrollFactor.set(0, 0.18);
		bg.color = 0xD8B168;
		bg.antialiasing = true;
		add(bg);

		generateOptions(categoriesMap.get("main"));
		updateSelections();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// typical controls array tomfoolery
		var up = Controls.getPressEvent("ui_up", "pressed");
		var down = Controls.getPressEvent("ui_down", "pressed");
		var up_p = Controls.getPressEvent("ui_up");
		var down_p = Controls.getPressEvent("ui_down");
		var controlArray:Array<Bool> = [up, down, up_p, down_p];

		if ((controlArray.contains(true)) && (!lockedMovement))
		{
			for (i in 0...controlArray.length)
			{
				// here we check which keys are pressed
				if (controlArray[i] == true)
				{
					// if single press
					if (i > 1)
					{
						// up == 2 - down == 3
						if (i == 2)
							updateSelections(-1);
						else if (i == 3)
							updateSelections(1);

						FlxG.sound.play(Paths.sound('base/menus/scrollMenu'));
					}
				}
				//
			}
		}

		var optionText = alphabetGroup.members[curSelected].text;

		if (Controls.getPressEvent("accept"))
		{
			if (activeGroup[curSelected].type == "keybinds")
			{
				//
				FlxG.sound.play(Paths.sound('base/menus/scrollMenu'));
				openSubState(new states.substates.OptionsSubstate());
				updateSelections();
			}
			else if (activeGroup[curSelected].type == "subgroup")
			{
				FlxG.sound.play(Paths.sound('base/menus/scrollMenu'));
				switchCategory(optionText.toLowerCase());
				updateSelections();
			}
		}

		if (Init.gameSettings.get(optionText) != null)
		{
			switch (Init.gameSettings.get(optionText)[1])
			{
				case Init.SettingTypes.Checkmark:
					if (Controls.getPressEvent("accept"))
						updateCheckmarks();
				case Init.SettingTypes.Selector:
					updateSelectors();
			}
		}

		if (Controls.getPressEvent("back"))
		{
			FlxG.sound.play(Paths.sound('base/menus/cancelMenu'));
			if (curCategory != 'main')
			{
				switchCategory('main');
				updateSelections();
			}
			else
			{
				if (states.substates.PauseSubstate.toOptions)
					Main.switchState(this, new PlayState());
				else
					Main.switchState(this, new MainMenu());
			}
		}
	}
}
