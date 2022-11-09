import states.menus.MainMenuState;

function create() {}

function postCreate()
{
	var bg:FlxSprite = new FlxSprite();
	bg.loadGraphic(Paths.image('menus/chart/bg'));
	add(bg);

	updatePresence('EXAMPLE MENU', 'Scriptable State');
}

function update(elapsed:Float)
{
	if (controls.BACK)
		Main.switchState(this, new MainMenuState());
}

function postUpdate(elapsed:Float) {}
function beatHit(curBeat:Int) {}
function stepHit(curStep:Int) {}
function onFocus() {}
function onFocusLost() {}
function destroy() {}
function openSubState() {}
function closeSubState() {}
