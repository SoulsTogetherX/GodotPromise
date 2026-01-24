@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type(
		"GodotPromise",
		"RefCounted",
		load("uid://co0qail5t6ki6"),
		load("uid://k5shot7mo40d")
	)
	add_custom_type(
		"GodotPromiseEx",
		"RefCounted",
		load("uid://beymcq10l761i"),
		load("uid://d0rvuugj5wsqt")
	)
func _exit_tree() -> void:
	remove_custom_type("GodotPromise")
	remove_custom_type("GodotPromiseEx")
