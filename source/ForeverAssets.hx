package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import gameObjects.userInterface.*;
import gameObjects.userInterface.menu.*;
import gameObjects.userInterface.notes.*;
import gameObjects.userInterface.notes.Strumline.Receptor;
import meta.data.Conductor;
import meta.data.SongInfo.SwagSection;
import meta.data.Timings;
import meta.state.PlayState;

using StringTools;

/**
	Forever Assets is a class that manages the different asset types, basically a compilation of switch statements that are
	easy to edit for your own needs. Most of these are just static functions that return information
**/
class ForeverAssets
{
	//
	public static function generateCombo(asset:String, number:String, allSicks:Bool, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String, negative:Bool, createdColor:FlxColor, scoreInt:Int):FlxSprite
	{
		var width = 100;
		var height = 140;

		if (assetModifier == 'pixel')
		{
			width = 10;
			height = 12;
		}
		var newSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary)),
			true, width, height);
		switch (assetModifier)
		{
			default:
				newSprite.alpha = 1;
				newSprite.screenCenter();
				newSprite.x += (43 * scoreInt) + 20;
				newSprite.y += 60;

				newSprite.color = FlxColor.WHITE;
				if (negative)
					newSprite.color = createdColor;

				newSprite.animation.add('base', [
					(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!allSicks ? 0 : 11)
				], 0, false);
				newSprite.animation.play('base');
		}

		if (assetModifier == 'pixel')
			newSprite.setGraphicSize(Std.int(newSprite.width * PlayState.daPixelZoom));
		else
		{
			newSprite.antialiasing = true;
			newSprite.setGraphicSize(Std.int(newSprite.width * 0.5));
		}
		newSprite.updateHitbox();
		if (!Init.trueSettings.get('Simply Judgements'))
		{
			newSprite.acceleration.y = FlxG.random.int(200, 300);
			newSprite.velocity.y = -FlxG.random.int(140, 160);
			newSprite.velocity.x = FlxG.random.float(-5, 5);
		}

		return newSprite;
	}

	public static function generateRating(asset:String, perfectSick:Bool, timing:String, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String):FlxSprite
	{
		var width = 500;
		var height = 163;
		if (assetModifier == 'pixel')
		{
			width = 72;
			height = 32;
		}
		var rating:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ForeverTools.returnSkinAsset('judgements', assetModifier, changeableSkin,
			baseLibrary)), true, width, height);
		switch (assetModifier)
		{
			default:
				rating.alpha = 1;
				rating.screenCenter();
				rating.x = (FlxG.width * 0.55) - 40;
				rating.y -= 60;
				if (!Init.trueSettings.get('Simply Judgements'))
				{
					rating.acceleration.y = 550;
					rating.velocity.y = -FlxG.random.int(140, 175);
					rating.velocity.x = -FlxG.random.int(0, 10);
				}
				rating.animation.add('base', [
					Std.int((Timings.judgementsMap.get(asset)[0] * 2) + (perfectSick ? 0 : 2) + (timing == 'late' ? 1 : 0))
				], 24, false);
				rating.animation.play('base');
		}

		if (assetModifier == 'pixel')
			rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.7));
		else
		{
			rating.antialiasing = true;
			rating.setGraphicSize(Std.int(rating.width * 0.7));
		}

		return rating;
	}

	public static function generateNoteSplashes(asset:String, assetModifier:String = 'base', changeableSkin:String = 'default', baseLibrary:String,
			noteData:Int):NoteSplash
	{
		//
		var tempSplash:NoteSplash = new NoteSplash(noteData);
		switch (assetModifier)
		{
			case 'pixel':
				tempSplash.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('splash-pixel', assetModifier, changeableSkin, baseLibrary)), true, 34, 34);
				tempSplash.animation.add('anim1', [noteData, 4 + noteData, 8 + noteData, 12 + noteData], 24, false);
				tempSplash.animation.add('anim2', [16 + noteData, 20 + noteData, 24 + noteData, 28 + noteData], 24, false);
				tempSplash.animation.play('anim1');
				tempSplash.addOffset('anim1', -120, -90);
				tempSplash.addOffset('anim2', -120, -90);
				tempSplash.setGraphicSize(Std.int(tempSplash.width * PlayState.daPixelZoom));

			default:
				// 'UI/$assetModifier/notes/noteSplashes'
				tempSplash.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('noteSplashes', assetModifier, changeableSkin, baseLibrary)), true, 210, 210);
				tempSplash.animation.add('anim1', [
					(noteData * 2 + 1),
					8 + (noteData * 2 + 1),
					16 + (noteData * 2 + 1),
					24 + (noteData * 2 + 1),
					32 + (noteData * 2 + 1)
				], 24, false);
				tempSplash.animation.add('anim2', [
					(noteData * 2),
					8 + (noteData * 2),
					16 + (noteData * 2),
					24 + (noteData * 2),
					32 + (noteData * 2)
				], 24, false);
				tempSplash.animation.play('anim1');
				tempSplash.addOffset('anim1', -20, -10);
				tempSplash.addOffset('anim2', -20, -10);
		}

		return tempSplash;
	}

	public static function generateUIArrows(x:Float, y:Float, ?receptorData:Int = 0, framesArg:String, assetModifier:String):Receptor
	{
		var uiReceptor:Receptor = new Receptor(x, y, receptorData);
		switch (assetModifier)
		{
			case 'pixel':
				// look man you know me I fucking hate repeating code
				// not even just a cleanliness thing it's just so annoying to tweak if something goes wrong like
				// genuinely more programmers should make their code more modular
				uiReceptor.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('arrows-pixels', assetModifier, Init.trueSettings.get("Note Skin"),
					'noteskins/notes')), true,
					17, 17);
				uiReceptor.animation.add('static', [receptorData]);
				uiReceptor.animation.add('pressed', [4 + receptorData, 8 + receptorData], 12, false);
				uiReceptor.animation.add('confirm', [12 + receptorData, 16 + receptorData], 24, false);

				uiReceptor.setGraphicSize(Std.int(uiReceptor.width * PlayState.daPixelZoom));
				uiReceptor.updateHitbox();
				uiReceptor.antialiasing = false;

				uiReceptor.addOffset('static', -67, -50);
				uiReceptor.addOffset('pressed', -67, -50);
				uiReceptor.addOffset('confirm', -67, -50);

			case 'chart editor':
				uiReceptor.loadGraphic(Paths.image('UI/forever/base/chart editor/note_array'), true, 157, 156);
				uiReceptor.animation.add('static', [receptorData]);
				uiReceptor.animation.add('pressed', [16 + receptorData], 12, false);
				uiReceptor.animation.add('confirm', [4 + receptorData, 8 + receptorData, 16 + receptorData], 24, false);

				uiReceptor.addOffset('static');
				uiReceptor.addOffset('pressed');
				uiReceptor.addOffset('confirm');

			default:
				// probably gonna revise this and make it possible to add other arrow types but for now it's just pixel and normal
				var stringSect:String = '';
				// call arrow type I think
				stringSect = Receptor.getArrowFromNumber(receptorData);

				uiReceptor.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset('$framesArg', assetModifier, Init.trueSettings.get("Note Skin"),
					'noteskins/notes'));

				uiReceptor.animation.addByPrefix('static', 'arrow' + stringSect.toUpperCase());
				uiReceptor.animation.addByPrefix('pressed', stringSect + ' press', 24, false);
				uiReceptor.animation.addByPrefix('confirm', stringSect + ' confirm', 24, false);

				uiReceptor.antialiasing = true;
				uiReceptor.setGraphicSize(Std.int(uiReceptor.width * 0.7));

				// set little offsets per note!
				// so these had a little problem honestly and they make me wanna off(set) myself so the middle notes basically
				// have slightly different offsets than the side notes (which have the same offset)

				var offsetMiddleX = 0;
				var offsetMiddleY = 0;
				if (receptorData > 0 && receptorData < 3)
				{
					offsetMiddleX = 2;
					offsetMiddleY = 2;
					if (receptorData == 1)
					{
						offsetMiddleX -= 1;
						offsetMiddleY += 2;
					}
				}

				uiReceptor.addOffset('static');
				uiReceptor.addOffset('pressed', -2, -2);
				uiReceptor.addOffset('confirm', 36 + offsetMiddleX, 36 + offsetMiddleY);
		}

		return uiReceptor;
	}

	/**
		Notes!
	**/
	public static function generateArrow(assetModifier, strumTime, noteData, noteType, noteAlt, ?isSustainNote:Bool = false, ?prevNote:Note = null):Note
	{
		var newNote:Note;
		var changeableSkin:String = Init.trueSettings.get("Note Skin");
		// gonna improve the system eventually
		if (changeableSkin.startsWith('quant'))
			newNote = Note.returnQuantNote(assetModifier, strumTime, noteData, noteType, noteAlt, isSustainNote, prevNote);
		else
			newNote = Note.returnDefaultNote(assetModifier, strumTime, noteData, noteType, noteAlt, isSustainNote, prevNote);

		// hold note shit
		if (isSustainNote && prevNote != null)
		{
			// set note offset
			if (prevNote.isSustainNote)
				newNote.noteVisualOffset = prevNote.noteVisualOffset;
			else // calculate a new visual offset based on that note's width and newnote's width
				newNote.noteVisualOffset = ((prevNote.width / 2) - (newNote.width / 2));
		}

		return newNote;
	}

	/**
		Checkmarks!
	**/
	public static function generateCheckmark(x:Float, y:Float, asset:String, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String)
	{
		var newCheckmark:Checkmark = new Checkmark(x, y);
		switch (assetModifier)
		{
			default:
				newCheckmark.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary));
				newCheckmark.antialiasing = true;

				newCheckmark.animation.addByPrefix('false finished', 'uncheckFinished');
				newCheckmark.animation.addByPrefix('false', 'uncheck', 12, false);
				newCheckmark.animation.addByPrefix('true finished', 'checkFinished');
				newCheckmark.animation.addByPrefix('true', 'check', 12, false);

				// for week 7 assets when they decide to exist
				// animation.addByPrefix('false', 'Check Box unselected', 24, true);
				// animation.addByPrefix('false finished', 'Check Box unselected', 24, true);
				// animation.addByPrefix('true finished', 'Check Box Selected Static', 24, true);
				// animation.addByPrefix('true', 'Check Box selecting animation', 24, false);
				newCheckmark.setGraphicSize(Std.int(newCheckmark.width * 0.7));
				newCheckmark.updateHitbox();

				///*
				var offsetByX = 45;
				var offsetByY = 5;
				newCheckmark.addOffset('false', offsetByX, offsetByY);
				newCheckmark.addOffset('true', offsetByX, offsetByY);
				newCheckmark.addOffset('true finished', offsetByX, offsetByY);
				newCheckmark.addOffset('false finished', offsetByX, offsetByY);
				// */

				// addOffset('true finished', 17, 37);
				// addOffset('true', 25, 57);
				// addOffset('false', 2, -30);
		}
		return newCheckmark;
	}
}
