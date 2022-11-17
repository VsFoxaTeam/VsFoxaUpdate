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

function getSkinPath(?forceSkin:String):String
	return ForeverTools.returnSkinAsset(forceSkin == null ? 'NOTE_assets' : forceSkin, 'base', Init.trueSettings.get("Note Skin"), 'default/skins', 'default');
