@tool
extends EditorPlugin

const CSV_DOCK_SLOT = DOCK_SLOT_RIGHT_UR
const CSV_DOCK_NAME = "CSV"
const CSV_DOCK_TSCN = preload("res://addons/csv_manager/csv_dock.tscn")
const CSV_ICON = preload("res://addons/csv_manager/icons/csv.png")
var csv_dock: Control

func _enter_tree():
	# Create and add CSV dock to AssetLib panel
	csv_dock = CSV_DOCK_TSCN.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(csv_dock)
	csv_dock.hide()
	csv_dock.name = CSV_DOCK_NAME
	# Add CSV file type to editor
	add_custom_type("CSVFile", "Resource", preload("res://addons/csv_manager/csv_resource.gd"), preload("res://addons/csv_manager/icons/csv_icon.svg"))

func _exit_tree():
	csv_dock.queue_free()
	remove_custom_type("CSVFile")

func _make_visible(visible: bool) -> void:
	if not CSV_DOCK_TSCN: return
	csv_dock.visible = visible

func _has_main_screen() -> bool:
	return Engine.is_editor_hint()

func _get_plugin_name() -> String:
	return "CsvManager"

func _get_plugin_icon() -> Texture2D:
	return CSV_ICON
