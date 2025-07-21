@tool
extends Control

var current_csv: CSVResource
var file_dialog: FileDialog
var save_dialog: FileDialog
var table_cells: Array = []
var selected_cells: Array = []
var current_file_path: String = ""

@onready var table_grid = $VBoxContainer/HSplitContainer/MainPanel/ScrollContainer/TableContainer/TableGrid
@onready var file_list = $VBoxContainer/HSplitContainer/FileBrowser/FileList
@onready var delete_button = $VBoxContainer/HSplitContainer/FileBrowser/DeleteButton
@onready var table_name_label = $VBoxContainer/HSplitContainer/MainPanel/InfoBar/TableName
@onready var dimensions_label = $VBoxContainer/HSplitContainer/MainPanel/InfoBar/DimensionsLabel
@onready var delimiter_label = $VBoxContainer/HSplitContainer/MainPanel/InfoBar/DelimiterLabel
@onready var status_label = $VBoxContainer/StatusBar/StatusLabel
@onready var open_button: Button = %OpenButton
@onready var save_button: Button = %SaveButton
@onready var save_as_button: Button = %SaveAsButton
@onready var new_button: Button = %NewButton
@onready var edit_headers_button: Button = %EditHeadersButton
@onready var delete_row_button: Button = %DeleteRowButton
@onready var delete_column_button: Button = %DeleteColumnButton

func _ready():
	_setup_file_dialogs()
	_refresh_file_list()
	_clear_table()
	_connect_signal()
	set_process_unhandled_key_input(true)

func _connect_signal():
	open_button.pressed.connect(_on_open_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	save_as_button.pressed.connect(_on_save_as_button_pressed)
	new_button.pressed.connect(_on_new_button_pressed)
	edit_headers_button.pressed.connect(_on_edit_headers_button_pressed)
	delete_row_button.pressed.connect(_on_delete_row_button_pressed)
	delete_column_button.pressed.connect(_on_delete_column_button_pressed)
	
func _setup_file_dialogs():
	# Create open file dialog
	file_dialog = FileDialog.new()
	file_dialog.title = "Open CSV File"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.csv;*.txt;CSV Files"])
	file_dialog.file_selected.connect(_on_file_dialog_file_selected)
	add_child(file_dialog)
	
	# Create save file dialog
	save_dialog = FileDialog.new()
	save_dialog.title = "Save CSV File"
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.filters = PackedStringArray(["*.txt;CSV Text Files"])
	save_dialog.file_selected.connect(_on_save_dialog_file_selected)
	add_child(save_dialog)

func _on_open_button_pressed():
	file_dialog.popup_centered_ratio(0.7)

func _on_save_button_pressed():
	if current_csv and not current_file_path.is_empty():
		if current_csv.save_to_file(current_file_path):
			status_label.text = "File saved successfully"
		else:
			status_label.text = "Failed to save file"
	elif current_csv:
		_on_save_as_button_pressed()

func _on_save_as_button_pressed():
	if current_csv:
		var filename = current_csv.table_name
		if not filename.ends_with("_csv"):
			filename += "_csv"
		filename += ".txt"
		save_dialog.current_file = filename
		save_dialog.popup_centered_ratio(0.7)

func _on_new_button_pressed():
	current_csv = CSVResource.new()
	current_csv.create_new_csv("New CSV", 3, 5)
	current_file_path = ""
	_populate_table()
	status_label.text = "New CSV created"

func _on_edit_headers_button_pressed():
	if not current_csv:
		status_label.text = "No CSV loaded"
		return
	
	_show_header_editor()

func _show_header_editor():
	# Create a popup for header editing
	var header_dialog = AcceptDialog.new()
	header_dialog.title = "Edit Headers"
	add_child(header_dialog)
	
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(400, 300)
	header_dialog.add_child(scroll_container)
	
	var vbox = VBoxContainer.new()
	scroll_container.add_child(vbox)
	
	# Create input fields for each header
	var header_inputs = []
	for i in range(current_csv.headers.size()):
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		var label = Label.new()
		label.text = "Column %d:" % (i + 1)
		label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(label)
		
		var line_edit = LineEdit.new()
		line_edit.text = str(current_csv.headers[i])
		line_edit.custom_minimum_size = Vector2(300, 0)
		hbox.add_child(line_edit)
		header_inputs.append(line_edit)
	
	# Add buttons for adding/removing columns and rows
	var column_button_container = HBoxContainer.new()
	vbox.add_child(column_button_container)
	
	var add_column_button = Button.new()
	add_column_button.text = "Add Column"
	add_column_button.pressed.connect(func():
		current_csv.add_column("New Column")
		header_dialog.queue_free()
		_show_header_editor()
	)
	column_button_container.add_child(add_column_button)
	
	var remove_column_button = Button.new()
	remove_column_button.text = "Remove Last Column"
	remove_column_button.pressed.connect(func():
		if current_csv.headers.size() > 1:
			current_csv.remove_column(current_csv.headers.size() - 1)
			header_dialog.queue_free()
			_show_header_editor()
	)
	column_button_container.add_child(remove_column_button)
	
	# Add batch row addition
	var row_section = VBoxContainer.new()
	vbox.add_child(row_section)
	
	var row_label = Label.new()
	row_label.text = "Add Rows:"
	row_section.add_child(row_label)
	
	var row_button_container = HBoxContainer.new()
	row_section.add_child(row_button_container)
	
	var row_count_input = SpinBox.new()
	row_count_input.min_value = 1
	row_count_input.max_value = 1000
	row_count_input.value = 5
	row_count_input.custom_minimum_size = Vector2(80, 0)
	row_button_container.add_child(row_count_input)
	
	var add_rows_button = Button.new()
	add_rows_button.text = "Add Rows"
	add_rows_button.pressed.connect(func():
		var count = int(row_count_input.value)
		current_csv.add_rows(count)
		status_label.text = "Added %d rows" % count
	)
	row_button_container.add_child(add_rows_button)
	
	# Connect the confirmed signal
	header_dialog.confirmed.connect(func():
		# Update headers with new values
		for i in range(header_inputs.size()):
			if i < current_csv.headers.size():
				current_csv.set_header(i, header_inputs[i].text)
		_populate_table()
		header_dialog.queue_free()
	)
	
	# Connect the cancelled signal
	header_dialog.canceled.connect(func():
		header_dialog.queue_free()
	)
	
	header_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String):
	_load_csv_file(path)

