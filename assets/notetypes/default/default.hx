// THIS SCRIPT DOESN'T WORK YET, IT'S HERE FOR TESTING PURPOSES!!!!
function generateNote()
{
	var framesArg:String = 'NOTE_assets';
	var noteSkin:String = Init.trueSettings.get('Note Skin');

	if (newNote.isSustainNote)
	{
		var skinAssetPath:String = ForeverTools.returnSkinAsset(framesArg, assetModifier, changeable, 'default/skins', '');
		newNote.loadGraphic(Paths.image(skinAssetPath, 'notetypes'), true, 7, 6);
		newNote.animation.add(Receptor.colors[newNote.noteData] + 'holdend', [pixelData[newNote.noteData]]);
		newNote.animation.add(Receptor.colors[newNote.noteData] + 'hold', [pixelData[newNote.noteData] - 4]);
	}
	else
	{
		var skinAssetPath:String = ForeverTools.returnSkinAsset(framesArg, assetModifier, changeable, 'default/skins', '');
		newNote.loadGraphic(Paths.image(skinAssetPath, 'notetypes'), true, 17, 17);
		newNote.animation.add(Receptor.colors[newNote.noteData] + 'Scroll', [pixelData[newNote.noteData]], 12);
	}
}
