package meta.data;

// stores typedefs for song info and such;

/*
	[LEGACY] Song Format, from Friday Night Funkin' v0.2.7.1/0.2.8;
 */
typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var noteSkin:String;
	var splashSkin:String;
	var assetModifier:String;
	var validScore:Bool;

	@:optional public dynamic function copy():SwagSong;
}

/*
	[LEGACY] Section Format, from Friday Night Funkin' v0.2.7.1/0.2.8;
 */
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

/*
	Timed Event Format;
 */
typedef TimedEvent =
{
	public var strumTime:Float;
	public var event:String;
	public var val1:String;
	public var val2:String;
	public var val3:String;
	@:optional public var color:Array<Int>;
}
