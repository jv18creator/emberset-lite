extends Node3D
## Dark stage with a grid floor, glow and an orbit camera. Used by the gallery and the capture tool.

var camera := Camera3D.new()
var yaw := 0.6
var pitch := 0.28
var distance := 4.0
var target := Vector3(0.0, 0.8, 0.0)
## Stand-in character for status effects; hidden until an effect asks for it.
var dummy := MeshInstance3D.new()
## Props behind the origin for the frosted glass panes.
var props: Node3D


func _init() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.04, 0.055)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.7)
	env.ambient_light_energy = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	sun.light_energy = 0.12
	add_child(sun)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(160.0, 160.0)
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = load("res://demo/grid.gdshader")
	var ground := MeshInstance3D.new()
	ground.mesh = floor_mesh
	ground.material_override = floor_mat
	add_child(ground)

	# Backdrop shell: a plain background colour comes out lighter on Compatibility with glow on.
	var shell := SphereMesh.new()
	shell.radius = 60.0
	shell.height = 120.0
	shell.flip_faces = true
	var shell_mat := StandardMaterial3D.new()
	shell_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shell_mat.albedo_color = Color(0.035, 0.04, 0.055)
	var backdrop := MeshInstance3D.new()
	backdrop.mesh = shell
	backdrop.material_override = shell_mat
	add_child(backdrop)

	var body := CapsuleMesh.new()
	body.radius = 0.32
	body.height = 1.8
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.3, 0.32, 0.38)
	body_mat.roughness = 0.8
	dummy.mesh = body
	dummy.material_override = body_mat
	dummy.position.y = 0.9
	dummy.visible = false
	add_child(dummy)

	props = _make_props()
	add_child(props)

	camera.fov = 50.0
	add_child(camera)
	update_camera()


## Bright things to look at through the frosted glass panes; hidden for everything else.
func _make_props() -> Node3D:
	var out := Node3D.new()
	var spots := [[Vector3(-0.8, 1.9, -1.3), Color(1.0, 0.25, 0.2)], [Vector3(0.75, 1.7, -1.6), Color(1.0, 0.85, 0.2)], [Vector3(-0.35, 0.8, -1.2), Color(0.2, 0.9, 1.0)],
		[Vector3(0.6, 0.6, -1.9), Color(0.9, 0.3, 1.0)], [Vector3(0.0, 1.3, -2.4), Color(0.3, 1.0, 0.4)]]
	for i in spots.size():
		var m := MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = spots[i][1]
		if i % 2 == 0:
			var ball := SphereMesh.new()
			ball.radius = 0.3
			ball.height = 0.6
			m.mesh = ball
		else:
			var box := BoxMesh.new()
			box.size = Vector3(0.45, 0.45, 0.45)
			m.mesh = box
			m.rotation_degrees = Vector3(20, 35, 10)
		m.material_override = mat
		m.position = spots[i][0]
		out.add_child(m)
	var bars := MeshInstance3D.new()
	var bars_mat := StandardMaterial3D.new()
	bars_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bars_mat.albedo_color = Color(0.85, 0.87, 0.95)
	var pole := BoxMesh.new()
	pole.size = Vector3(0.06, 2.6, 0.06)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = pole
	multi.instance_count = 7
	for i in 7:
		multi.set_instance_transform(i, Transform3D(Basis(), Vector3(-1.2 + i * 0.4, 1.3, -3.0)))
	var grid := MultiMeshInstance3D.new()
	grid.multimesh = multi
	grid.material_override = bars_mat
	out.add_child(grid)
	out.visible = false
	return out


## Shows the dummy for effects that can coat a character, and hands it to them.
func present(fx: Node) -> void:
	dummy.material_overlay = null
	dummy.visible = fx.has_method("attach")
	props.visible = fx.scene_file_path.contains("/glass/")
	if props.visible:
		# Glass panes are looked at from the front, with the props behind them.
		yaw = 0.3
		pitch = 0.1
		update_camera()
	if dummy.visible:
		fx.call("attach", dummy)


func frame(dist: float, height: float) -> void:
	distance = dist
	target = Vector3(0.0, height, 0.0)
	update_camera()


func update_camera() -> void:
	pitch = clampf(pitch, -0.2, 1.4)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.look_at_from_position(target + offset, target)
