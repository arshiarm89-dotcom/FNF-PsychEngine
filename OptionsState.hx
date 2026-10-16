package options;

import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
	];

	// name of the button art (images/optionsmenu/opt_<name>.png) for every option
	var optionArt:Map<String, String> = [
		'Note Colors' => 'notecolors',
		'Controls' => 'controls',
		'Adjust Delay and Combo' => 'delay',
		'Graphics' => 'graphics',
		'Visuals' => 'visuals',
		'Gameplay' => 'gameplay',
		'Language' => 'language'
	];

	var buttons:Array<FlxSprite> = [];
	var baseYs:Array<Float> = [];
	var scaleVel:Array<Float> = [];
	var menuTime:Float = 0;

	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		add(new backend.RedBG(0.25));

		var title:FlxSprite = new FlxSprite().loadGraphic(Paths.image('optionsmenu/opt_title'));
		title.antialiasing = ClientPrefs.data.antialiasing;
		title.screenCenter(X);
		title.y = 14;
		add(title);

		for (num => option in options)
		{
			var art:String = optionArt.exists(option) ? optionArt.get(option) : 'controls';
			var btn:FlxSprite = new FlxSprite();
			btn.frames = Paths.getSparrowAtlas('optionsmenu/opt_' + art);
			btn.animation.addByPrefix('idle', 'idle', 24, true);
			btn.animation.addByPrefix('selected', 'selected', 24, true);
			btn.animation.play('idle');
			btn.updateHitbox();
			btn.antialiasing = ClientPrefs.data.antialiasing;

			var col:Int = num % 2;
			var row:Int = Std.int(num / 2);
			var cx:Float = (col == 0) ? 340 : 940;
			if (num == options.length - 1 && options.length % 2 == 1) cx = 640; // lonely last one in the middle
			btn.x = cx - btn.width / 2;
			btn.y = 190 + row * 132 - btn.height / 2;

			buttons.push(btn);
			baseYs.push(btn.y);
			scaleVel.push(0);
			add(btn);
		}

		setSelection(curSelected, false);
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		menuTime += elapsed;

		// floating + springy pop on the selected button
		for (i in 0...buttons.length)
		{
			var b:FlxSprite = buttons[i];
			var isSel:Bool = (i == curSelected);
			b.y = baseYs[i] + Math.sin(menuTime * 1.8 + i * 1.3) * (isSel ? 5 : 3);
			var target:Float = isSel ? 1.1 + Math.sin(menuTime * 5) * 0.012 : 1.0;
			var cur:Float = b.scale.x;
			scaleVel[i] += ((target - cur) * 220 - scaleVel[i] * 13) * elapsed;
			var ns:Float = cur + scaleVel[i] * elapsed;
			b.scale.set(ns, ns);
			b.alpha = isSel ? 1 : 0.85;
		}

		var n:Int = options.length;
		var rows:Int = Math.ceil(n / 2);

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			var other:Int = curSelected ^ 1;
			if (other < n) setSelection(other);
		}
		if (controls.UI_UP_P)
		{
			var ni:Int = curSelected - 2;
			if (ni < 0)
			{
				ni = curSelected + (rows - 1) * 2;
				if (ni >= n) ni -= 2;
			}
			setSelection(ni);
		}
		if (controls.UI_DOWN_P)
		{
			var ni:Int = curSelected + 2;
			if (ni >= n) ni = curSelected % 2;
			setSelection(ni);
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT)
		{
			scaleVel[curSelected] += 2.5;
			openSelectedSubstate(options[curSelected]);
		}
	}

	function setSelection(index:Int, sound:Bool = true)
	{
		curSelected = FlxMath.wrap(index, 0, options.length - 1);

		for (num => b in buttons)
			b.animation.play(num == curSelected ? 'selected' : 'idle');

		if (sound)
		{
			scaleVel[curSelected] += 1.6; // pop
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
