package backend;

import flixel.group.FlxGroup;

/**
 * Animated red background (drifting image + glowing smoke + floating embers).
 * Used by the VS RAF menus. Add it with: add(new backend.RedBG());
 */
class RedBG extends FlxGroup
{
	var bgMain:FlxSprite;
	var bgSmoke:FlxSprite;
	var bgBaseX:Float = 0;
	var bgBaseY:Float = 0;
	var smokeBaseX:Float = 0;
	var smokeBaseY:Float = 0;
	var t:Float = 0;
	var embers:Array<FlxSprite> = [];
	var emberSpeed:Array<Float> = [];
	var emberDrift:Array<Float> = [];

	public function new(dim:Float = 0.0)
	{
		super();

		bgMain = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		bgMain.antialiasing = ClientPrefs.data.antialiasing;
		bgMain.scrollFactor.set();
		bgMain.setGraphicSize(Std.int(bgMain.width * 1.4));
		bgMain.updateHitbox();
		bgMain.screenCenter();
		bgBaseX = bgMain.x;
		bgBaseY = bgMain.y;
		add(bgMain);

		bgSmoke = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bgSmoke.antialiasing = ClientPrefs.data.antialiasing;
		bgSmoke.scrollFactor.set();
		bgSmoke.setGraphicSize(Std.int(bgSmoke.width * 1.6));
		bgSmoke.updateHitbox();
		bgSmoke.screenCenter();
		bgSmoke.color = 0xFFC8101A;
		bgSmoke.blend = openfl.display.BlendMode.ADD;
		bgSmoke.alpha = 0.2;
		smokeBaseX = bgSmoke.x;
		smokeBaseY = bgSmoke.y;
		add(bgSmoke);

		for (i in 0...30)
		{
			var e:FlxSprite = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			var sz:Int = FlxG.random.int(2, 5);
			e.makeGraphic(sz, sz, FlxColor.fromRGB(255, FlxG.random.int(40, 110), 40));
			e.scrollFactor.set();
			e.alpha = FlxG.random.float(0.2, 0.7);
			embers.push(e);
			emberSpeed.push(FlxG.random.float(18, 60));
			emberDrift.push(FlxG.random.float(-14, 14));
			add(e);
		}

		if (dim > 0)
		{
			var d:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			d.scale.set(FlxG.width, FlxG.height);
			d.updateHitbox();
			d.scrollFactor.set();
			d.alpha = dim;
			add(d);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		t += elapsed;

		bgMain.x = bgBaseX + Math.sin(t * 0.23) * 70;
		bgMain.y = bgBaseY + Math.cos(t * 0.17) * 40;
		bgSmoke.x = smokeBaseX - Math.sin(t * 0.19 + 1.3) * 90;
		bgSmoke.y = smokeBaseY - Math.cos(t * 0.27) * 50;
		bgSmoke.alpha = 0.22 + Math.sin(t * 0.8) * 0.12;

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
		}
	}
}
