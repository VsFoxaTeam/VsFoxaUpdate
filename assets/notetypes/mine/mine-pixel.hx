function generateNote(newNote)
{
	var framesArg:String = 'mines';
	if (newNote.isSustainNote)
		newNote.kill();
	else
	{
		newNote.loadGraphic(Paths.image(ForeverTools.returnSkin('mines', 'pixel', '', 'mine/skins', 'notetypes')), true, 133, 128);
		newNote.animation.add(Receptor.actions[newNote.noteData] + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12);
	}
}
