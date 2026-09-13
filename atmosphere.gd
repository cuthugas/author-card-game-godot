extends Node3D

var flames: Array[OmniLight3D] = []
var elapsed := 0.0

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0a100e")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("758475")
	env.ambient_light_energy = 0.55
	world.environment = env
	add_child(world)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 8.5, 6.4)
	camera.look_at_from_position(camera.position, Vector3(0, 0, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.4
	add_child(camera)
	_box(Vector3(0,-0.3,0), Vector3(16,0.6,11), Color("201913"))
	_box(Vector3(0,0.015,0), Vector3(9.0,0.035,7.8), Color("172920"))
	for x in [-4.6,4.6]: _box(Vector3(x,0.025,0), Vector3(0.025,0.04,8.0), Color("897047"))
	for z in [-4.0,4.0]: _box(Vector3(0,0.025,z), Vector3(9.2,0.04,0.025), Color("897047"))
	for i in 19:
		_box(Vector3(-8.0+i*0.9,0.006,0),Vector3(0.012,0.012,11),Color("35291d"))
	for x in [-5.5,5.5]:
		for z in [-2.8,2.4]:
			_candle(Vector3(x,0.05,z))
	for i in 4:
		var book := _box(Vector3(-5.8,0.15+i*0.18,0.15),Vector3(1.35,0.17,1.75),Color("362c25") if i%2 else Color("29372e"))
		book.rotation.y = 0.12*i
		_box(Vector3(-5.8,0.17+i*0.18,0.15),Vector3(1.28,0.11,1.68),Color("9f9479"))
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55,-25,0)
	moon.light_color = Color("a5bbc2")
	moon.light_energy = 0.6
	add_child(moon)

func _box(pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.87
	instance.material_override = material
	add_child(instance)
	return instance

func _candle(pos: Vector3) -> void:
	_box(pos,Vector3(0.52,0.08,0.52),Color("a68b50"))
	_box(pos+Vector3(0,0.32,0),Vector3(0.21,0.65,0.21),Color("d6c29b"))
	var flame := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.26
	flame.mesh = sphere
	flame.position = pos+Vector3(0,0.75,0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffcd78")
	mat.emission_enabled = true
	mat.emission = Color("ffb24b")
	mat.emission_energy_multiplier = 3
	flame.material_override = mat
	add_child(flame)
	var light := OmniLight3D.new()
	light.position = flame.position+Vector3(0,0.2,0)
	light.light_color = Color("ffc47e")
	light.omni_range = 4.5
	light.light_energy = 1.3
	add_child(light)
	flames.append(light)

func _process(delta: float) -> void:
	elapsed += delta
	for i in flames.size(): flames[i].light_energy = 1.2 + sin(elapsed*3.5+i)*0.13 + sin(elapsed*8.1+i)*0.07
