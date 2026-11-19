class_name FpOverlay
extends Control
## First person's screen, kept clean and cinematic: thin letterbox bars top and bottom; a small
## dot for a crosshair (four fine ticks open round it as you strike or cast, red on a foe); the
## one in your sights named under it on a slim bar that fades in and out; your health, mana and
## stamina as three slim lines at the lower left that fade almost away while full and out of a
## fight; a red rim that flashes when you're hurt and pulses when you're near death.

var game
var _aim_a := 0.0                    # how much the sights' name shows (fades)
var _vit_a := 1.0                    # how much the vitals show (fade while full and calm)
var _last_hp := -1.0
var _hurt := 0.0                     # the red flash when hit (1 -> 0)
var _last_aim: Entity = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Called each frame by the game while first person is on.
func step(delta: float) -> void:
	if game == null or game.hero == null:
		return
	var hero: Entity = game.hero
	if _last_hp >= 0.0 and hero.hp < _last_hp - 0.5:
		_hurt = 1.0
	_last_hp = hero.hp
	_hurt = maxf(_hurt - delta * 1.8, 0.0)
	var aim: Entity = game.aimed
	if aim != null:
		_last_aim = aim
	_aim_a = move_toward(_aim_a, 1.0 if aim != null else 0.0, delta * (6.0 if aim != null else 2.5))
	var s := hero.stats
	var full := hero.hp >= float(s.max_hp()) - 0.5 and hero.mana >= float(s.max_mana()) - 0.5 \
		and hero.stamina >= float(s.max_stamina()) - 0.5
	var calm := hero.target == null and _hurt <= 0.0
	_vit_a = move_toward(_vit_a, 0.15 if full and calm else 1.0, delta * (0.6 if full and calm else 4.0))
	queue_redraw()


func _line(at: Vector2, w: float, frac: float, col: Color, a: float) -> void:
	draw_rect(Rect2(at, Vector2(w, 4)), Color(0, 0, 0, 0.45 * a))
	draw_rect(Rect2(at, Vector2(w * clampf(frac, 0.0, 1.0), 4)), Color(col, a))


func _draw() -> void:
	if game == null or game.hero == null:
		return
	var hero: Entity = game.hero
	var vs := get_viewport_rect().size
	var c := vs / 2.0
	var font := ThemeDB.fallback_font
	# letterbox: thin bars, soft-edged
	var bar := vs.y * 0.045
	for k in range(6):
		var a := 1.0 - k / 6.0
		draw_rect(Rect2(0, 0, vs.x, bar + k * 3.0), Color(0, 0, 0, 0.16 * a))
		draw_rect(Rect2(0, vs.y - bar - k * 3.0, vs.x, bar + k * 3.0), Color(0, 0, 0, 0.16 * a))
	draw_rect(Rect2(0, 0, vs.x, bar), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(0, vs.y - bar, vs.x, bar), Color(0, 0, 0, 0.85))
	# the red rim: a flash when hurt, a slow pulse near death
	var low := clampf(1.0 - hero.hp / maxf(float(hero.stats.max_hp()), 1.0) / 0.3, 0.0, 1.0)
	var rim := maxf(_hurt * 0.55, low * (0.25 + 0.15 * sin(Time.get_ticks_msec() * 0.006)))
	if rim > 0.01:
		for k in range(8):
			var w := 10.0 + k * 9.0
			var a := rim * (1.0 - k / 8.0) * 0.22
			draw_rect(Rect2(0, 0, w, vs.y), Color(0.7, 0.05, 0.03, a))
			draw_rect(Rect2(vs.x - w, 0, w, vs.y), Color(0.7, 0.05, 0.03, a))
			draw_rect(Rect2(0, bar, vs.x, w * 0.6), Color(0.7, 0.05, 0.03, a * 0.7))
			draw_rect(Rect2(0, vs.y - bar - w * 0.6, vs.x, w * 0.6), Color(0.7, 0.05, 0.03, a * 0.7))
	# the crosshair: a dot, and four fine ticks that open as you strike or cast
	var aim: Entity = game.aimed
	var foe := aim != null and aim.kind == Entity.Kind.MONSTER
	var col := Color(1.0, 0.4, 0.32) if foe else Color(1, 1, 1, 0.8)
	var open := 4.0
	if hero.swing_anim > 0.0:
		open += 6.0 * sin(hero.swing_anim / Entity.SWING_ANIM * PI)
	if hero.casting_id != "":
		open += 3.0 + 2.0 * sin(Time.get_ticks_msec() * 0.01)
	draw_circle(c, 2.6, Color(0, 0, 0, 0.5))
	draw_circle(c, 1.8, col)
	for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		draw_line(c + d * open, c + d * (open + 5.0), Color(0, 0, 0, 0.45), 3.0)
		draw_line(c + d * open, c + d * (open + 5.0), col, 1.4)
	# who's in your sights: a name and a slim bar, fading in and out
	var shown: Entity = aim if aim != null else _last_aim
	if _aim_a > 0.01 and shown != null and is_instance_valid(shown):
		var a := _aim_a
		var mhp := float(shown.stats.max_hp())
		var label: String = shown.display_name
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var at := c + Vector2(-w / 2.0, 30.0)
		draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color(0, 0, 0, 0.7 * a))
		draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(col, a))
		_line(c + Vector2(-34, 36), 68, shown.hp / maxf(mhp, 1.0), Color(0.9, 0.25, 0.2), a)
	# your vitals: three slim lines, lower left, above the letterbox
	var s := hero.stats
	var va := _vit_a
	var x := 24.0
	var y := vs.y - bar - 34.0
	_line(Vector2(x, y), 150, hero.hp / maxf(float(s.max_hp()), 1.0), Color(0.85, 0.25, 0.2), va)
	_line(Vector2(x, y + 8), 150, hero.mana / maxf(float(s.max_mana()), 1.0), Color(0.3, 0.5, 0.95), va)
	_line(Vector2(x, y + 16), 150, hero.stamina / maxf(float(s.max_stamina()), 1.0), Color(0.85, 0.72, 0.25), va)
	if va > 0.5:
		var t := "%d" % ceili(hero.hp)
		draw_string_outline(font, Vector2(x + 156, y + 6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 0.6 * va))
		draw_string(font, Vector2(x + 156, y + 6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.85, 0.8, va))
