package states;

import backend.WeekData;
import backend.Song;
import backend.StageData;
import backend.SaveProgress;

/**
 * VS RAF "START" menu: red panel on the left (START / SAVES),
 * preview on the right (couple picture / last saved level / lock).
 */
class StartMenuState extends MusicBeatState
{
	static final PANEL_CX:Float = 270;   // centre of the red panel
	static final RIGHT_CX:Float = 910;   // centre of the right side

	var bg:backend.RedBG;
	var darkBG:FlxSprite;
	var smoke:FlxSprite;
	var panel:FlxSprite;
	var startSpr:FlxSprite;
	var savesSpr:FlxSprite;
	var lockSmall:FlxSprite;

	var couple:FlxSprite;
	var coupleGlow:FlxSprite;
	var saveFrame:FlxSprite;
	var saveLabel:FlxSprite;
	var saveContinue:FlxSprite;
	var lockBig:FlxSprite;
	var lockText:FlxSprite;

	var curSel:Int = -1; // -1 = nothing, 0 = START, 1 = SAVES
	var busy:Bool = false;
	var hasSave:Bool = false;
	var t:Float = 0;
	var mouseIdle:Float = 0;

	var aDark:Float = 0;
	var aStart:Float = 0;
	var aSaves:Float = 0;
	var aLock:Float = 0;
	var pop:Array<Float> = [0, 0];
	var popVel:Array<Float> = [0, 0];
	var lockShake:Float = 0;
	var embers:Array<FlxSprite> = [];
	var emberSpeed:Array<Float> = [];
	var emberDrift:Array<Float> = [];
	var emberBase:Array<Float> = [];

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		Mods.loadTopMod();
		persistentUpdate = persistentDraw = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		var saved:Int = SaveProgress.reached();
		hasSave = saved >= 0;

		// 1) animated red background (shown when nothing is selected)
		bg = new backend.RedBG(0.0);
		add(bg);

		// 2) black/red backdrop + smoke (shown when something is selected)
		darkBG = new FlxSprite().loadGraphic(Paths.image('startmenu/dark_bg'));
		darkBG.antialiasing = ClientPrefs.data.antialiasing;
		darkBG.scrollFactor.set();
		darkBG.alpha = 0;
		add(darkBG);

		smoke = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		smoke.antialiasing = ClientPrefs.data.antialiasing;
		smoke.scrollFactor.set();
		smoke.setGraphicSize(Std.int(smoke.width * 1.5));
		smoke.updateHitbox();
		smoke.screenCenter();
		smoke.color = 0xFFFF1A22;
		smoke.blend = openfl.display.BlendMode.ADD;
		smoke.alpha = 0;
		add(smoke);

		// floating red embers (same as the main menu), shown on the dark side
		for (i in 0...44)
		{
			var e:FlxSprite = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			var sz:Int = FlxG.random.int(2, 6);
			e.makeGraphic(sz, sz, FlxColor.fromRGB(255, FlxG.random.int(40, 110), 40));
			e.scrollFactor.set();
			emberBase.push(FlxG.random.float(0.3, 0.9));
			e.alpha = 0;
			embers.push(e);
			emberSpeed.push(FlxG.random.float(18, 70));
			emberDrift.push(FlxG.random.float(-14, 14));
			add(e);
		}

		// 3) START preview: Saeed + Bahare
		coupleGlow = new FlxSprite().loadGraphic(Paths.image('startmenu/couple'));
		coupleGlow.antialiasing = ClientPrefs.data.antialiasing;
		coupleGlow.scrollFactor.set();
		coupleGlow.color = 0xFFFF1010;
		coupleGlow.blend = openfl.display.BlendMode.ADD;
		coupleGlow.alpha = 0;
		add(coupleGlow);

		couple = new FlxSprite().loadGraphic(Paths.image('startmenu/couple'));
		couple.antialiasing = ClientPrefs.data.antialiasing;
		couple.scrollFactor.set();
		couple.alpha = 0;
		add(couple);

