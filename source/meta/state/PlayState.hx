package meta.state;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import gameObjects.*;
import gameObjects.userInterface.*;
import gameObjects.userInterface.notes.*;
import gameObjects.userInterface.notes.Strumline.Receptor;
import meta.*;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.SongInfo.SwagSong;
import meta.state.charting.*;
import meta.state.menus.*;
import meta.subState.*;
import openfl.display.GraphicsShader;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
import openfl.utils.Assets;
import sys.io.File;

using StringTools;

#if desktop
import meta.data.dependency.Discord;
#end

class PlayState extends MusicBeatState
{
	// for the Countdown;
	public static var startTimer:FlxTimer;

	// for Static Access to this Class;
	public static var main:PlayState;

	// Scripts;
	public static var moduleArray:Array<ScriptHandler> = [];

	// Notes;
	private var unspawnNotes:Array<Note> = [];

	// private var timedEvents:Array<TimedEvent> = [];
	// Song;
	public static var SONG:SwagSong;
	public static var songMusic:FlxSound;
	public static var songLength:Float = 0;
	public static var vocals:FlxSound;

	public var generatedMusic:Bool = false;

	public static var curStage:String = '';

	// Story Mode;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 2;

	// Player;
	public static var songScore:Int = 0;
	public static var campaignScore:Int = 0;
	public static var campaingMisses:Int = 0;
	public static var health:Float = 1; // mario
	public static var combo:Int = 0;
	public static var misses:Int = 0;
	public static var deaths:Int = 0;

	// Characters;
	public static var opponent:Character;
	public static var gf:Character;
	public static var boyfriend:Boyfriend;

	// Custom;
	public static var assetModifier:String = 'base';
	public static var changeableSkin:String = 'default';

	// Discord RPC;
	public static var songDetails:String = "";
	public static var detailsSub:String = "";
	public static var detailsPausedText:String = "";
	public static var iconRPC:String = "";
	public static var storyDifficultyText:String = "";

	// Events;
	public var startingSong:Bool = false;
	public var paused:Bool = false;
	public var startedCountdown:Bool = false;
	public var inCutscene:Bool = false;
	public var canPause:Bool = true;

	// Cameras;
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	public static var camHUD:FlxCamera;
	public static var camGame:FlxCamera;
	public static var dialogueHUD:FlxCamera;

	private static var prevCamFollow:FlxObject;

	public var camDisplaceX:Float = 0;
	public var camDisplaceY:Float = 0; // might not use depending on result

	public static var cameraSpeed:Float = 1;
	public static var defaultCamZoom:Float = 1.05;
	public static var forceZoom:Array<Float>;

	// User Interface and Objects
	public static var uiHUD:ClassHUD;
	public static var daPixelZoom:Float = 6;

	public var stageBuild:Stage;

	// strumlines
	public var dadStrums:Strumline;
	public var bfStrums:Strumline;

	public static var strumLines:FlxTypedGroup<Strumline>;
	public static var strumHUD:Array<FlxCamera> = [];

	// stores all UI Cameras in an array
	private var allUIs:Array<FlxCamera> = [];

	// Other;
	public static var lastRating:FlxSprite;
	public static var lastCombo:Array<FlxSprite>;

	public var gfSpeed:Int = 1;
	public static var preventScoring:Bool = true;

	function resetStatics()
	{
		songScore = 0;
		combo = 0;
		health = 1;
		misses = 0;

		moduleArray = [];
		lastCombo = [];

		defaultCamZoom = 1.05;
		cameraSpeed = 1;
		forceZoom = [0, 0, 0, 0];

		assetModifier = 'base';
		changeableSkin = 'default';

		preventScoring = false;
	}

	function checkTween(isDad:Bool = false):Bool
	{
		if (isDad && Init.trueSettings.get('Centered Notefield'))
			return false;
		// if (skipCountdown)
		//	return false;
		return true;
	}

