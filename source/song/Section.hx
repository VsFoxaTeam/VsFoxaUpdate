package song;

import song.SongInfo.SwagSection;

class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var lengthInSteps:Int = 16;
	public var sectionBeats:Float = 4;
	public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(lengthInSteps:Int = 16, sectionBeats:Float = 4)
	{
		this.lengthInSteps = lengthInSteps;
		this.sectionBeats = sectionBeats;
	}
}
