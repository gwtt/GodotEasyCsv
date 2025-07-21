@tool
extends Resource
class_name CSVResource

@export var file_path: String = ""
@export var delimiter: String = ","
@export var encoding: String = "UTF-8"
@export var data: Array = []
@export var headers: Array = []
@export var table_name: String = ""

signal data_changed

func load_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	
	file_path = path
	table_name = path.get_file().get_basename()
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	
	var content = file.get_as_text()
	file.close()
	
	# Detect delimiter
	delimiter = _detect_delimiter(content)
	
	# Parse CSV
	var parser = CSVParser.new()
	parser.delimiter = delimiter
	var result = parser.parse(content)
	
	if result.size() > 0:
		headers = result[0]
		data = result.slice(1, result.size())
		data_changed.emit()
		return true
	
	return false

func save_to_file(path: String = "") -> bool:
	if path.is_empty():
		path = file_path
	
	if path.is_empty():
		return false
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	
	var content = _to_csv_string()
	file.store_string(content)
	file.close()
	
	file_path = path
	table_name = path.get_file().get_basename()
	return true

func _detect_delimiter(content: String) -> String:
	var lines = content.split("\n")
	if lines.size() == 0:
		return ","
	
	var first_line = lines[0]
	var comma_count = first_line.count(",")
	var semicolon_count = first_line.count(";")
	var tab_count = first_line.count("\t")
	
	if semicolon_count > comma_count and semicolon_count > tab_count:
		return ";"
	elif tab_count > comma_count and tab_count > semicolon_count:
		return "\t"
	else:
		return ","

func _to_csv_string() -> String:
	var result = PackedStringArray()
	
	# Add headers
	if headers.size() > 0:
		result.append(_escape_row(headers))
	
	# Add data rows
	for row in data:
		result.append(_escape_row(row))
	
	return "\n".join(result)

func _escape_row(row: Array) -> String:
	var escaped = PackedStringArray()
	for cell in row:
		var str = str(cell)
		if str.contains(",") or str.contains("\"") or str.contains("\n"):
			str = "\"" + str.replace("\"", "\"\"") + "\""
		escaped.append(str)
	return ",".join(escaped)

func get_dimensions() -> Vector2i:
	var cols = max(headers.size(), 0)
	var rows = data.size()
	return Vector2i(cols, rows)

func get_cell(row: int, col: int) -> String:
	if row < 0 or row >= data.size():
		return ""
	if col < 0 or col >= data[row].size():
		return ""
	return str(data[row][col])

func set_cell(row: int, col: int, value: String) -> void:
	if row < 0 or row >= data.size():
		return
	if col < 0:
		return
	
	# Ensure row has enough columns
	while data[row].size() <= col:
		data[row].append("")
	
	data[row][col] = value
	data_changed.emit()

func add_row() -> void:
	var new_row = []
	var cols = max(headers.size(), 1)
	for i in cols:
		new_row.append("")
	data.append(new_row)
	data_changed.emit()

func add_rows(count: int) -> void:
	if count <= 0:
		return
	
	var cols = max(headers.size(), 1)
	for i in range(count):
		var new_row = []
		for j in range(cols):
			new_row.append("")
		data.append(new_row)
	data_changed.emit()

func add_column(name: String = "") -> void:
	headers.append(name)
	for row in data:
		row.append("")
	data_changed.emit()

func remove_row(index: int) -> void:
	if index >= 0 and index < data.size():
		data.remove_at(index)
		data_changed.emit()

func remove_column(index: int) -> void:
	if index >= 0 and index < headers.size():
		headers.remove_at(index)
		for row in data:
			if index < row.size():
				row.remove_at(index)
		data_changed.emit()

func set_header(index: int, name: String) -> void:
	if index >= 0 and index < headers.size():
		headers[index] = name
		data_changed.emit()

func create_new_csv(name: String = "New CSV", initial_columns: int = 3, initial_rows: int = 5) -> void:
	file_path = ""
	table_name = name
	headers.clear()
	data.clear()
	
	# Create initial headers
	for i in range(initial_columns):
		headers.append("Column %d" % (i + 1))
	
	# Create initial data rows
	for i in range(initial_rows):
		var row = []
		for j in range(initial_columns):
			row.append("")
		data.append(row)
	
	data_changed.emit()
