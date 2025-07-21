@tool
class_name CSVParser

var delimiter: String = ","
var quote_char: String = "\""

func parse(text: String) -> Array:
	var result = []
	var lines = text.split("\n", false)
	
	for line in lines:
		if line.strip_edges().is_empty():
			continue
			
		var row = parse_line(line)
		if row.size() > 0:
			result.append(row)
	
	return result

func parse_line(line: String) -> Array:
	var result = []
	var current = ""
	var in_quotes = false
	var i = 0
	
	while i < line.length():
		var c = line[i]
		
		if c == quote_char:
			if in_quotes and i + 1 < line.length() and line[i + 1] == quote_char:
				# Escaped quote
				current += quote_char
				i += 1
			else:
				# Toggle quote state
				in_quotes = !in_quotes
			
		elif c == delimiter and !in_quotes:
			result.append(current)
			current = ""
		
		elif c == "\r":
			# Skip carriage return
			pass
		
		else:
			current += c
		
		i += 1
	
	# Add the last field
	result.append(current)
	
	return result