		// 4) SAVES preview: picture of the last reached level
		if (hasSave)
		{
			var lv:Array<String> = SaveProgress.LEVELS[saved];
			saveFrame = new FlxSprite().loadGraphic(Paths.image('startmenu/' + lv[2]));
			saveFrame.antialiasing = ClientPrefs.data.antialiasing;
			saveFrame.scrollFactor.set();
			saveFrame.alpha = 0;
			add(saveFrame);

			saveLabel = new FlxSprite().loadGraphic(Paths.image('startmenu/' + lv[3]));
			saveLabel.antialiasing = ClientPrefs.data.antialiasing;
			saveLabel.scrollFactor.set();
			saveLabel.alpha = 0;
			add(saveLabel);

			saveContinue = new FlxSprite().loadGraphic(Paths.image('startmenu/lbl_continue'));
			saveContinue.antialiasing = ClientPrefs.data.antialiasing;
			saveContinue.scrollFactor.set();
			saveContinue.alpha = 0;
			add(saveContinue);
		}
		else
		{
			// 5) SAVES locked preview
			lockBig = new FlxSprite().loadGraphic(Paths.image('startmenu/lock_big'));
			lockBig.antialiasing = ClientPrefs.data.antialiasing;
			lockBig.scrollFactor.set();
			lockBig.alpha = 0;
			add(lockBig);

			lockText = new FlxSprite().loadGraphic(Paths.image('startmenu/lock_text'));
			lockText.antialiasing = ClientPrefs.data.antialiasing;
			lockText.scrollFactor.set();
			lockText.alpha = 0;
			add(lockText);
		}

		// 6) red panel on the left + the two labels
		panel = new FlxSprite().loadGraphic(Paths.image('startmenu/panel'));
		panel.antialiasing = ClientPrefs.data.antialiasing;
		panel.scrollFactor.set();
		panel.x = -panel.width;
		add(panel);
		FlxTween.tween(panel, {x: 0}, 0.45, {ease: FlxEase.quartOut});

		startSpr = new FlxSprite().loadGraphic(Paths.image('startmenu/start'));
		startSpr.antialiasing = ClientPrefs.data.antialiasing;
		startSpr.scrollFactor.set();
		add(startSpr);

		savesSpr = new FlxSprite().loadGraphic(Paths.image('startmenu/' + (hasSave ? 'saves' : 'saves_locked')));
		savesSpr.antialiasing = ClientPrefs.data.antialiasing;
		savesSpr.scrollFactor.set();
		add(savesSpr);

		if (!hasSave)
		{
			lockSmall = new FlxSprite().loadGraphic(Paths.image('startmenu/lock_small'));
			lockSmall.antialiasing = ClientPrefs.data.antialiasing;
			lockSmall.scrollFactor.set();
			add(lockSmall);
		}