func _on_save_dialog_file_selected(path: String):
	if current_csv:
		if current_csv.save_to_file(path):
			current_file_path = path
			status_label.text = "File saved as: " + path.get_file()
			_refresh_file_list()
		else:
			status_label.text = "Failed to save file"

func _load_csv_file(path: String):
	var csv = CSVResource.new()
	if csv.load_from_file(path):
		current_csv = csv
		current_file_path = path
		_populate_table()
		status_label.text = "Loaded: " + path.get_file()
	else:
		status_label.text = "Failed to load: " + path.get_file()

func _populate_table():
	_clear_table()
	_clear_selection()
	
	if not current_csv:
		return
	
	# Update info labels
	table_name_label.text = current_csv.table_name
	var dims = current_csv.get_dimensions()
	dimensions_label.text = "%dx%d" % [dims.x, dims.y]
	delimiter_label.text = "Delimiter: " + current_csv.delimiter
	
	# Create headers
	var col = 0
	for header in current_csv.headers:
		var header_label = Label.new()
		header_label.text = str(header)
		header_label.add_theme_stylebox_override("normal", _create_header_style())
		header_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		header_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		header_label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
		header_label.add_theme_font_size_override("font_size", 12)
		header_label.add_theme_color_override("font_color", Color.WHITE)
		table_grid.add_child(header_label)
		col += 1
	
	# Create data cells
	for row_idx in range(current_csv.data.size()):
		for col_idx in range(current_csv.headers.size()):
			var cell_value = current_csv.get_cell(row_idx, col_idx)
			
			var line_edit = LineEdit.new()
			line_edit.text = cell_value
			line_edit.placeholder_text = ""
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
			line_edit.custom_minimum_size = Vector2(80, 25)
			line_edit.add_theme_stylebox_override("normal", _create_cell_style())
			line_edit.add_theme_stylebox_override("focus", _create_focus_style())
			
			# Store coordinates in metadata
			line_edit.set_meta("row", row_idx)
			line_edit.set_meta("col", col_idx)
			line_edit.text_changed.connect(_on_cell_text_changed.bind(line_edit))
			line_edit.gui_input.connect(_on_cell_gui_input.bind(line_edit))
			
			table_grid.add_child(line_edit)
			table_cells.append(line_edit)
	
	# Update grid columns
	table_grid.columns = current_csv.headers.size()
	
	# Connect data changed signal
	if !current_csv.data_changed.is_connected(_on_csv_data_changed):
		current_csv.data_changed.connect(_on_csv_data_changed)