	// at the beginning of the playstate
	override public function create()
	{
		super.create();

		main = this;

		// reset any values and variables that are static
		resetStatics();

		Timings.callAccuracy();

		// stop any existing music tracks playing
		resetMusic();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// create the game camera
		camGame = new FlxCamera();

		// create the hud camera (separate so the hud stays on screen)
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		allUIs.push(camHUD);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		// default song
		if (SONG == null)
			SONG = Song.loadFromJson('test', 'test');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		curStage = "";
		if (SONG.stage != null)
			curStage = SONG.stage;

		try
		{
			scriptCall();
		}
		catch (e)
		{
			trace('Script Calling Error: $e');
		}

		// cache shit
		displayRating('sick', 'early', true);
		popUpCombo(true);
		//

		stageBuild = new Stage(curStage);
		add(stageBuild);

		if (SONG.gfVersion == null || SONG.gfVersion.length < 1)
			SONG.gfVersion = stageBuild.returnGFtype(curStage);

		// set up characters here too
		gf = new Character();
		gf.adjustPos = false;
		gf.setCharacter(300, 100, SONG.gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		opponent = new Character().setCharacter(50, 850, SONG.player2);
		boyfriend = new Boyfriend();
		boyfriend.setCharacter(750, 850, SONG.player1);

		var camPos:FlxPoint = new FlxPoint(gf.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

		stageBuild.repositionPlayers(curStage, boyfriend, opponent, gf);
		stageBuild.dadPosition(curStage, boyfriend, opponent, gf, camPos);

		if (SONG.assetModifier != null && SONG.assetModifier.length > 1)
			assetModifier = SONG.assetModifier;

		changeableSkin = Init.trueSettings.get("UI Skin");
		if ((curStage.startsWith("school")))
			assetModifier = 'pixel';

		// add characters
		if (stageBuild.spawnGirlfriend)
			add(gf);

		add(stageBuild.layers);

		add(opponent);
		add(boyfriend);

		add(stageBuild.foreground);

		// force them to dance
		opponent.dance();
		gf.dance();
		boyfriend.dance();

		// set song position before beginning
		Conductor.songPosition = -(Conductor.crochet * 4);

		// EVERYTHING SHOULD GO UNDER THIS, IF YOU PLAN ON SPAWNING SOMETHING LATER ADD IT TO STAGEBUILD OR FOREGROUND
		// darken everything but the arrows and ui via a flxsprite
		var darknessBG:FlxSprite = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		darknessBG.alpha = (100 - Init.trueSettings.get('Stage Opacity')) / 100;
		darknessBG.scrollFactor.set(0, 0);
		add(darknessBG);

		// strum setup
		strumLines = new FlxTypedGroup<Strumline>();

		// generate the song
		generateSong(SONG.song);

		// set the camera position to the center of the stage
		camPos.set(gf.x + (gf.frameWidth / 2), gf.y + (gf.frameHeight / 2));

		// create the game camera
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);
		// check if the camera was following someone previously
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);
		add(camFollowPos);

		// actually set the camera up
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		// initialize ui elements
		startingSong = true;
		startedCountdown = true;

		//
		var downscroll = Init.trueSettings.get('Downscroll');
		var centered = Init.trueSettings.get('Centered Notefield');

		var placement = (FlxG.width / 2);
		var height = (downscroll ? FlxG.height - 200 : 0);

		var dadData = opponent.characterData;
		var bfData = boyfriend.characterData;

		dadStrums = new Strumline(placement - (FlxG.width / 4), height, dadData.noteSkin, [opponent], downscroll, false, true, checkTween(true), 4);
		bfStrums = new Strumline(placement + (!centered ? (FlxG.width / 4) : 0), height, bfData.noteSkin, [boyfriend], downscroll, true, false,
			checkTween(false), 4);

		dadStrums.visible = !centered;

		strumLines.add(dadStrums);
		strumLines.add(bfStrums);

		// strumline camera setup
		strumHUD = [];
		for (i in 0...strumLines.length)
		{
			// generate a new strum camera
			strumHUD[i] = new FlxCamera();
			strumHUD[i].bgColor.alpha = 0;

			strumHUD[i].cameras = [camHUD];
			allUIs.push(strumHUD[i]);
			FlxG.cameras.add(strumHUD[i], false);
			// set this strumline's camera to the designated camera
			strumLines.members[i].cameras = [strumHUD[i]];
		}
		add(strumLines);

		uiHUD = new ClassHUD();
		add(uiHUD);
		uiHUD.cameras = [camHUD];

		if (!Init.trueSettings.get('Opaque User Interface'))
		{
			for (text in uiHUD.storedTexts)
				text.alpha = 0.8;

			for (sprite in uiHUD.storedSprites)
				sprite.alpha = 0.8;
		}
		//

		// create a hud over the hud camera for dialogue
		dialogueHUD = new FlxCamera();
		dialogueHUD.bgColor.alpha = 0;
		FlxG.cameras.add(dialogueHUD, false);

		//
		keysArray = [
			copyKey(Init.gameControls.get('LEFT')[0]),
			copyKey(Init.gameControls.get('DOWN')[0]),
			copyKey(Init.gameControls.get('UP')[0]),
			copyKey(Init.gameControls.get('RIGHT')[0])
		];

		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Paths.clearUnusedMemory();

		// call the funny intro cutscene depending on the song
		if (!skipCutscenes())
			songIntroCutscene();
		else
			startCountdown();

		callFunc('postCreate', []);

		/**
		 * SHADERS
		 *
		 * This is a highly experimental code by gedehari to support runtime shader parsing.
		 * Usually, to add a shader, you would make it a class, but now, I modified it so
		 * you can parse it from a file.
		 *
		 * This feature is planned to be used for modcharts
		 * (at this time of writing, it's not available yet).
		 *
		 * This example below shows that you can apply shaders as a FlxCamera filter.
		 * the GraphicsShader class accepts two arguments, one is for vertex shader, and
		 * the second is for fragment shader.
		 * Pass in an empty string to use the default vertex/fragment shader.
		 *
		 * Next, the Shader is passed to a new instance of ShaderFilter, neccesary to make
		 * the filter work. And that's it!
		 *
		 * To access shader uniforms, just reference the `data` property of the GraphicsShader
		 * instance.
		 *
		 * Thank you for reading! -gedehari
		 */

		// Uncomment the code below to apply the effect

		/*
			var shader:GraphicsShader = new GraphicsShader("", File.getContent("./assets/shaders/vhs.frag"));
			FlxG.camera.setFilters([new ShaderFilter(shader)]);
		 */
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	var keysArray:Array<Dynamic>;

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if ((key >= 0)
			&& !bfStrums.autoplay
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || Init.trueSettings.get('Controller Mode'))
			&& (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate)))
		{
			if (generatedMusic)
			{
				var previousTime:Float = Conductor.songPosition;
				Conductor.songPosition = songMusic.time;
				// improved this a little bit, maybe its a lil
				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				bfStrums.allNotes.forEachAlive(function(daNote:Note)
				{
					if ((daNote.noteData == key) && daNote.canBeHit && !daNote.isSustainNote && !daNote.tooLate && !daNote.wasGoodHit)
						possibleNoteList.push(daNote);
				});
				possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				// if there is a list of notes that exists for that control
				if (possibleNoteList.length > 0)
				{
					var eligable = true;
					var firstNote = true;
					// loop through the possible notes
					for (coolNote in possibleNoteList)
					{
						for (noteDouble in pressedNotes)
						{
							if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
								firstNote = false;
							else
								eligable = false;
						}

						if (eligable)
						{
							goodNoteHit(coolNote, bfStrums); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}
					//
				}
				else // else just call bad notes
					if (!Init.trueSettings.get('Ghost Tapping'))
						missNoteCheck(true, key, bfStrums, true);
				Conductor.songPosition = previousTime;
			}

			if (bfStrums.receptors.members[key] != null && bfStrums.receptors.members[key].animation.curAnim.name != 'confirm')
				bfStrums.receptors.members[key].playAnim('pressed');
		}

		callFunc('onKeyPress', []);
	}

	public function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			// receptor reset
			if (key >= 0 && bfStrums.receptors.members[key] != null)
				bfStrums.receptors.members[key].playAnim('static');
		}
		callFunc('onKeyRelease', []);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	override public function destroy()
	{
		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		super.destroy();
	}

	var staticDisplace:Int = 0;

	var lastSection:Int = 0;

	override public function update(elapsed:Float)
	{
		callFunc('update', [elapsed]);

		stageBuild.stageUpdateConstant(elapsed, boyfriend, gf, opponent);

		super.update(elapsed);

		if (health > 2)
			health = 2;

		// dialogue checks
		if (dialogueBox != null && dialogueBox.alive)
		{
			// wheee the shift closes the dialogue
			if (FlxG.keys.justPressed.SHIFT)
				dialogueBox.closeDialog();

			// the change I made was just so that it would only take accept inputs
			if (controls.ACCEPT && dialogueBox.textStarted)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				dialogueBox.curPage += 1;

				if (dialogueBox.curPage == dialogueBox.dialogueData.dialogue.length)
					dialogueBox.closeDialog()
				else
					dialogueBox.updateDialog();
			}
		}

		if (!inCutscene)
		{
			// pause the game if the game is allowed to pause and enter is pressed
			if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
			{
				pauseGame();
			}

			// make sure you're not cheating lol
			if (!isStoryMode)
			{
				// charting state (more on that later)
				if ((FlxG.keys.justPressed.SEVEN) && (!startingSong))
				{
					resetMusic();
					if (FlxG.keys.pressed.SHIFT)
						Main.switchState(this, new ChartingState());
					else
						Main.switchState(this, new OriginalChartingState());
					preventScoring = true;
				}

				if (FlxG.keys.justPressed.SIX)
				{
					preventScoring = true;
					bfStrums.autoplay = !bfStrums.autoplay;
				}
			}

			Conductor.songPosition += elapsed * 1000;
			if (startingSong && startedCountdown && Conductor.songPosition >= 0)
				startSong();

			if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				var curSection = Std.int(curStep / 16);
				if (curSection != lastSection)
				{
					// section reset stuff
					var lastMustHit:Bool = PlayState.SONG.notes[lastSection].mustHitSection;
					if (PlayState.SONG.notes[curSection].mustHitSection != lastMustHit)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
					}
					lastSection = Std.int(curStep / 16);
				}

				if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				{
					var char = opponent;

					var getCenterX = char.getMidpoint().x + 100;
					var getCenterY = char.getMidpoint().y - 100;

					camFollow.setPosition(getCenterX + camDisplaceX + char.characterData.camOffsetX,
						getCenterY + camDisplaceY + char.characterData.camOffsetY);

					if (char.curCharacter == 'mom')
						vocals.volume = 1;
				}
				else
				{
					var char = boyfriend;

					var getCenterX = char.getMidpoint().x - 100;
					var getCenterY = char.getMidpoint().y - 100;
					switch (curStage)
					{
						case 'limo':
							getCenterX = char.getMidpoint().x - 300;
						case 'mall':
							getCenterY = char.getMidpoint().y - 200;
						case 'school':
							getCenterX = char.getMidpoint().x - 200;
							getCenterY = char.getMidpoint().y - 200;
						case 'schoolEvil':
							getCenterX = char.getMidpoint().x - 200;
							getCenterY = char.getMidpoint().y - 200;
					}

					camFollow.setPosition(getCenterX + camDisplaceX - char.characterData.camOffsetX,
						getCenterY + camDisplaceY + char.characterData.camOffsetY);
				}
			}

			var lerpVal = (elapsed * 2.4) * cameraSpeed;
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

			var easeLerp = 1 - Main.framerateAdjust(0.05);
			// camera stuffs
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom + forceZoom[0], FlxG.camera.zoom, easeLerp);
			for (hud in allUIs)
				hud.zoom = FlxMath.lerp(1 + forceZoom[1], hud.zoom, easeLerp);

			// not even forcezoom anymore but still
			FlxG.camera.angle = FlxMath.lerp(0 + forceZoom[2], FlxG.camera.angle, easeLerp);
			for (hud in allUIs)
				hud.angle = FlxMath.lerp(0 + forceZoom[3], hud.angle, easeLerp);

			// Controls

			// RESET = Quick Game Over Screen
			if (controls.RESET && !startingSong && !isStoryMode)
			{
				health = 0;
			}

			if (health <= 0 && startedCountdown)
			{
				paused = true;
				// startTimer.active = false;
				persistentUpdate = false;
				persistentDraw = false;

				resetMusic();

				deaths += 1;

				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				FlxG.sound.play(Paths.sound('fnf_loss_sfx' + GameOverSubstate.stageSuffix));

				#if DISCORD_RPC
				Discord.changePresence("Game Over - " + songDetails, detailsSub, iconRPC);
				#end
			}

			// spawn in the notes from the array
			if ((unspawnNotes[0] != null) && ((unspawnNotes[0].strumTime - Conductor.songPosition) < 3500))
			{
				var dunceNote:Note = unspawnNotes[0];
				var strumline:Strumline = (dunceNote.mustPress ? bfStrums : dadStrums);

				// push note to its correct strumline
				strumLines.members[
					Math.floor((dunceNote.noteData + (dunceNote.mustPress ? 4 : 0)) / strumline.keyAmount)
				].push(dunceNote);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}

			noteCalls();

			if (Init.trueSettings.get('Controller Mode'))
				controllerInput();

			callFunc('postUpdate', [elapsed]);
		}
	}

	// maybe theres a better place to put this, idk -saw
	function controllerInput()
	{
		var justPressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];

		var justReleaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		if (justPressArray.contains(true))
		{
			for (i in 0...justPressArray.length)
			{
				if (justPressArray[i])
					onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
			}
		}

		if (justReleaseArray.contains(true))
		{
			for (i in 0...justReleaseArray.length)
			{
				if (justReleaseArray[i])
					onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
			}
		}
	}

	function noteCalls()
	{
		// reset strums
		for (strumline in strumLines)
		{
			for (receptor in strumline.receptors)
			{
				if (strumline.autoplay && receptor.animation.curAnim.name == 'confirm' && receptor.animation.curAnim.finished)
					receptor.playAnim('static', true);
			}

			if (strumline.splashNotes != null)
			{
				for (i in 0...strumline.splashNotes.length)
				{
					strumline.splashNotes.members[i].x = strumline.receptors.members[i].x - 48;
					strumline.splashNotes.members[i].y = strumline.receptors.members[i].y + (Note.swagWidth / 6) - 56;
				}
			}
		}

		// if the song is generated
		if (generatedMusic && startedCountdown)
		{
			for (strumline in strumLines)
			{
				// set the notes x and y
				var downscrollMultiplier = 1;
				if (Init.trueSettings.get('Downscroll'))
					downscrollMultiplier = -1;

				strumline.allNotes.forEachAlive(function(daNote:Note)
				{
					var roundedSpeed = FlxMath.roundDecimal(daNote.noteSpeed, 2);
					var receptorPosY:Float = strumline.receptors.members[Math.floor(daNote.noteData)].y + Note.swagWidth / 6;
					var psuedoY:Float = (downscrollMultiplier * -((Conductor.songPosition - daNote.strumTime) * (0.45 * roundedSpeed)));
					var psuedoX = 25 + daNote.noteVisualOffset;

					daNote.y = receptorPosY
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX);
					// painful math equation
					daNote.x = strumline.receptors.members[Math.floor(daNote.noteData)].x
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY);

					// also set note rotation
					daNote.angle = -daNote.noteDirection;

					// shitty note hack I hate it so much
					var center:Float = receptorPosY + Note.swagWidth / 2;
					if (daNote.isSustainNote)
					{
						daNote.y -= ((daNote.height / 2) * downscrollMultiplier);
						if ((daNote.animation.curAnim.name.endsWith('holdend')) && (daNote.prevNote != null))
						{
							daNote.y -= ((daNote.prevNote.height / 2) * downscrollMultiplier);
							if (Init.trueSettings.get('Downscroll'))
							{
								daNote.y += (daNote.height * 2);
								if (daNote.endHoldOffset == Math.NEGATIVE_INFINITY)
								{
									// set the end hold offset yeah I hate that I fix this like this
									daNote.endHoldOffset = (daNote.prevNote.y - (daNote.y + daNote.height));
								}
								else
									daNote.y += daNote.endHoldOffset;
							}
							else // this system is funny like that
								daNote.y += ((daNote.height / 2) * downscrollMultiplier);
						}

						if (Init.trueSettings.get('Downscroll'))
						{
							daNote.flipY = true;
							if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
								&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
								&& daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
								daNote.clipRect = swagRect;
							}
						}
					}
					// hell breaks loose here, we're using nested scripts!
					mainControls(daNote, strumline, strumline.autoplay);

					// check where the note is and make sure it is either active or inactive
					if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
					else
					{
						daNote.visible = true;
						daNote.active = true;
					}

					if (!daNote.tooLate && daNote.strumTime < Conductor.songPosition - (Timings.msThreshold) && !daNote.wasGoodHit)
					{
						if ((!daNote.tooLate) && (daNote.mustPress))
						{
							if (!daNote.isSustainNote)
							{
								daNote.tooLate = true;
								for (note in daNote.childrenNotes)
									note.tooLate = true;

								vocals.volume = 0;
								missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, daNote.noteData, strumline, true);
								// ambiguous name
								Timings.updateAccuracy(0);
							}
							else if (daNote.isSustainNote)
							{
								if (daNote.parentNote != null)
								{
									var parentNote = daNote.parentNote;
									if (!parentNote.tooLate)
									{
										var breakFromLate:Bool = false;
										for (note in parentNote.childrenNotes)
										{
											if (note.tooLate && !note.wasGoodHit)
												breakFromLate = true;
										}
										if (!breakFromLate)
										{
											missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, daNote.noteData, strumline, true);
											for (note in parentNote.childrenNotes)
												note.tooLate = true;
										}
										//
									}
								}
							}
						}
					}

					// if the note is off screen (above)
					if ((((!Init.trueSettings.get('Downscroll')) && (daNote.y < -daNote.height))
						|| ((Init.trueSettings.get('Downscroll')) && (daNote.y > (FlxG.height + daNote.height))))
						&& (daNote.tooLate || daNote.wasGoodHit))
						destroyNote(strumline, daNote);
				});

				// unoptimised asf camera control based on strums
				strumCameraRoll(strumline.receptors, (strumline == bfStrums));
			}
		}

		// reset bf's animation
		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		for (boyfriend in bfStrums.characters)
		{
			if ((boyfriend != null && boyfriend.animation != null)
				&& (boyfriend.holdTimer > Conductor.stepCrochet * (4 / 1000) && (!holdControls.contains(true) || bfStrums.autoplay)))
			{
				if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
					boyfriend.dance();
			}
		}
	}

	function destroyNote(strumline:Strumline, daNote:Note)
	{
		daNote.active = false;
		daNote.exists = false;

		var chosenGroup = (daNote.isSustainNote ? strumline.holdsGroup : strumline.notesGroup);
		// note damage here I guess
		daNote.kill();
		if (strumline.allNotes.members.contains(daNote))
			strumline.allNotes.remove(daNote, true);
		if (chosenGroup.members.contains(daNote))
			chosenGroup.remove(daNote, true);
		daNote.destroy();
	}

	function goodNoteHit(coolNote:Note, strumline:Strumline)
	{
		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			vocals.volume = 1;

			callFunc(coolNote.mustPress ? 'goodNoteHit' : 'opponentNoteHit', [coolNote, strumline]);

			for (character in strumline.characters)
				characterPlayAnimation(coolNote, character);
			if (strumline.receptors.members[coolNote.noteData] != null)
				strumline.receptors.members[coolNote.noteData].playAnim('confirm', true);

			// special thanks to sam, they gave me the original system which kinda inspired my idea for this new one
			if (strumline.displayJudges)
			{
				// get the note ms timing
				var noteDiff:Float = Math.abs(coolNote.strumTime - Conductor.songPosition);
				// get the timing
				if (coolNote.strumTime < Conductor.songPosition)
					ratingTiming = "late";
				else
					ratingTiming = "early";

				// loop through all avaliable judgements
				var foundRating:String = 'miss';
				var lowestThreshold:Float = Math.POSITIVE_INFINITY;
				for (myRating in Timings.judgementsMap.keys())
				{
					var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
					if (noteDiff <= myThreshold && (myThreshold < lowestThreshold))
					{
						foundRating = myRating;
						lowestThreshold = myThreshold;
					}
				}

				if (!coolNote.isSustainNote)
				{
					increaseCombo(foundRating, coolNote.noteData, strumline);
					popUpScore(foundRating, ratingTiming, strumline, coolNote);
					if (coolNote.childrenNotes.length > 0)
						Timings.notesHit++;
					healthCall(Timings.judgementsMap.get(foundRating)[3]);
				}
				else if (coolNote.isSustainNote)
				{
					// call updated accuracy stuffs
					if (coolNote.parentNote != null)
					{
						Timings.updateAccuracy(100, true, coolNote.parentNote.childrenNotes.length);
						healthCall(100 / coolNote.parentNote.childrenNotes.length);
					}
				}
			}

			if (!coolNote.isSustainNote)
				destroyNote(strumline, coolNote);
		}
	}

	function missNoteCheck(?includeAnimation:Bool = false, direction:Int = 0, strumline:Strumline, popMiss:Bool = false, lockMiss:Bool = false)
	{
		if (includeAnimation)
		{
			var stringDirection:String = Receptor.getArrowFromNumber(direction);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			for (character in strumline.characters)
			{
				var missString:String = '';
				if (character.hasMissAnims)
					missString = 'miss';

				character.playAnim('sing' + stringDirection.toUpperCase() + missString, lockMiss);

				// fake misses;
				if (missString == null || missString == '')
					character.color = 0xFF7069FF; // *sad spongebob image* bwoomp.
			}
		}
		decreaseCombo(popMiss);
	}

	function characterPlayAnimation(coolNote:Note, character:Character)
	{
		// alright so we determine which animation needs to play
		// get alt strings and stuffs
		var stringArrow:String = '';
		var altString:String = '';

		var baseString = 'sing' + Receptor.getArrowFromNumber(coolNote.noteData).toUpperCase();

		// I tried doing xor and it didnt work lollll
		if (coolNote.noteAlt > 0)
			altString = '-alt';
		if (((SONG.notes[Math.floor(curStep / 16)] != null) && (SONG.notes[Math.floor(curStep / 16)].altAnim))
			&& (character.animOffsets.exists(baseString + '-alt')))
		{
			if (altString != '-alt')
				altString = '-alt';
			else
				altString = '';
		}

		stringArrow = baseString + altString;
		character.playAnim(stringArrow, true);
		character.holdTimer = 0;
	}

	private function mainControls(daNote:Note, strumline:Strumline, autoplay:Bool):Void
	{
		var notesPressedAutoplay = [];

		// here I'll set up the autoplay functions
		if (autoplay)
		{
			// check if the note was a good hit
			if (daNote.strumTime <= Conductor.songPosition)
			{
				// kill the note, then remove it from the array
				if (strumline.displayJudges)
					notesPressedAutoplay.push(daNote);
				goodNoteHit(daNote, strumline);
			}
		}

		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		if (!autoplay)
		{
			// check if anything is held
			if (holdControls.contains(true))
			{
				// check notes that are alive
				strumline.allNotes.forEachAlive(function(coolNote:Note)
				{
					if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
						&& coolNote.canBeHit
						&& coolNote.mustPress
						&& !coolNote.tooLate
						&& coolNote.isSustainNote
						&& holdControls[coolNote.noteData])
						goodNoteHit(coolNote, strumline);
				});
			}
		}
	}

	private function strumCameraRoll(cStrum:FlxTypedGroup<Receptor>, mustHit:Bool)
	{
		if (!Init.trueSettings.get('No Camera Note Movement'))
		{
			var camDisplaceExtend:Float = 15;
			if (PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				if ((PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && mustHit)
					|| (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
				{
					camDisplaceX = 0;
					if (cStrum.members[0].animation.curAnim.name == 'confirm')
						camDisplaceX -= camDisplaceExtend;
					if (cStrum.members[3].animation.curAnim.name == 'confirm')
						camDisplaceX += camDisplaceExtend;

					camDisplaceY = 0;
					if (cStrum.members[1].animation.curAnim.name == 'confirm')
						camDisplaceY += camDisplaceExtend;
					if (cStrum.members[2].animation.curAnim.name == 'confirm')
						camDisplaceY -= camDisplaceExtend;
				}
			}
		}
		//
	}

	public function pauseGame()
	{
		// pause discord rpc
		updateRPC(true);

		// pause game
		paused = true;

		// update drawing stuffs
		persistentUpdate = false;
		persistentDraw = true;

		// stop all tweens and timers
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
		{
			if (!tmr.finished)
				tmr.active = false;
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween)
		{
			if (!twn.finished)
				twn.active = false;
		});

		// open pause substate
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
	}

	override public function onFocus():Void
	{
		if (!paused)
			updateRPC(false);
		callFunc('onFocus', []);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (canPause && !paused && !bfStrums.autoplay && !Init.trueSettings.get('Auto Pause'))
			pauseGame();
		callFunc('onFocusLost', []);
		super.onFocusLost();
	}

	public static function updateRPC(pausedRPC:Bool)
	{
		#if DISCORD_RPC
		var displayRPC:String = (pausedRPC) ? detailsPausedText : songDetails;

		if (health > 0)
		{
			if (Conductor.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, iconRPC, true, songLength - Conductor.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, iconRPC);
		}
		#end
	}

	private var ratingTiming:String = "";

	function popUpScore(baseRating:String, timing:String, strumline:Strumline, coolNote:Note)
	{
		// set up the rating
		var ratingScore:Int = 50;

		// notesplashes
		if (baseRating == "sick")
			// create the note splash if you hit a sick
			createSplash(coolNote, strumline);
		else
			// if it isn't a sick, and you had a sick combo, then it becomes not sick :(
			if (Timings.perfectCombo)
				Timings.perfectCombo = false;

		displayRating(baseRating, timing);
		Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);

		ratingScore = Std.int(Timings.judgementsMap.get(baseRating)[2]);
		songScore += ratingScore;

		popUpCombo();
	}

	public function createSplash(coolNote:Note, strumline:Strumline)
	{
		// play animation in existing notesplashes
		var noteSplashRandom:String = (Std.string((FlxG.random.int(0, 1) + 1)));
		if (strumline.splashNotes != null)
			strumline.splashNotes.members[coolNote.noteData].playAnim('anim' + noteSplashRandom, true);
	}

	private var createdColor = FlxColor.fromRGB(204, 66, 66);

	function popUpCombo(?cache:Bool = false)
	{
		var comboString:String = Std.string(combo);
		var negative = false;
		if ((comboString.startsWith('-')) || (combo == 0))
			negative = true;
		var stringArray:Array<String> = comboString.split("");
		// deletes all combo sprites prior to initalizing new ones
		if (lastCombo != null)
		{
			while (lastCombo.length > 0)
			{
				lastCombo[0].kill();
				lastCombo.remove(lastCombo[0]);
			}
		}

		for (scoreInt in 0...stringArray.length)
		{
			// numScore.loadGraphic(Paths.image('UI/' + pixelModifier + 'num' + stringArray[scoreInt]));
			var numScore = ForeverAssets.generateCombo('combo', stringArray[scoreInt], (!negative ? Timings.perfectCombo : false), assetModifier,
				changeableSkin, 'UI', negative, createdColor, scoreInt);
			add(numScore);
			// hardcoded lmao
			if (!Init.trueSettings.get('Simply Judgements'))
			{
				add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.kill();
					},
					startDelay: Conductor.crochet * 0.002
				});
			}
			else
			{
				add(numScore);
				// centers combo
				numScore.y += 10;
				numScore.x -= 95;
				numScore.x -= ((comboString.length - 1) * 22);
				lastCombo.push(numScore);
				FlxTween.tween(numScore, {y: numScore.y + 20}, 0.1, {type: FlxTweenType.BACKWARD, ease: FlxEase.circOut});
			}
			// hardcoded lmao
			if (Init.trueSettings.get('Fixed Judgements'))
			{
				if (!cache)
					numScore.cameras = [camHUD];
				numScore.y += 50;
			}
			numScore.x += 100;
		}
	}

	function decreaseCombo(?popMiss:Bool = false)
	{
		// painful if statement
		if (((combo > 5) || (combo < 0)) && (gf.animOffsets.exists('sad')))
			gf.playAnim('sad');

		if (combo > 0)
			combo = 0; // bitch lmao
		else
			combo--;

		// misses
		songScore -= 10;
		misses++;

		// display negative combo
		if (popMiss)
		{
			// doesnt matter miss ratings dont have timings
			displayRating("miss", 'late');
			healthCall(Timings.judgementsMap.get("miss")[3]);
		}
		popUpCombo();

		// gotta do it manually here lol
		Timings.updateFCDisplay();
	}

	function increaseCombo(?baseRating:String, ?direction = 0, ?strumline:Strumline)
	{
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null)
		{
			if (Timings.judgementsMap.get(baseRating)[3] > 0)
			{
				if (combo < 0)
					combo = 0;
				combo += 1;
			}
			else
				missNoteCheck(true, direction, strumline, false, true);
		}
	}

	public function displayRating(daRating:String, timing:String, ?cache:Bool = false)
	{
		/* so you might be asking
			"oh but if the rating isn't sick why not just reset it"
			because miss judgements can pop, and they dont mess with your sick combo
		 */
		var rating = ForeverAssets.generateRating('$daRating', (daRating == 'sick' ? Timings.perfectCombo : false), timing, assetModifier, changeableSkin,
			'UI');
		add(rating);

		if (!Init.trueSettings.get('Simply Judgements'))
		{
			add(rating);

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					rating.kill();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		else
		{
			if (lastRating != null)
			{
				lastRating.kill();
			}
			add(rating);
			lastRating = rating;
			FlxTween.tween(rating, {y: rating.y + 20}, 0.2, {type: FlxTweenType.BACKWARD, ease: FlxEase.circOut});
			FlxTween.tween(rating, {"scale.x": 0, "scale.y": 0}, 0.1, {
				onComplete: function(tween:FlxTween)
				{
					rating.kill();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		// */

		if (!cache)
		{
			if (Init.trueSettings.get('Fixed Judgements'))
			{
				// bound to camera
				rating.cameras = [camHUD];
				rating.screenCenter();
			}

			// return the actual rating to the array of judgements
			Timings.gottenJudgements.set(daRating, Timings.gottenJudgements.get(daRating) + 1);

			// set new smallest rating
			if (Timings.smallestRating != daRating)
			{
				if (Timings.judgementsMap.get(Timings.smallestRating)[0] < Timings.judgementsMap.get(daRating)[0])
					Timings.smallestRating = daRating;
			}
		}
	}

	function healthCall(?ratingMultiplier:Float = 0)
	{
		// health += 0.012;
		var healthBase:Float = 0.06;
		health += (healthBase * (ratingMultiplier / 100));
	}

	function startSong():Void
	{
		startingSong = false;

		if (!paused)
		{
			songMusic.play();
			songMusic.onComplete = endSong;
			vocals.play();

			resyncVocals();

			#if desktop
			// Song duration in a float, useful for the time left feature
			songLength = songMusic.length;

			// Updating Discord Rich Presence (with Time Left)
			updateRPC(false);
			#end
		}
	}

	private function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		songDetails = CoolUtil.dashToSpace(SONG.song) + ' - ' + CoolUtil.difficultyFromNumber(storyDifficulty);

		// String for when the game is paused
		detailsPausedText = "Paused - " + songDetails;

		// set details for song stuffs
		detailsSub = "";

		// Updating Discord Rich Presence.
		updateRPC(false);

		songMusic = new FlxSound().loadEmbedded(Paths.inst(SONG.song), false, true);

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song), false, true);
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		// generate the chart
		unspawnNotes = ChartParser.parseBaseChart(SONG);
		// timedEvents = ChartParser.parseEvents(SONG.events);

		/*
			for (i in timedEvents)
			{
				if (timedEvents.length > 0)
					pushedEvent(i);
			}
		 */

		// give the game the heads up to be able to start
		generatedMusic = true;

		callFunc('generateSong', []);
	}

	/*
		function eventCheck()
		{
			while (timedEvents.length > 0)
			{
				var line:TimedEvent = timedEvents[0];
				if (line != null)
				{
					if (Conductor.songPosition < line.strumTime)
						break;

					eventNoteHit(line.event, line.val1, line.val2, line.val3);
					timedEvents.shift();
				}
			}
		}

		function pushedEvent(event:TimedEvent)
		{
			// trace('Event Name: ${event.event}, Event V1: ${event.val1}, Event V2: ${event.val2}, Event V3: ${event.val3}');

			switch (event.event)
			{
				case 'Change Character':
					var char:Character = new Character(false);
					char.setCharacter(0, 0, event.val2);
					charGroup.add(char);
				case 'Change Stage':
					var newStage:Stage = new Stage(event.val1);
					stageGroup.add(newStage);
					new FlxTimer().start(0.005, function(tmr:FlxTimer)
					{
						newStage.visible = false;
					});
			}
		}

		public var songSpeedTween:FlxTween;

		public function eventNoteHit(event:String, value1:String, value2:String, ?value3:String)
		{
			// TODO: unhardcode this later;
			switch (event)
			{
				case 'Set GF Speed':
					var speed:Int = Std.parseInt(value1);
					if (Math.isNaN(speed) || speed <= 0)
						speed = 1;
					gfSpeed = speed;
				case 'Change Character':
					var changeTimer:FlxTimer;
					var timer:Float = Std.parseFloat(value3);
					if (Math.isNaN(timer))
						timer = 0;
					if (value1 == null || value1.length < 1)
						value1 == 'dad';

					changeTimer = new FlxTimer().start(timer, function(tmr:FlxTimer)
					{
						switch (value1.toLowerCase().trim())
						{
							case 'bf' | 'boyfriend' | 'player' | '0':
								boyfriend.setCharacter(770, 450, value2);
								uiHUD.iconP1.updateIcon(value2, true);
							case 'gf' | 'girlfriend' | 'spectator' | '2':
								gf.setCharacter(300, 100, value2);
							case 'dad' | 'dadOpponent' | 'opponent' | '1':
								dad.setCharacter(100, 100, value2);
								uiHUD.iconP2.updateIcon(value2, false);
						}
						uiHUD.updateBar();
					});
				case 'Change Stage':
					var changeTimer:FlxTimer;
					var timer:Float = Std.parseFloat(value2);
					if (Math.isNaN(timer))
						timer = 0;

					changeTimer = new FlxTimer().start(timer, function(tmr:FlxTimer)
					{
						remove(stageBuild.layers);
						remove(stageBuild.foreground);

						stageGroup.forEach(function(stage:Stage)
						{
							if (stage.curStage != value1)
								stageGroup.remove(stageBuild);
						});

						stageBuild = new Stage(value1);
						stageGroup.add(stageBuild);

						curStage = value1;

						regenerateCharacters();
						loadUIDarken();
					});
				case 'Camera Flash':
					var timer:Float = Std.parseFloat(value2);
					if (Math.isNaN(timer) || timer <= 0)
						timer = 0.6;
					if (value1 == null)
						value1 = 'white';
					FlxG.camera.flash(ForeverTools.returnColor('$value1'), timer);
				case 'Hey!':
					var timer:Float = Std.parseFloat(value2);
					if (Math.isNaN(timer) || timer <= 0)
						timer = 0.6;
					if (value1 == null || value1.length < 1)
						value1 == 'bf';

					switch (value1.toLowerCase().trim())
					{
						case 'bf' | 'boyfriend' | 'player' | '0':
							if (boyfriend.animOffsets.exists('hey'))
							{
								boyfriend.playAnim('hey', true);
								boyfriend.specialAnim = true;
								boyfriend.heyTimer = timer;
							}
						case 'gf' | 'girlfriend' | 'spectator' | '2':
							if (gf.animOffsets.exists('hey'))
								gf.playAnim('hey', true);
							else if (gf.animOffsets.exists('cheer'))
								gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = timer;
						case 'dad' | 'dadOpponent' | 'opponent' | '1':
							if (dad.animOffsets.exists('hey'))
							{
								dad.playAnim('hey', true);
								dad.specialAnim = true;
								dad.heyTimer = timer;
							}
					}
				case 'Play Animation':
					var timer:Float = Std.parseFloat(value3);
					if (Math.isNaN(timer) || timer <= 0)
						timer = 0.6;
					if (value1 == null || value1.length < 1)
						value1 == 'dad';

					switch (value2.toLowerCase().trim())
					{
						case 'bf' | 'boyfriend' | 'player' | '0':
							if (boyfriend.animOffsets.exists(value1))
							{
								boyfriend.playAnim(value1, true);
								boyfriend.specialAnim = true;
								boyfriend.heyTimer = timer;
							}
						case 'gf' | 'girlfriend' | 'spectator' | '2':
							if (gf.animOffsets.exists(value1))
							{
								gf.playAnim(value1, true);
								gf.specialAnim = true;
								gf.heyTimer = timer;
							}
						case 'dad' | 'dadOpponent' | 'opponent' | '1':
							if (dad.animOffsets.exists(value1))
							{
								dad.playAnim(value1, true);
								dad.specialAnim = true;
								dad.heyTimer = timer;
							}
					}
				case 'Multiply Scroll Speed':
					if (Init.getSetting('Use Custom Note Speed'))
						return;

					var mult:Float = Std.parseFloat(value1);
					var timer:Float = Std.parseFloat(value2);
					if (Math.isNaN(mult))
						mult = 1;
					if (Math.isNaN(timer))
						timer = 0;

					var speed = SONG.speed * mult;

					if (mult <= 0)
					{
						songSpeed = speed;
					}
					else
					{
						if (songSpeedTween != null)
							songSpeedTween.cancel();
						songSpeedTween = FlxTween.tween(this, {songSpeed: speed}, timer / Conductor.playbackRate, {
							ease: ForeverTools.returnTweenEase(value3),
							onComplete: function(twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
					}
			}

			callFunc('eventNoteHit', [event, value1, value2, value3]);
		}
	 */
	function resyncVocals():Void
	{
		songMusic.pause();
		vocals.pause();
		Conductor.songPosition = songMusic.time;
		vocals.time = Conductor.songPosition;
		songMusic.play();
		vocals.play();
	}

	override function stepHit()
	{
		super.stepHit();
		///*
		if (songMusic.time >= Conductor.songPosition + 20 || songMusic.time <= Conductor.songPosition - 20)
			resyncVocals();
		//*/

		callFunc('stepHit', [curStep]);
	}

	private function charactersDance(curBeat:Int)
	{
		for (i in strumLines)
		{
			for (targetChar in i.characters)
			{
				if (targetChar != null)
				{
					if ((!targetChar.danceIdle && curBeat % targetChar.characterData.headBopSpeed == 0)
						|| (targetChar.danceIdle && curBeat % Math.round(gfSpeed * targetChar.characterData.headBopSpeed) == 0))
					{
						if (targetChar.animation.curAnim.name.startsWith("idle") // check if the idle exists before dancing
							|| targetChar.animation.curAnim.name.startsWith("dance"))
							targetChar.dance();
					}
				}
			}
		}

		if (gf != null && curBeat % Math.round(gfSpeed * gf.characterData.headBopSpeed) == 0)
		{
			if (gf.animation.curAnim.name.startsWith("idle") || gf.animation.curAnim.name.startsWith("dance"))
				gf.dance();
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if ((FlxG.camera.zoom < 1.35 && curBeat % 4 == 0) && (!Init.trueSettings.get('Reduced Movements')))
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.05;
			for (hud in strumHUD)
				hud.zoom += 0.05;
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}
		}

		uiHUD.beatHit(curBeat);

		//
		charactersDance(curBeat);

		// stage stuffs
		stageBuild.stageUpdate(curBeat, boyfriend, gf, opponent);

		callFunc('beatHit', [curBeat]);

		if (SONG.song.toLowerCase() == 'bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
			}
		}

		if (SONG.song.toLowerCase() == 'fresh')
		{
			switch (curBeat)
			{
				case 16 | 80:
					gfSpeed = 2;
				case 48 | 112:
					gfSpeed = 1;
			}
		}

		if (SONG.song.toLowerCase() == 'milf'
			&& curBeat >= 168
			&& curBeat < 200
			&& !Init.trueSettings.get('Reduced Movements')
			&& FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			for (hud in allUIs)
				hud.zoom += 0.03;
		}
	}

	/* ====== substate stuffs ====== */
	public static function resetMusic()
	{
		// simply stated, resets the playstate's music for other states and substates
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (songMusic != null)
			{
				songMusic.pause();
				vocals.pause();
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (songMusic != null && !startingSong)
				resyncVocals();

			// resume all tweens and timers
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
			{
				if (!tmr.finished)
					tmr.active = true;
			});

			FlxTween.globalManager.forEach(function(twn:FlxTween)
			{
				if (!twn.finished)
					twn.active = true;
			});

			paused = false;

			///*
			updateRPC(false);
			// */
		}

		Paths.clearUnusedMemory();

		super.closeSubState();
	}

	/*
		Extra functions and stuffs
	 */
	/// song end function at the end of the playstate lmao ironic I guess
	private var endSongEvent:Bool = false;

	function endSong():Void
	{
		callFunc('endSong', []);

		canPause = false;
		songMusic.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore && !bfStrums.autoplay)
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);

		deaths = 0;

		if (!isStoryMode)
		{
			Main.switchState(this, new FreeplayState());
		}
		else
		{
			// set the campaign's score higher
			campaignScore += songScore;

			// remove a song from the story playlist
			storyPlaylist.remove(storyPlaylist[0]);

			// check if there aren't any songs left
			if ((storyPlaylist.length <= 0) && (!endSongEvent))
			{
				// play menu music
				ForeverTools.resetMenuMusic();

				// set up transitions
				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				// change to the menu state
				Main.switchState(this, new StoryMenuState());

				// save the week's score if the score is valid
				if (SONG.validScore)
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);

				// flush the save
				FlxG.save.flush();
			}
			else
				songEndSpecificActions();
		}
		//
	}

	private function songEndSpecificActions()
	{
		switch (SONG.song.toLowerCase())
		{
			case 'eggnog':
				// make the lights go out
				var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
					-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
				blackShit.scrollFactor.set();
				add(blackShit);
				camHUD.visible = false;

				// oooo spooky
				FlxG.sound.play(Paths.sound('Lights_Shut_off'));

				// call the song end
				var eggnogEndTimer:FlxTimer = new FlxTimer().start(Conductor.crochet / 1000, function(timer:FlxTimer)
				{
					callDefaultSongEnd();
				}, 1);

			default:
				callDefaultSongEnd();
		}
	}

	private function callDefaultSongEnd()
	{
		var difficulty:String = '-' + CoolUtil.difficultyFromNumber(storyDifficulty).toLowerCase();
		difficulty = difficulty.replace('-normal', '');

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
		ForeverTools.killMusic([songMusic, vocals]);

		// deliberately did not use the main.switchstate as to not unload the assets
		FlxG.switchState(new PlayState());
	}

	var dialogueBox:DialogueBox;

	public function songIntroCutscene()
	{
		switch (SONG.song.toLowerCase())
		{
			case "winter-horrorland":
				inCutscene = true;
				var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				add(blackScreen);
				blackScreen.scrollFactor.set();
				camHUD.visible = false;

				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					remove(blackScreen);
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					camFollow.y = -2050;
					camFollow.x += 200;
					FlxG.camera.focusOn(camFollow.getPosition());
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				});
			case 'roses':
				// the same just play angery noise LOL
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
				callTextbox();
			case 'thorns':
				inCutscene = true;
				for (hud in allUIs)
					hud.visible = false;

				var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
				red.scrollFactor.set();

				var senpaiEvil:FlxSprite = new FlxSprite();
				senpaiEvil.frames = Paths.getSparrowAtlas('cutscene/senpai/senpaiCrazy');
				senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
				senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
				senpaiEvil.scrollFactor.set();
				senpaiEvil.updateHitbox();
				senpaiEvil.screenCenter();

				add(red);
				add(senpaiEvil);
				senpaiEvil.alpha = 0;
				new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
				{
					senpaiEvil.alpha += 0.15;
					if (senpaiEvil.alpha < 1)
						swagTimer.reset();
					else
					{
						senpaiEvil.animation.play('idle');
						FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
						{
							remove(senpaiEvil);
							remove(red);
							FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
							{
								for (hud in allUIs)
									hud.visible = true;
								callTextbox();
							}, true);
						});
						new FlxTimer().start(3.2, function(deadTime:FlxTimer)
						{
							FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
						});
					}
				});
			default:
				callTextbox();
		}
		//
	}

	function callTextbox()
	{
		var dialogPath = Paths.json(SONG.song.toLowerCase() + '/dialogue');
		if (sys.FileSystem.exists(dialogPath))
		{
			startedCountdown = false;

			dialogueBox = DialogueBox.createDialogue(sys.io.File.getContent(dialogPath));
			dialogueBox.cameras = [dialogueHUD];
			dialogueBox.whenDaFinish = startCountdown;

			add(dialogueBox);
		}
		else
			startCountdown();
	}

	public static function skipCutscenes():Bool
	{
		// pretty messy but an if statement is messier
		if (Init.trueSettings.get('Skip Text') != null && Std.isOfType(Init.trueSettings.get('Skip Text'), String))
		{
			switch (cast(Init.trueSettings.get('Skip Text'), String))
			{
				case 'never':
					return false;
				case 'freeplay only':
					if (!isStoryMode)
						return true;
					else
						return false;
				default:
					return true;
			}
		}
		return false;
	}

	public static var swagCounter:Int = 0;

	private function startCountdown():Void
	{
		inCutscene = false;
		Conductor.songPosition = -(Conductor.crochet * 5);
		swagCounter = 0;

		callFunc('startCountdown', []);

		camHUD.visible = true;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			startedCountdown = true;

			charactersDance(curBeat);

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', [
				ForeverTools.returnSkinAsset('prepare', assetModifier, changeableSkin, 'UI'),
				ForeverTools.returnSkinAsset('ready', assetModifier, changeableSkin, 'UI'),
				ForeverTools.returnSkinAsset('set', assetModifier, changeableSkin, 'UI'),
				ForeverTools.returnSkinAsset('go', assetModifier, changeableSkin, 'UI')
			]);

			var introAlts:Array<String> = introAssets.get('default');
			for (value in introAssets.keys())
			{
				if (value == PlayState.curStage)
					introAlts = introAssets.get(value);
			}

			switch (swagCounter)
			{
				case 0:
					var prepare:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					prepare.scrollFactor.set();
					prepare.updateHitbox();

					if (assetModifier == 'pixel')
						prepare.setGraphicSize(Std.int(prepare.width * PlayState.daPixelZoom));

					prepare.screenCenter();
					add(prepare);
					FlxTween.tween(prepare, {y: prepare.y += 50, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							prepare.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro3-' + assetModifier), 0.6);
					Conductor.songPosition = -(Conductor.crochet * 4);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (assetModifier == 'pixel')
						ready.setGraphicSize(Std.int(ready.width * PlayState.daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 50, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2-' + assetModifier), 0.6);

					Conductor.songPosition = -(Conductor.crochet * 3);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					set.scrollFactor.set();

					if (assetModifier == 'pixel')
						set.setGraphicSize(Std.int(set.width * PlayState.daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 50, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1-' + assetModifier), 0.6);

					Conductor.songPosition = -(Conductor.crochet * 2);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[3]));
					go.scrollFactor.set();

					if (assetModifier == 'pixel')
						go.setGraphicSize(Std.int(go.width * PlayState.daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 50, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo-' + assetModifier), 0.6);

					Conductor.songPosition = -(Conductor.crochet * 1);
			}

			callFunc('countdownTick', [swagCounter]);

			swagCounter += 1;
		}, 5);
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}

	private function scriptCall()
	{
		var dirs:Array<Array<String>> = [
			CoolUtil.absoluteDirectory('scripts'),
			CoolUtil.absoluteDirectory('songs/${CoolUtil.swapSpaceDash(PlayState.SONG.song.toLowerCase())}')
		];

		for (directory in dirs)
		{
			for (script in directory)
			{
				if (directory != null && directory.length > 0)
				{
					for (ext in Paths.scriptExts)
					{
						if (script != null && script.endsWith('.$ext'))
							moduleArray.push(new ScriptHandler(script));
					}
				}
			}
		}

		callFunc('create', []);
	}

	private function callFunc(key:String, args:Array<Dynamic>)
	{
		if (moduleArray != null)
		{
			for (i in moduleArray)
				i.call(key, args);
			if (generatedMusic)
				callLocalVariables();
		}
	}

	private function setVar(key:String, value:Dynamic)
	{
		var allSucceed:Bool = true;
		if (moduleArray != null)
		{
			for (i in moduleArray)
			{
				i.set(key, value);

				if (!i.exists(key))
				{
					trace('${i.scriptFile} failed to set $key for its interpreter, continuing.');
					allSucceed = false;
					continue;
				}
			}
		}
		return allSucceed;
	}

	function callLocalVariables()
	{
		// GENERAL
		setVar('game', PlayState.main);

		setVar('add', add);
		setVar('remove', remove);
		setVar('openSubState', openSubState);

		// CHARACTERS
		setVar('songName', PlayState.SONG.song.toLowerCase());

		if (boyfriend != null)
		{
			setVar('bf', boyfriend);
			setVar('boyfriend', boyfriend);
			setVar('player', boyfriend);
			setVar('bfName', boyfriend.curCharacter);
			setVar('boyfriendName', boyfriend.curCharacter);
			setVar('playerName', boyfriend.curCharacter);
		}

		if (opponent != null)
		{
			setVar('dad', opponent);
			setVar('dadOpponent', opponent);
			setVar('opponent', opponent);
			setVar('dadName', opponent.curCharacter);
			setVar('dadOpponentName', opponent.curCharacter);
			setVar('opponentName', opponent.curCharacter);
		}

		if (gf != null)
		{
			setVar('gf', gf);
			setVar('girlfriend', gf);
			setVar('spectator', gf);
			setVar('gfName', gf.curCharacter);
			setVar('girlfriendName', gf.curCharacter);
			setVar('spectatorName', gf.curCharacter);
		}

		if (bfStrums != null)
			setVar('bfStrums', bfStrums);
		if (dadStrums != null)
			setVar('dadStrums', dadStrums);
		if (strumLines != null)
			setVar('strumLines', strumLines);
		if (allUIs != null)
			setVar('allUIs', allUIs);
		if (camGame != null)
			setVar('camGame', camGame);
		if (camHUD != null)
			setVar('camHUD', camHUD);
		if (dialogueHUD != null)
			setVar('dialogueHUD', dialogueHUD);
		if (strumHUD != null)
			setVar('strumHUD', strumHUD);
		if (uiHUD != null)
			setVar('ui', uiHUD);

		setVar('score', songScore);
		setVar('combo', combo);
		setVar('health', health);
		setVar('hits', Timings.notesHit);
		setVar('misses', misses);
		setVar('deaths', deaths);

		setVar('curBeat', curBeat);
		setVar('curStep', curStep);

		setVar('set', function(key:String, value:Dynamic)
		{
			var dotList:Array<String> = key.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(this, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				Reflect.setProperty(reflector, dotList[dotList.length - 1], value);
				return true;
			}

			Reflect.setProperty(this, key, value);
			return true;
		});

		setVar('get', function(variable:String)
		{
			var dotList:Array<String> = variable.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(this, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				return Reflect.getProperty(reflector, dotList[dotList.length - 1]);
			}

			return Reflect.getProperty(this, variable);
		});
	}
}
