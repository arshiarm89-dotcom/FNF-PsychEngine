package backend;

/**
 * VS RAF level progress (auto-save).
 * LEVELS order = story order. Each entry: [song folder name, week file name, level picture, level label picture]
 * To add a new level later, just add a line here (and its pictures in mods/images/startmenu/).
 */
class SaveProgress
{
	public static final LEVELS:Array<Array<String>> = [
		['bahare-lesson', 'story-tutorial', 'lvl_bahare-lesson', 'lbl_bahare-lesson'],
		['street-act-1', 'street-act1', 'lvl_street-act-1', 'lbl_street-act-1']
	];

	/** index of the furthest level reached, or -1 when nothing is saved yet */
	public static function reached():Int
	{
		var v:Dynamic = FlxG.save.data.vsrafLevel;
		if (v == null) return -1;
		var i:Int = Std.int(v);
		if (i >= LEVELS.length) i = LEVELS.length - 1;
		return i;
	}

	/** called when a level starts: saves it if it is further than what is saved */
	public static function reach(song:String):Void
	{
		for (i in 0...LEVELS.length)
		{
			if (LEVELS[i][0] == song)
			{
				if (i > reached())
				{
					FlxG.save.data.vsrafLevel = i;
					FlxG.save.flush();
				}
				return;
			}
		}
	}
}