func _clear_table():
	# Clear all children from grid
	for child in table_grid.get_children():
		child.queue_free()
	
	table_cells.clear()
	table_name_label.text = "No CSV loaded"
	dimensions_label.text = "0x0"
	delimiter_label.text = "Delimiter: ,"

func _create_header_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.3, 0.4, 1.0)
	style.border_color = Color(0.4, 0.5, 0.6, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

func _create_cell_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style

func _create_focus_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.35, 0.45, 1.0)
	style.border_color = Color(0.5, 0.7, 0.9, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	return style

func _on_cell_text_changed(new_text: String, cell: LineEdit):
	if not current_csv:
		return
	
	var row = cell.get_meta("row")
	var col = cell.get_meta("col")
	current_csv.set_cell(row, col, new_text)

func _on_csv_data_changed():
	# Update dimensions when data changes
	var dims = current_csv.get_dimensions()
	dimensions_label.text = "%dx%d" % [dims.x, dims.y]

func _unhandled_key_input(event: InputEvent):
	# 键盘快捷键支持
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			if event.shift_pressed:
				match event.keycode:
					KEY_1:
						# Ctrl+Shift+1 删除当前行
						var focused_row = _get_focused_row()
						if focused_row != -1:
							_delete_row_with_confirmation(focused_row)
							accept_event()
					KEY_2:
						# Ctrl+Shift+2 删除当前列
						var focused_col = _get_focused_column()
						if focused_col != -1:
							_delete_column_with_confirmation(focused_col)
							accept_event()
					KEY_3:
						# Ctrl+Shift+3 全选
						if Input.is_key_pressed(KEY_CTRL):
							_select_all_cells()
							accept_event()
					KEY_4:
						# Ctrl+Shift+4 取消选择
						_clear_selection()
						accept_event()

func _on_cell_gui_input(event: InputEvent, cell: LineEdit):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		# 右键点击显示菜单
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_show_cell_context_menu(cell)
			cell.accept_event()
		
		# Ctrl+左键点击进行多选
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if Input.is_key_pressed(KEY_CTRL):
				_toggle_cell_selection(cell)
				cell.accept_event()
			else:
				_clear_selection()

func _show_cell_context_menu(cell: LineEdit):
	var menu = PopupMenu.new()
	add_child(menu)
	
	var row = cell.get_meta("row")
	var col = cell.get_meta("col")
	
	# 添加菜单项
	menu.add_item("删除此行", 0)
	menu.add_item("删除此列", 1)
	menu.add_separator()
	menu.add_item("删除选中行", 2)
	menu.add_item("删除选中列", 3)
	
	# 根据是否有选中单元格来启用/禁用批量删除选项
	if selected_cells.size() == 0:
		menu.set_item_disabled(2, true)
		menu.set_item_disabled(3, true)
	
	# 连接菜单信号
	menu.id_pressed.connect(func(id):
		match id:
			0: _delete_row_with_confirmation(row)
			1: _delete_column_with_confirmation(col)
			2: _delete_selected_rows()
			3: _delete_selected_columns()
		menu.queue_free()
	)
	
	# 显示菜单位置 - 使用相对于视口的局部坐标
	var local_pos = get_viewport().get_mouse_position()
	menu.popup(Rect2(local_pos, Vector2(0, 0)))

func _toggle_cell_selection(cell: LineEdit):
	if selected_cells.has(cell):
		selected_cells.erase(cell)
		cell.remove_theme_color_override("font_color")
	else:
		selected_cells.append(cell)
		cell.add_theme_color_override("font_color", Color(1, 0.5, 0.2))

func _select_all_cells():
	_clear_selection()
	for cell in table_cells:
		if cell is LineEdit:
			selected_cells.append(cell)
			cell.add_theme_color_override("font_color", Color(1, 0.5, 0.2))

func _clear_selection():
	for cell in selected_cells:
		cell.remove_theme_color_override("font_color")
	selected_cells.clear()

func _delete_row_with_confirmation(row_index: int):
	if row_index < 0 or row_index >= current_csv.data.size():
		return
	
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.title = "确认删除行"
	confirm_dialog.dialog_text = "确定要删除第 %d 行吗？\n\n此操作不可撤销！" % (row_index + 1)
	add_child(confirm_dialog)
	
	confirm_dialog.confirmed.connect(func():
		current_csv.remove_row(row_index)
		_populate_table()
		status_label.text = "第 %d 行已删除" % (row_index + 1)
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered()

func _delete_column_with_confirmation(col_index: int):
	if col_index < 0 or col_index >= current_csv.headers.size():
		return
	
	var column_name = str(current_csv.headers[col_index])
	
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.title = "确认删除列"
	confirm_dialog.dialog_text = "确定要删除列 '%s' 吗？\n\n此操作不可撤销！" % column_name
	add_child(confirm_dialog)
	
	confirm_dialog.confirmed.connect(func():
		current_csv.remove_column(col_index)
		_populate_table()
		status_label.text = "列 '%s' 已删除" % column_name
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered()

func _delete_selected_rows():
	if selected_cells.size() == 0:
		return
	
	# 获取所有选中的行
	var rows_to_delete = []
	for cell in selected_cells:
		var row = cell.get_meta("row")
		if not rows_to_delete.has(row):
			rows_to_delete.append(row)
	
	rows_to_delete.sort()
	rows_to_delete.reverse()  # 从后往前删除，避免索引变化
	
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.title = "确认批量删除行"
	confirm_dialog.dialog_text = "确定要删除选中的 %d 行吗？\n\n此操作不可撤销！" % rows_to_delete.size()
	add_child(confirm_dialog)
	
	confirm_dialog.confirmed.connect(func():
		for row in rows_to_delete:
			current_csv.remove_row(row)
		_populate_table()
		_clear_selection()
		status_label.text = "已删除 %d 行" % rows_to_delete.size()
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered()

func _delete_selected_columns():
	if selected_cells.size() == 0:
		return
	
	# 获取所有选中的列
	var cols_to_delete = []
	for cell in selected_cells:
		var col = cell.get_meta("col")
		if not cols_to_delete.has(col):
			cols_to_delete.append(col)
	
	cols_to_delete.sort()
	cols_to_delete.reverse()  # 从后往前删除，避免索引变化
	
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.title = "确认批量删除列"
	confirm_dialog.dialog_text = "确定要删除选中的 %d 列吗？\n\n此操作不可撤销！" % cols_to_delete.size()
	add_child(confirm_dialog)
	
	confirm_dialog.confirmed.connect(func():
		for col in cols_to_delete:
			current_csv.remove_column(col)
		_populate_table()
		_clear_selection()
		status_label.text = "已删除 %d 列" % cols_to_delete.size()
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered()

func _refresh_file_list():
	file_list.clear()
	
	var project_dir = "res://"
	var csv_files = _find_csv_files(project_dir)
	
	for file_path in csv_files:
		var file_name = file_path.trim_prefix("res://")
		file_list.add_item(file_name, preload("res://addons/csv_manager/icons/csv_icon.svg"))
		# Store full path in metadata
		file_list.set_item_metadata(file_list.get_item_count() - 1, file_path)

func _find_csv_files(directory: String) -> Array:
	var csv_files = []
	var dir = DirAccess.open(directory)
	if not dir:
		return csv_files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = directory + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			# Recursively search subdirectories
			csv_files.append_array(_find_csv_files(full_path))
		elif file_name.contains("csv"):
			if file_name.ends_with(".txt") or file_name.ends_with(".csv"):
				csv_files.append(full_path)
		
		file_name = dir.get_next()
	
	return csv_files

func _on_file_selected(index: int):
	var file_path = file_list.get_item_metadata(index)
	_load_csv_file(file_path)

func _on_refresh_pressed():
	_refresh_file_list()
	status_label.text = "File list refreshed"

func _on_delete_row_button_pressed():
	if not current_csv or current_csv.data.size() == 0:
		status_label.text = "No data to delete"
		return
	
	# Try to get focused cell first
	var focused_row = _get_focused_row()
	if focused_row != -1:
		# Delete the row containing the focused cell
		_show_delete_row_confirmation(focused_row)
	else:
		# Fall back to selection dialog
		_show_delete_row_dialog()

func _on_delete_column_button_pressed():
	if not current_csv or current_csv.headers.size() == 0:
		status_label.text = "No columns to delete"
		return
	
	# Try to get focused cell first
	var focused_col = _get_focused_column()
	if focused_col != -1:
		# Delete the column containing the focused cell
		_show_delete_column_confirmation(focused_col)
	else:
		# Fall back to selection dialog
		_show_delete_column_dialog()

func _get_focused_row() -> int:
	# Find which LineEdit currently has focus
	for cell in table_cells:
		if cell is LineEdit and cell.has_focus():
			return cell.get_meta("row")
	return -1

func _get_focused_column() -> int:
	# Find which LineEdit currently has focus
	for cell in table_cells:
		if cell is LineEdit and cell.has_focus():
			return cell.get_meta("col")
	return -1

func _show_delete_row_confirmation(row_index: int):
	if row_index < 0 or row_index >= current_csv.data.size():
		return
	
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.title = "Confirm Row Deletion"
	confirm_dialog.dialog_text = "Are you sure you want to delete row %d?\n\nThis action cannot be undone!" % (row_index + 1)
	add_child(confirm_dialog)
	
	confirm_dialog.confirmed.connect(func():
		current_csv.remove_row(row_index)
		_populate_table()
		status_label.text = "Row %d deleted" % (row_index + 1)
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered()

func _show_delete_column_confirmation(col_index: int):
	if col_index < 0 or col_index >= current_csv.headers.size():
		return
	
	var column_name = str(current_csv.headers[col_index])
	
	# Check if column has any data
	var has_data = false
	for row in current_csv.data:
		if col_index < row.size() and str(row[col_index]) != "":
			has_data = true
			break
	
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.title = "Confirm Column Deletion"
	
	if has_data:
		confirm_dialog.dialog_text = "Column '%s' contains data.\n\nAre you sure you want to delete this column?\n\nThis action cannot be undone!" % column_name
	else:
		confirm_dialog.dialog_text = "Are you sure you want to delete column '%s'?\n\nThis action cannot be undone!" % column_name
	
	add_child(confirm_dialog)
	
	confirm_dialog.confirmed.connect(func():
		current_csv.remove_column(col_index)
		_populate_table()
		status_label.text = "Column '%s' deleted" % column_name
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered()

func _show_delete_row_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "Delete Row"
	add_child(dialog)
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var label = Label.new()
	label.text = "Select row to delete:"
	vbox.add_child(label)
	
	var row_selector = SpinBox.new()
	row_selector.min_value = 1
	row_selector.max_value = current_csv.data.size()
	row_selector.value = 1
	row_selector.custom_minimum_size = Vector2(100, 0)
	vbox.add_child(row_selector)
	
	# Warning label for data
	var warning_label = Label.new()
	warning_label.text = "Warning: This will permanently delete the selected row!"
	warning_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	vbox.add_child(warning_label)
	
	dialog.confirmed.connect(func():
		var row_index = int(row_selector.value) - 1  # Convert to 0-based index
		if row_index >= 0 and row_index < current_csv.data.size():
			# Show confirmation for data deletion
			var confirm_dialog = AcceptDialog.new()
			confirm_dialog.title = "Confirm Row Deletion"
			confirm_dialog.dialog_text = "Are you sure you want to delete row %d?\n\nThis action cannot be undone!" % (row_index + 1)
			add_child(confirm_dialog)
			
			confirm_dialog.confirmed.connect(func():
				current_csv.remove_row(row_index)
				_populate_table()
				status_label.text = "Row %d deleted" % (row_index + 1)
				confirm_dialog.queue_free()
			)
			
			confirm_dialog.canceled.connect(func():
				confirm_dialog.queue_free()
			)
			
			confirm_dialog.popup_centered()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	dialog.popup_centered()

func _show_delete_column_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "Delete Column"
	add_child(dialog)
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var label = Label.new()
	label.text = "Select column to delete:"
	vbox.add_child(label)
	
	var column_selector = SpinBox.new()
	column_selector.min_value = 1
	column_selector.max_value = current_csv.headers.size()
	column_selector.value = 1
	column_selector.custom_minimum_size = Vector2(100, 0)
	vbox.add_child(column_selector)
	
	var column_name_label = Label.new()
	column_name_label.text = "Column: %s" % str(current_csv.headers[0])
	vbox.add_child(column_name_label)
	
	# Update label when selection changes
	column_selector.value_changed.connect(func(value):
		var index = int(value) - 1
		if index >= 0 and index < current_csv.headers.size():
			column_name_label.text = "Column: %s" % str(current_csv.headers[index])
	)
	
	# Warning for data
	var warning_label = Label.new()
	warning_label.text = "Warning: This will permanently delete the selected column and all its data!"
	warning_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	vbox.add_child(warning_label)
	
	dialog.confirmed.connect(func():
		var col_index = int(column_selector.value) - 1  # Convert to 0-based index
		if col_index >= 0 and col_index < current_csv.headers.size():
			var column_name = str(current_csv.headers[col_index])
			
			# Check if column has any data
			var has_data = false
			for row in current_csv.data:
				if col_index < row.size() and str(row[col_index]) != "":
					has_data = true
					break
			
			if has_data:
				# Show confirmation for data deletion
				var confirm_dialog = AcceptDialog.new()
				confirm_dialog.title = "Confirm Column Deletion"
				confirm_dialog.dialog_text = "Column '%s' contains data.\n\nAre you sure you want to delete this column?\n\nThis action cannot be undone!" % column_name
				add_child(confirm_dialog)
				
				confirm_dialog.confirmed.connect(func():
					current_csv.remove_column(col_index)
					_populate_table()
					status_label.text = "Column '%s' deleted" % column_name
					confirm_dialog.queue_free()
				)
				
				confirm_dialog.canceled.connect(func():
					confirm_dialog.queue_free()
				)
				
				confirm_dialog.popup_centered()
			else:
				# No data, delete directly
				current_csv.remove_column(col_index)
				_populate_table()
				status_label.text = "Column '%s' deleted" % column_name
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	dialog.popup_centered()

func _on_delete_button_pressed():
	var selected_index = file_list.get_selected_items()
	if selected_index.size() == 0:
		status_label.text = "No file selected for deletion"
		return
	
	var file_path = file_list.get_item_metadata(selected_index[0])
	var file_name = file_path.get_file()
	
	# Create confirmation dialog with both confirm and cancel buttons
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.title = "Confirm Deletion"
	confirm_dialog.dialog_text = "Are you sure you want to delete:\n%s\n\nThis action cannot be undone!" % file_name
	add_child(confirm_dialog)
	
	confirm_dialog.confirmed.connect(func():
		_delete_file(file_path)
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered()

func _delete_file(file_path: String):
	var dir = DirAccess.open("res://")
	if dir.file_exists(file_path):
		var error = dir.remove(file_path)
		if error == OK:
			status_label.text = "File deleted: %s" % file_path.get_file()
			_refresh_file_list()
			
			# If the deleted file was the currently loaded one, clear the table
			if current_file_path == file_path:
				current_csv = null
				current_file_path = ""
				_clear_table()
		else:
			status_label.text = "Failed to delete file: %s" % file_path.get_file()
	else:
		status_label.text = "File not found: %s" % file_path.get_file()

func _drop_data(_position: Vector2, data: Variant):
	if typeof(data) == TYPE_DICTIONARY and data.has("files"):
		var files = data["files"]
		if files.size() > 0 and files[0].ends_with(".csv"):
			_load_csv_file(files[0])

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("files"):
		var files = data["files"]
		return files.size() > 0 and files[0].ends_with(".csv")
	return false

func _get_drag_data(_position: Vector2):
	if current_csv and not current_file_path.is_empty():
		var drag_data = {
			"files": [current_file_path],
			"type": "csv_file"
		}
		return drag_data
	return null
