function generateReceptor(receptor)
{
	var stringSect:String = Receptor.actions[receptor.strumData];

	receptor.frames = Paths.getSparrowAtlas(getSkinPath(), 'notetypes');

	receptor.animation.addByPrefix('static', 'arrow' + stringSect.toUpperCase());
	receptor.animation.addByPrefix('pressed', stringSect + ' press', 24, false);
	receptor.animation.addByPrefix('confirm', stringSect + ' confirm', 24, false);

	receptor.setGraphicSize(Std.int(receptor.width * 0.7));
	receptor.antialiasing = true;

	var offsetMiddleX = 0;
	var offsetMiddleY = 0;
	if (receptor.strumData > 0 && receptor.strumData < 3)
	{
		offsetMiddleX = 2;
		offsetMiddleY = 2;
		if (receptor.strumData == 1)
		{
			offsetMiddleX -= 1;
			offsetMiddleY += 2;
		}
	}

	receptor.addOffset('static');
	receptor.addOffset('pressed', -2, -2);
	receptor.addOffset('confirm', 36 + offsetMiddleX, 36 + offsetMiddleY);
}

function generateNote(newNote)
{
	var stringSect = Receptor.colors[newNote.noteData];

	newNote.frames = Paths.getSparrowAtlas(getSkinPath(), 'notetypes');
	newNote.animation.addByPrefix(stringSect + 'Scroll', stringSect + '0');

	newNote.setGraphicSize(Std.int(newNote.width * 0.7));
	newNote.antialiasing = true;
	newNote.updateHitbox();
}

function generateSustain(newNote)
{
	newNote.frames = Paths.getSparrowAtlas(getSkinPath(), 'notetypes');
	newNote.animation.addByPrefix(stringSect + 'holdend', stringSect + ' hold end');
	newNote.animation.addByPrefix(stringSect + 'hold', stringSect + ' hold piece');
	newNote.animation.addByPrefix('purpleholdend', 'pruple end hold'); // PA god dammit.

	newNote.setGraphicSize(Std.int(newNote.width * 0.7));
	newNote.antialiasing = true;
	newNote.updateHitbox();
}

function generateSplash(noteSplash, noteData)
{
	var skin = Init.trueSettings.get("Note Skin");
	var ui = Init.trueSettings.get("UI Skin");

	if (ui == "forever")
	{
		noteSplash.loadGraphic(Paths.image(getSkinPath('noteSplashes'), 'notetypes'), true, 210, 210);
		noteSplash.animation.add('anim1', [
			(noteData * 2 + 1),
			8 + (noteData * 2 + 1),
			16 + (noteData * 2 + 1),
			24 + (noteData * 2 + 1),
			32 + (noteData * 2 + 1)
		], 24, false);
		noteSplash.animation.add('anim2', [
			(noteData * 2),
			8 + (noteData * 2),
			16 + (noteData * 2),
			24 + (noteData * 2),
			32 + (noteData * 2)
		], 24, false);
		noteSplash.addOffset('anim1', -20, -10);
		noteSplash.addOffset('anim2', -20, -10);
	}
	else
	{
		noteSplash.frames = Paths.getSparrowAtlas(getSkinPath('noteSplashesOG'), 'notetypes');
		noteSplash.animation.addByPrefix('anim1', 'note impact 1 ' + Receptor.colors[noteData], 24, false);
		noteSplash.animation.addByPrefix('anim2', 'note impact 2 ' + Receptor.colors[noteData], 24, false);
		noteSplash.animation.addByPrefix('anim1', 'note impact 1  blue', 24, false); // HE DID IT AGAIN EVERYONE;

		noteSplash.addOffset('anim1', 10, 30);
		noteSplash.addOffset('anim2', 10, 30);
		noteSplash.updateHitbox();
		noteSplash.animation.play('anim1');
	}
}

function getSkinPath(?forceSkin:String):String
	return ForeverTools.returnSkinAsset(forceSkin == null ? 'NOTE_assets' : forceSkin, 'base', Init.trueSettings.get("Note Skin"), 'default/skins', 'default');
