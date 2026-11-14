extends Node3D
## Emberset effect browser: pick an effect from the list, orbit with the mouse, replay with Space.


var _stage: Node3D
var _effects: Array = []
var _current := -1
var _fx: Node3D
var _entry: Dictionary
var _clock := 0.0
var _replay_at := -1.0
var _tree: Tree
var _title: Label
var _info: Label
var _hue: HSlider
var _spin: CheckButton
var _dragging := false
var _items: Array[TreeItem] = []


func _ready() -> void:
	_stage = load("res://demo/stage.gd").new()
	add_child(_stage)
	# One index file per pack; the gallery shows whichever packs are installed.
	for pack in ["index", "index_combat"]:
		var path := "res://addons/emberset/effects/%s.json" % pack
		if FileAccess.file_exists(path):
			_effects.append_array(JSON.parse_string(FileAccess.get_file_as_string(path)))
	_build_ui()
	_show(0)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var side := PanelContainer.new()
	side.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	side.custom_minimum_size.x = 250
	layer.add_child(side)
	var box := VBoxContainer.new()
	side.add_child(box)
	var head := Label.new()
	head.text = "EMBERSET  -  %d scenes" % _effects.size()
	box.add_child(head)
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.focus_mode = Control.FOCUS_NONE
	box.add_child(_tree)
	var root := _tree.create_item()
	var groups := {}
	for i in _effects.size():
		var e: Dictionary = _effects[i]
		if not groups.has(e.category):
			var g := _tree.create_item(root)
			g.set_text(0, (e.category as String).capitalize())
			g.set_selectable(0, false)
			groups[e.category] = g
		var item := _tree.create_item(groups[e.category])
		# Colour variants sit under their original, indented.
		item.set_text(0, "      " + (e.color as String).capitalize() if e.has("color") else (e.name as String).capitalize())
		item.set_metadata(0, i)
		_items.append(item)
	_tree.item_selected.connect(func() -> void:
		var picked: int = _tree.get_selected().get_metadata(0)
		if picked != _current:
			_show(picked))

	var hue_label := Label.new()
	hue_label.text = "Hue shift"
	box.add_child(hue_label)
	_hue = HSlider.new()
	_hue.min_value = 0.0
	_hue.max_value = 1.0
	_hue.step = 0.01
	_hue.focus_mode = Control.FOCUS_NONE
	_hue.value_changed.connect(func(_v: float) -> void: _show(_current))
	box.add_child(_hue)
	_spin = CheckButton.new()
	_spin.text = "Auto orbit"
	_spin.button_pressed = true
	_spin.focus_mode = Control.FOCUS_NONE
	box.add_child(_spin)

	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	top.position = Vector2(270, 12)
	layer.add_child(top)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	top.add_child(_title)
	_info = Label.new()
	_info.modulate = Color(1, 1, 1, 0.7)
	top.add_child(_info)


func _show(i: int) -> void:
	if _fx:
		_fx.queue_free()
	_current = wrapi(i, 0, _effects.size())
	_entry = _effects[_current]
	_items[_current].select(0)
	_tree.scroll_to_item(_items[_current])
	if ResourceLoader.exists(_entry.path):
		_fx = load(_entry.path).instantiate()
		_fx.set("hue_shift", _hue.value)
	else:
		# The browser demo leaves the colour scenes out to stay small and recolours the original instead.
		_fx = load(_entry.base).instantiate()
		_fx.set("hue_shift", fposmod(_entry.hue_shift + _hue.value, 1.0))
		_fx.set("tint", Color.html(_entry.tint))
	_fx.position = Vector3(0, _entry.lift, 0)
	if _entry.move:
		_fx.rotation.y = -PI / 2.0
	_stage.add_child(_fx)
	# Status effects get a stand-in character to coat.
	_stage.present(_fx)
	_stage.frame(_entry.cam, _entry.height)
	_stage.target.z = _entry.look_z
	_stage.update_camera()
	_clock = 0.0
	_replay_at = -1.0
	_title.text = "%s / %s" % [(_entry.category as String).capitalize(), (_entry.name as String).capitalize()]
	_info.text = "%s   |   %s   |   Space: replay   Up/Down: next   Drag: orbit   Wheel: zoom" % [
		"loop" if _entry.loop else "one-shot %.1fs" % _entry.duration, (_entry.path as String).trim_prefix("res://")]
	if not _entry.loop:
		_fx.connect("finished", func() -> void: _replay_at = _clock + 0.6)


func _process(delta: float) -> void:
	_clock += delta
	if _spin.button_pressed and not _dragging and _entry.category != "glass":
		_stage.yaw += delta * 0.25
		_stage.update_camera()
	if _fx and _fx.has_method("hit") and fmod(_clock, 1.4) < delta:
		# Shields: a hit from a random side every 1.4 seconds.
		_fx.call("hit", _fx.global_position + Vector3(randf() - 0.5, randf() - 0.3, randf() - 0.5).normalized() * 1.3)
	if _fx and _entry.move:
		_fx.position.x = -3.0 + fmod(_clock * 3.0, 6.0)
	if _replay_at > 0.0 and _clock >= _replay_at:
		_replay_at = -1.0
		_fx.call("play")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_stage.distance = maxf(_stage.distance * 0.9, 1.0)
			_stage.update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_stage.distance = minf(_stage.distance * 1.1, 20.0)
			_stage.update_camera()
	elif event is InputEventMouseMotion and _dragging:
		_stage.yaw -= event.relative.x * 0.008
		_stage.pitch += event.relative.y * 0.006
		_stage.update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_fx.call("play")
			KEY_DOWN, KEY_RIGHT:
				_show(_current + 1)
			KEY_UP, KEY_LEFT:
				_show(_current - 1)