		layoutAll(0);
		super.create();
	}

	function setBase(s:FlxSprite, base:Float, sel:Float):Void
	{
		s.scale.set(base * (1 + sel), base * (1 + sel));
		s.updateHitbox();
	}

	function layoutAll(elapsed:Float):Void
	{
		var slide:Float = panel.x + panel.width; // 0 when fully hidden... (panel slides in)
		var pOff:Float = panel.x; // negative while sliding in

		setBase(startSpr, 0.62, pop[0]);
		startSpr.x = PANEL_CX - startSpr.width / 2 + pOff + (curSel == 0 ? 14 : 0);
		startSpr.y = 250 - startSpr.height / 2 + Math.sin(t * 1.6) * 3;

		setBase(savesSpr, 0.62, pop[1]);
		savesSpr.x = PANEL_CX - savesSpr.width / 2 + pOff + (curSel == 1 ? 14 : 0);
		savesSpr.y = 430 - savesSpr.height / 2 + Math.sin(t * 1.6 + 1.5) * 3;
		if (!hasSave && lockShake > 0)
			savesSpr.x += Math.sin(t * 70) * 6 * lockShake;
		if (lockSmall != null)
		{
			lockSmall.x = savesSpr.x + savesSpr.width + 4;
			lockSmall.y = savesSpr.y + savesSpr.height / 2 - lockSmall.height / 2;
		}
	}

	function setSel(n:Int):Void
	{
		if (n == curSel) return;
		curSel = n;
		if (n >= 0) FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function update(elapsed:Float)
	{
		t += elapsed;
		if (lockShake > 0) lockShake = Math.max(0, lockShake - elapsed * 3);

		if (FlxG.sound.music != null && !busy && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		// ---- previews fade in/out ----
		var r:Float = FlxMath.bound(elapsed * 9, 0, 1);
		aDark = FlxMath.lerp(aDark, curSel >= 0 ? 1 : 0, r);
		aStart = FlxMath.lerp(aStart, curSel == 0 ? 1 : 0, r);
		aSaves = FlxMath.lerp(aSaves, (curSel == 1 && hasSave) ? 1 : 0, r);
		aLock = FlxMath.lerp(aLock, (curSel == 1 && !hasSave) ? 1 : 0, r);

		darkBG.alpha = aDark;
		smoke.alpha = aDark * (0.22 + Math.sin(t * 0.9) * 0.1);
		smoke.x = (FlxG.width - smoke.width) / 2 - Math.sin(t * 0.21 + 0.7) * 90;
		smoke.y = (FlxG.height - smoke.height) / 2 - Math.cos(t * 0.29) * 50;

		for (i in 0...embers.length)
		{
			var e:FlxSprite = embers[i];
			e.y -= emberSpeed[i] * elapsed;
			e.x += (emberDrift[i] + Math.sin(t * 1.5 + i) * 10) * elapsed;
			if (e.y < -10)
			{
				e.y = FlxG.height + 10;
				e.x = FlxG.random.float(0, FlxG.width);
			}
			e.alpha = emberBase[i] * aDark;
		}

		// couple: slow breathing + glow pulse
		// anchored to the bottom-right corner so the cut edges stay off-screen
		var cs:Float = 0.56 * (1 + Math.sin(t * 1.7) * 0.006);
		couple.scale.set(cs, cs);
		couple.updateHitbox();
		couple.x = FlxG.width - couple.width + 4 + (1 - aStart) * 80;
		couple.y = FlxG.height - couple.height + 4 + Math.sin(t * 1.3) * 3;
		couple.alpha = aStart;
		coupleGlow.scale.set(cs * 1.03, cs * 1.03);
		coupleGlow.updateHitbox();
		coupleGlow.x = couple.x + (couple.width - coupleGlow.width) / 2;
		coupleGlow.y = couple.y + (couple.height - coupleGlow.height) / 2;
		coupleGlow.alpha = aStart * (0.35 + Math.sin(t * 2.4) * 0.15);

		if (saveFrame != null)
		{
			saveFrame.x = RIGHT_CX - saveFrame.width / 2 + (1 - aSaves) * 60;
			saveFrame.y = 345 - saveFrame.height / 2 + Math.sin(t * 1.3) * 4;
			saveFrame.alpha = aSaves;
			saveLabel.x = RIGHT_CX - saveLabel.width / 2 + (1 - aSaves) * 60;
			saveLabel.y = saveFrame.y + saveFrame.height + 18;
			saveLabel.alpha = aSaves;
			saveContinue.x = RIGHT_CX - saveContinue.width / 2 + (1 - aSaves) * 60;
			saveContinue.y = saveFrame.y - saveContinue.height - 14;
			saveContinue.alpha = aSaves;
		}
		if (lockBig != null)
		{
			lockBig.x = RIGHT_CX - lockBig.width / 2 + Math.sin(t * 60) * 5 * lockShake;
			lockBig.y = 290 - lockBig.height / 2 + Math.sin(t * 1.5) * 5;
			lockBig.alpha = aLock;
			lockText.x = RIGHT_CX - lockText.width / 2;
			lockText.y = 420;
			lockText.alpha = aLock;
		}

		// ---- springy pop on the selected label ----
		for (i in 0...2)
		{
			var target:Float = (curSel == i) ? 0.12 + Math.sin(t * 5) * 0.012 : 0;
			popVel[i] += ((target - pop[i]) * 220 - popVel[i] * 13) * elapsed;
			pop[i] += popVel[i] * elapsed;
		}
		layoutAll(elapsed);

		// ---- input ----
		if (!busy)
		{
			if (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)
			{
				FlxG.mouse.visible = true;
				mouseIdle = 0;
				if (FlxG.mouse.overlaps(startSpr)) setSel(0);
				else if (FlxG.mouse.overlaps(savesSpr)) setSel(1);
				else setSel(-1);
			}
			else
			{
				mouseIdle += elapsed;
				if (mouseIdle > 2) FlxG.mouse.visible = false;
			}

			if (controls.UI_DOWN_P)
				setSel(curSel < 0 ? 0 : (curSel == 0 ? 1 : 0));
			if (controls.UI_UP_P)
				setSel(curSel < 0 ? 1 : (curSel == 1 ? 0 : 1));

			if (controls.BACK)
			{
				busy = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			if (curSel >= 0 && (controls.ACCEPT || FlxG.mouse.justPressed))
			{
				if (curSel == 0)
					startGame(0, true);
				else if (hasSave)
					startGame(SaveProgress.reached(), false);
				else
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					lockShake = 1;
				}
			}
		}

		super.update(elapsed);
	}

	/** laugh (START only) -> red flash -> level */
	function startGame(levelIdx:Int, withLaugh:Bool):Void
	{
		busy = true;
		FlxG.mouse.visible = false;

		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.5, 0);

		var wait:Float = 1.2;
		if (withLaugh)
		{
			// put your own laugh in mods/sounds/vsraf_laugh.ogg to replace this one
			var laugh = Paths.sound('vsraf_laugh');
			if (laugh != null) FlxG.sound.play(laugh);
			wait = 3.4;
			FlxG.camera.shake(0.012, 0.6);
			if (ClientPrefs.data.flashing) FlxG.camera.flash(0xFFB00010, 0.7);
			new FlxTimer().start(1.4, function(_) { FlxG.camera.shake(0.006, 1.2); });
		}
		else
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
		}

		new FlxTimer().start(wait - 0.8, function(_) { FlxG.camera.fade(FlxColor.BLACK, 0.8, false); });
		new FlxTimer().start(wait, function(_) { loadLevel(levelIdx); });
	}

	function loadLevel(idx:Int):Void
	{
		var lv:Array<String> = SaveProgress.LEVELS[idx];

		WeekData.reloadWeekFiles(true);
		var week:WeekData = WeekData.weeksLoaded.get(lv[1]);
		if (week == null)
		{
			trace('START MENU: week "' + lv[1] + '" not found');
			MusicBeatState.switchState(new MainMenuState());
			return;
		}

		var songArray:Array<String> = [];
		var leWeek:Array<Dynamic> = week.songs;
		for (i in 0...leWeek.length) songArray.push(leWeek[i][0]);

		try
		{
			WeekData.setDirectoryFromWeek(week);
			PlayState.storyWeek = WeekData.weeksList.indexOf(lv[1]);
			Difficulty.resetList();
			Difficulty.loadFromWeek();
			var curDifficulty:Int = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
			var diffic:String = Difficulty.getFilePath(curDifficulty);
			if (diffic == null) diffic = '';

			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;
			PlayState.changedDifficulty = false;
			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;
			PlayState.storyDifficulty = curDifficulty;
			Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
		}
		catch (e:Dynamic)
		{
			trace('ERROR! $e');
			MusicBeatState.switchState(new MainMenuState());
			return;
		}

		// TODO (later): play the level's cutscene here before starting it

		var directory = StageData.forceNextDirectory;
		LoadingState.loadNextDirectory();
		StageData.forceNextDirectory = directory;

		@:privateAccess
		if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
		{
			trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
			Paths.freeGraphicsFromMemory();
		}
		LoadingState.prepareToSong();
		#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
		LoadingState.loadAndSwitchState(new PlayState(), true);
		FreeplayState.destroyFreeplayVocals();

		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}
}
