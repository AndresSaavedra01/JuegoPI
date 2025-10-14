@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	# Change all node names to "modified_[oldnodename]"
	var mesh : MeshInstance3D = scene.get_child(0)
	mesh.create_convex_collision()
	return scene # Remember to return the imported scene
