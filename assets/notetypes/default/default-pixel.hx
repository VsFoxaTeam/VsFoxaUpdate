function generateReceptor(receptor)
{
	receptor.loadGraphic(Paths.image(getSkinPath(false), 'notetypes'), true, 17, 17);
	receptor.animation.add('static', [receptor.strumData]);
	receptor.animation.add('pressed', [4 + receptor.strumData, 8 + receptor.strumData], 12, false);
	receptor.animation.add('confirm', [12 + receptor.strumData, 16 + receptor.strumData], 24, false);

	receptor.setGraphicSize(Std.int(receptor.width * PlayState.daPixelZoom));
	receptor.updateHitbox();
	receptor.antialiasing = false;

	receptor.addOffset('static', -67, -50);
	receptor.addOffset('pressed', -67, -50);
	receptor.addOffset('confirm', -67, -50);
}

function generateNote(newNote)
{
	var pixelData:Array<Int> = [4, 5, 6, 7];

	newNote.loadGraphic(Paths.image(getSkinPath(false), 'notetypes'), true, 17, 17);
	newNote.animation.add(Receptor.colors[newNote.noteData] + 'Scroll', [pixelData[newNote.noteData]], 12);
	newNote.animation.play(Receptor.colors[newNote.noteData] + 'Scroll');

	newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
	newNote.updateHitbox();
}

function generateSustain(newNote)
{
	var pixelData:Array<Int> = [4, 5, 6, 7];

	newNote.loadGraphic(Paths.image(getSkinPath(true), 'notetypes'), true, 7, 6);
	newNote.animation.add(Receptor.colors[newNote.noteData] + 'holdend', [pixelData[newNote.noteData]]);
	newNote.animation.add(Receptor.colors[newNote.noteData] + 'hold', [pixelData[newNote.noteData] - 4]);
	newNote.animation.play(Receptor.colors[newNote.noteData] + 'holdend');

	newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
	newNote.updateHitbox();
}

function getSkinPath(isSustain:Bool, ?forceSkin:String):String
	return ForeverTools.returnSkinAsset(forceSkin == null ?isSustain?'arrowEnds', 'arrows-pixels':forceSkin, 'base', Init.trueSettings.get("Note Skin"),
		'default/skins', 'default');
