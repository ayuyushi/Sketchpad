extends GutTest

var canvas_scene: PackedScene = load("res://system/canvas/canvas.tscn")
var canvas: Canvas
var project: Project

var width: int = 100
var height: int = 200


func before_each():
	var rs = RenderingServer
	canvas = canvas_scene.instantiate()
	add_child(canvas)
	add_child(rs)
	project = Project.new()
	project.new_project(width, height)
	canvas.attach_project(project)


# -- Canvas Tests --


func test_canvas_render_page():
	var page = project.get_current_page()
	canvas.render_page(page)
	assert_eq(
		canvas.layers_node.get_child_count(), page.layers.size(), "Canvas should render all layers"
	)


func test_canvas_has_onion_skin_renderer():
	var renderer = canvas.get_node("Control/OnionSkin")
	assert_not_null(renderer, "Canvas should have onion skin renderer node")


func test_canvas_toggle_onion_skin_works():
	var renderer = canvas.onion_skin_renderer

	assert_false(renderer.enabled, "Onion skin should start disabled")

	canvas.toggle_onion_skin()
	assert_true(renderer.enabled, "toggle_onion_skin should enable onion skin")

	canvas.toggle_onion_skin()
	assert_false(renderer.enabled, "toggle_onion_skin should disable onion skin again")


func test_canvas_set_onion_skin_depth_works():
	var renderer = canvas.onion_skin_renderer

	canvas.set_onion_skin_depth(5)
	assert_eq(renderer.depth, 5, "Depth should be set to 5")

	canvas.set_onion_skin_depth(1)
	assert_eq(renderer.depth, 1, "Depth should be set to 1")

	canvas.set_onion_skin_depth(0)
	assert_eq(renderer.depth, 1, "Depth should never be lower than 1")


func test_undo_restores_previous_active_layer_image():
	var page := project.get_current_page()
	var layer_index := project.current_layer
	var layer := page.layers[layer_index]
	var pixel := Vector2i(10, 10)
	var original_color := layer.get_pixelv(pixel)

	canvas.begin_undo_action()
	layer.set_pixelv(pixel, Color.RED)
	page.set_layer(layer_index, layer)
	canvas.commit_undo_action()

	assert_true(canvas.undo(), "Undo should restore the previous painting state")
	assert_eq(
		page.layers[layer_index].get_pixelv(pixel),
		original_color,
		"Undo should restore the previous active-layer pixel"
	)


func test_undo_history_is_limited_to_twenty_actions():
	var page := project.get_current_page()
	var layer_index := project.current_layer
	var layer := page.layers[layer_index]
	var pixel := Vector2i(10, 10)

	for action_index in range(21):
		canvas.begin_undo_action()
		layer.set_pixelv(pixel, Color(float(action_index + 1) / 21.0, 0, 0, 1))
		page.set_layer(layer_index, layer)
		canvas.commit_undo_action()

	for _action_index in range(20):
		assert_true(canvas.undo(), "Each of the most recent twenty actions should be undoable")

	assert_almost_eq(
		page.layers[layer_index].get_pixelv(pixel).r,
		1.0 / 21.0,
		0.005,
		"Undo history should discard the oldest action after reaching its limit"
	)

# TODO - Create unit tests and investigate GUT and RenderingServer issues.
# func test_bake():
# 	var rect = ColorRect.new()
# 	canvas.dynamic_node.add_child(rect)

# 	canvas.bake_page()

# 	assert_eq(canvas.dynamic_node.get_child_count(), 0, "Verify bake clearing dynamic")
# 	assert_eq(canvas.bake_node.get_child_count(), 0, "Verify bake clearing viewport")
