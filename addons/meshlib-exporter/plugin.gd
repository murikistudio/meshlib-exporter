@tool
extends EditorPlugin


# Variables
var _can_save := true
var _extension := ".tres"


# Built-in overrides
func _apply_changes() -> void:
	var editor := get_editor_interface()
	var scene := editor.get_edited_scene_root()

	if not _can_save or not scene or not scene.name.capitalize().begins_with("Lib "):
		return

	var resource_name := scene.name.capitalize().to_lower().replace(" ", "_")
	var scene_name := ""
	var scene_path := ""

	for fn in editor.get_open_scenes():
		var filename := fn as String
		filename = filename.get_file().replace("." + filename.get_extension(), "")
		filename = filename.capitalize().to_lower().replace(" ", "_")

		if filename == resource_name:
			scene_name = filename
			scene_path = fn.replace(fn.get_file(), "")
			break

	if resource_name != scene_name:
		return

	var mesh_lib := MeshLibrary.new()

	for i in scene.get_child_count():
		var child: Node = scene.get_child(i)

		mesh_lib.create_item(i)
		mesh_lib.set_item_name(i, child.name)

		if child.scene_file_path:
			var base_filename := child.scene_file_path.get_file().replace("." + child.scene_file_path.get_extension(), "")
			var preview_path := child.scene_file_path.get_base_dir() + "/" + base_filename + "_preview.png"
			var preview_path_alt := child.scene_file_path.get_base_dir() + "/previews/" + base_filename + ".png"

			if FileAccess.file_exists(preview_path):
				mesh_lib.set_item_preview(i, load(preview_path))

			elif FileAccess.file_exists(preview_path_alt):
				mesh_lib.set_item_preview(i, load(preview_path_alt))

		_iterate_child(mesh_lib, i, child)

	var resource_path := scene_path + resource_name + _extension
	var resource_access := DirAccess.open(resource_path)

	if FileAccess.file_exists(resource_path) and resource_access:
		resource_access.remove(resource_path)

	_can_save = false
	ResourceSaver.save(mesh_lib, resource_path)
	prints("Saved", mesh_lib.get_item_list().size(), "items on", resource_path)
	await get_tree().create_timer(1.0).timeout
	_can_save = true


# Private methods
func _iterate_child(mesh_lib: MeshLibrary, i: int, node: Node):
	if node != null:
		if node is MeshInstance3D:
			mesh_lib.set_item_mesh(i, node.mesh)

		elif node is CollisionShape3D:
			mesh_lib.set_item_shapes(i, [node.shape])

		for child in node.get_children():
			_iterate_child(mesh_lib, i, child)
