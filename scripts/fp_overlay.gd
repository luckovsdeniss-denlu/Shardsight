class_name FpOverlay
extends Control
## First person's screen furniture: a crosshair in the middle, a line under it naming whoever is
## in your sights (with their health), and your health, mana and stamina bars at the bottom.

var game


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _bar(at: Vector2, w: float, frac: float, col: Color, text: String) -> void:
	draw_rect(Rect2(at - Vector2(1, 1), Vector2(w + 2, 16)), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(at, Vector2(w * clampf(frac, 0.0, 1.0), 14)), col)
	var font := ThemeDB.fallback_font
	draw_string_outline(font, at + Vector2(6, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color.BLACK)
	draw_string(font, at + Vector2(6, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


func _draw() -> void:
	if game == null or game.hero == null:
		return
	var hero: Entity = game.hero
	var vsize := get_viewport_rect().size
	var c := vsize / 2.0
	var font := ThemeDB.fallback_font
	# the crosshair: a ring and a dot, outlined so it shows on any background
	var aim: Entity = game.aimed
	var col := Color(1.0, 0.35, 0.3) if aim != null and aim.kind == Entity.Kind.MONSTER else Color(1, 1, 1, 0.85)
	draw_arc(c, 9.0, 0.0, TAU, 24, Color(0, 0, 0, 0.6), 3.0)
	draw_arc(c, 9.0, 0.0, TAU, 24, col, 1.5)
	draw_circle(c, 2.0, col)
	# who's in your sights
	if aim != null:
		var mhp := float(aim.stats.max_hp())
		var label := "%s   HP %d/%d" % [aim.display_name, ceili(aim.hp), int(mhp)]
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var at := c + Vector2(-w / 2.0, 34.0)
		draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
		draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
		draw_rect(Rect2(c + Vector2(-40, 40), Vector2(80, 5)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(c + Vector2(-40, 40), Vector2(80 * clampf(aim.hp / maxf(mhp, 1.0), 0.0, 1.0), 5)), Color(0.9, 0.25, 0.2))
	# your health, mana and stamina, bottom centre (above the pick buttons)
	var s := hero.stats
	var bw := 240.0
	var x := c.x - bw / 2.0
	var y := vsize.y - 150.0
	_bar(Vector2(x, y), bw, hero.hp / maxf(float(s.max_hp()), 1.0), Color(0.75, 0.2, 0.18), "HP %d / %d" % [ceili(hero.hp), s.max_hp()])
	_bar(Vector2(x, y + 19), bw, hero.mana / maxf(float(s.max_mana()), 1.0), Color(0.25, 0.4, 0.85), "Mana %d / %d" % [int(hero.mana), s.max_mana()])
	_bar(Vector2(x, y + 38), bw, hero.stamina / maxf(float(s.max_stamina()), 1.0), Color(0.75, 0.65, 0.2), "Stamina %d / %d" % [int(hero.stamina), s.max_stamina()])
