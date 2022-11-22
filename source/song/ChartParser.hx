package song;

import flixel.util.FlxSort;
import gameObjects.Note;
import song.SongFormat.SwagSong;
import song.SongFormat.TimedEvent;
import states.PlayState;

/**
	This is the Chart Parser class. it loads in charts, but also exports charts, the chart parameters are based on the type of chart, 
	say the base game type loads the base game's charts, the forever chart type loads a custom forever structure chart with custom features,
	and so on. This class will handle both saving and loading of charts with useful features and scripts that will make things much easier
	to handle and load, as well as much more modular!
**/
class ChartParser
{
	// hopefully this makes it easier for people to load and save chart features and such, y'know the deal lol
	public static function parseBaseChart(songData:SwagSong):Array<Note>
	{
		return try
		{
			var unspawnNotes:Array<Note> = [];

			for (section in songData.notes)
			{
				var coolSection:Int = Std.int(section.lengthInSteps / 4);

				for (songNotes in section.sectionNotes)
				{
					var daStrumTime:Float = #if !neko songNotes[0] - Init.trueSettings['Offset'] /* - | late, + | early */ #else songNotes[0] #end;
					var daNoteData:Int = Std.int(songNotes[1] % 4);
					// define the note's animation (in accordance to the original game)!
					var daNoteAlt:Float = 0;
					var daNoteType:String = 'default';

					// psych conversion;
					switch (songNotes[3])
					{
						case "Hurt Note":
							songNotes[3] = 'mine';
						case "Hey!":
							songNotes[3] = 'default';
							songNotes[5] = 'hey'; // animation;
						case 'Alt Animation':
							songNotes[3] = 'default';
							songNotes[4] = '-alt'; // animation string;
						case "GF Sing":
							songNotes[3] = 'default';
					}

					// define the note's type if it is a string;
					if (songNotes[3] != null && Std.isOfType(songNotes[3], String))
						daNoteType = songNotes[3];

					// check the base section
					var gottaHitNote:Bool = section.mustHitSection;

					// if the note is on the other side, flip the base section of the note
					if (songNotes[1] > 3)
						gottaHitNote = !section.mustHitSection;

					// define the note that comes before (previous note)
					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					// create the new note
					var swagNote:Note = ForeverAssets.generateArrow(null, PlayState.assetModifier, daStrumTime, daNoteData, daNoteAlt, daNoteType);

					swagNote.noteType = daNoteType;
					swagNote.noteSpeed = songData.speed;
					swagNote.mustPress = gottaHitNote;

					// set animation parameters for notes!
					swagNote.noteSuffix = songNotes[4];
					swagNote.noteString = songNotes[5];
					swagNote.noteTimer = songNotes[6];

					if (swagNote.noteData > -1) // don't push notes if they are an event??
						unspawnNotes.push(swagNote);

					// set the note's length (sustain note)
					swagNote.sustainLength = songNotes[2];
					if (swagNote.sustainLength > 0)
						swagNote.sustainLength = Math.round(swagNote.sustainLength / Conductor.stepCrochet) * Conductor.stepCrochet;
					swagNote.scrollFactor.set(0, 0);

					if (swagNote.sustainLength > 0)
					{
						var floorSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet);
						if (floorSus > 0)
						{
							if (floorSus == 1)
								floorSus++;
							for (susNote in 0...floorSus)
							{
								oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

								var sustainNote:Note = ForeverAssets.generateArrow(null, PlayState.assetModifier,
									daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, daNoteAlt, daNoteType, true, oldNote);
								sustainNote.mustPress = gottaHitNote;
								sustainNote.scrollFactor.set();

								if (sustainNote != null)
									unspawnNotes.push(sustainNote);
							}
						}
					}
				}
			}

			// sort notes before returning them;
			unspawnNotes.sort(function(Obj1:Note, Obj2:Note):Int
			{
				return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
			});

			return unspawnNotes;
		}
		catch (e)
		{
			trace("Chart Parsing Error: " + e);
			return [];
		}
	}

	public static function parseEvents(events:Array<Array<Dynamic>>):Array<TimedEvent>
	{
		return try
		{
			var timedEvents:Array<TimedEvent> = [];
			for (i in events)
			{
				var newEvent:TimedEvent = cast {
					strumTime: i[0],
					event: i[1][0][0],
					val1: i[1][0][1],
					val2: i[1][0][2],
					val3: i[1][0][3]
				};
				timedEvents.push(newEvent);
			}
			if (timedEvents.length > 1)
			{
				timedEvents.sort(function(Obj1:TimedEvent, Obj2:TimedEvent):Int
				{
					return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
				});
			}
			timedEvents;
		}
		catch (e)
		{
			[];
		}
	}
}
