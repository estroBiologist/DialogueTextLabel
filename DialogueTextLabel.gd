extends RichTextLabel
class_name DialogueTextLabel

signal line_finished
signal advance_dialog

const WORDJOINER := "⁠" # Invisible character


var regex := RegEx.new() as RegEx

var text_speed_multiplier 		:= 1.0
var timer 						:= 0.0
var pause_buffer 				:= 0
var realtime_wait 				:= 0.0
var skipping_line 				:= false
var processed_char_commands 	:= 0
var total_char_commands 		:= 0

var play_sound := true
var is_line_finished := false

export var text_speed := 30.0 # per second
export var show_character_name := false
export var voice_player : NodePath
export var expression_base_node : NodePath

onready var audio_stream_player := get_node(voice_player) as AudioStreamPlayer if not voice_player.is_empty() else null


class DialogLine:
	extends Reference
	
	var text := ""
	var name := ""
	var autopunc := false
	
	# Other data you need per line (character names, expressions, etc) goes here


var current_line : DialogLine = null
var current_text := ""
var current_commands := {} # Maps character indices to arrays of commands


static func quick_line(text: String, name := "") -> DialogLine:
	var line := DialogLine.new()
	line.text = text
	line.name = name
	return line

	
func set_new_text(new_line: DialogLine):
	skipping_line = false
	is_line_finished = false
	visible_characters = 0
	
	current_commands = {}
	processed_char_commands = 0
	total_char_commands = 0
			
	current_line = new_line
	
	if show_character_name:
		current_text = current_line.name + ": " + current_line.text
	else:
		current_text = current_line.text
	
	current_text = parse_escape_sequences(current_text)

	# Now for the parsing
	
	# 1. Parse BBCode out of source text
	# 2. Feed BBCode output text to command parser
	# 3. Remove commands from the original text and put it through 
	# the BBCode parser *again* to get final output text
	
	bbcode_text = current_text
	var parse_result = parse_line_commands(text, current_line.autopunc)
	bbcode_text = remove_commands(current_text)
	
	for command in parse_result:
		var command_index = command.index
		command.erase("index")
	
		if not current_commands.has(command_index):
			current_commands[command_index] = []
			
		current_commands[command_index].append(command)
	
	timer = 0.0
	
	if show_character_name:
		visible_characters = current_line.name.length() + 2 # To account for the colon and space

	
	
func skip_line():
	skipping_line = true
	
	
func _ready():	
	# first off. i apologize
	regex.compile(	"(/{[^!][^/}]*[^!/}]/})".replace("/", "\\").replace("!", WORDJOINER))
	
	# I use replace twice there to make the regex somewhat more readable
	# Forward slashes become backslashes, and exclamation marks become WORDJOINER,
	# which is the invisible character we use to prevent the label from parsing
	# out the BBCode and commands when they're escaped
	# (see also: parse_escape_sequences())
	
	
func _process(delta):
	if not current_line: 
		return
	
	while realtime_wait > 0.0:
		realtime_wait = max(realtime_wait - delta, 0.0)
		return

	
	var current_text_speed := text_speed * text_speed_multiplier
	
	
	# Don't advance more than one character per frame
	var capped_delta = min(delta, 1.0 / current_text_speed)
	timer += capped_delta
	
	
	# Get number of commands on the current character
	total_char_commands = current_commands.get(visible_characters, []).size()
	
	var char_count : int = text.length()
	var char_delay = 1.0 / current_text_speed
	var current_char := get_char_at_index(current_line.text, visible_characters)
	var skipping_char := is_instant_char(current_char)

	# Text advance loop.
	# Yes, it has to be like this. I'm sorry.
	# Just let it do its magic.
	
	while (timer > char_delay or skipping_line or skipping_char) and realtime_wait == 0.0 and visible_characters <= char_count:
		timer = max(timer - char_delay, 0)
		
		if pause_buffer == 0:
			# Process commands
			if processed_char_commands < total_char_commands:
				for i in range(processed_char_commands, total_char_commands):
					handle_command(current_commands[visible_characters][i])
						
					processed_char_commands += 1
				
					# Pause buffer or wait timer might have been set by command, in which case we stop processing commands for now
					if pause_buffer > 0 or realtime_wait > 0.0:
						break
						
		else:
			pause_buffer -= 1
			
			
		# Check if ready to go to next character
		if processed_char_commands >= total_char_commands and ((pause_buffer == 0 or skipping_line) and realtime_wait == 0):
			if visible_characters == char_count:
				break # Done
				
			total_char_commands = current_commands.get(visible_characters + 1, []).size()
			processed_char_commands = 0

			if not skipping_line and not skipping_char and play_sound and current_char != " ":
				if audio_stream_player:
					audio_stream_player.play()
				
			visible_characters += 1
			
			
	# End of text advance loop
	
				
	# Check if finished with the line
	if realtime_wait == 0 and visible_characters >= char_count and processed_char_commands == total_char_commands:
		if not is_line_finished:
			is_line_finished = true
			skipping_line = false
			
			emit_signal("line_finished")
	else:
		is_line_finished = false




#
# Line parsing
#


static func parse_escape_sequences(var txtline: String):
	var escaped_state := false
	var result := ""
	var is_percent_closing = false
	
	for c in txtline:
		if escaped_state:
			match c:
				"t":
					result += "\t"
				"n":
					result += "\n"
				"r":
					result += "\r"
					
				"[", "{":
					result += c + WORDJOINER
				"]", "}":
					result += WORDJOINER + c
					
				"%":
					if is_percent_closing:
						result += WORDJOINER + c
					else:
						result += c + WORDJOINER
						
					
				"\\", "\"":
					result += c
				_:
					printerr("Unrecognized escape sequence '\\", c, "'.")
					result += "\\" + c
			escaped_state = false
		else:
			match c:
				"\\":
					escaped_state = true
				"%":
					is_percent_closing = !is_percent_closing
					result += c
				_:
					result += c
	
	return result
	

func remove_commands(var txtline: String):		
		
	var search_result = regex.search(txtline)
	while search_result != null:
		var txtline_result = ""
		if search_result.get_start() > 0:
			txtline_result += txtline.substr(0, search_result.get_start())
		
		if search_result.get_end() < txtline.length():
			txtline_result += txtline.substr(search_result.get_end()) # Account for non-WJ match
		
		txtline = txtline_result
		search_result = regex.search(txtline)
	
	return txtline
	

static func get_pause_len(c):
	match c:
		".", "?", "!", ":":
			return 20
		",", ";":
			return 10
		_:
			return 0
		
		
func parse_line_commands(txtline: String, autopunc: bool):
	var commands := []
	
	# Search for command tags
	var search_result = regex.search(txtline)
	
	while search_result != null:
		var command := {} 
		
		var index_offset = txtline.substr(0, search_result.get_start()).count("\n")
		
		# the wonders of weak typing
		var substrings = search_result.get_string(1)
		substrings = substrings.substr(1, substrings.length() - 2)
		substrings = substrings.split(" ")
		substrings = Array(substrings)
		
		command["index"] = search_result.get_start() - index_offset
		command["name"] = substrings[0]
		command["args"] = substrings.slice(1, substrings.size() - 1)
		command["raw"] = search_result.get_string(1)
		commands.push_back(command)
		
		#Remove command from string
		var txtline_result = ""
		if search_result.get_start() > 0:
			txtline_result += txtline.substr(0, search_result.get_start())
		
		if search_result.get_end() < txtline.length():
			txtline_result += txtline.substr(search_result.get_end())
		
		txtline = txtline_result
		
		
		search_result = regex.search(txtline)
	
	# Autopunc handling
	
	if autopunc:
		for i in txtline.length() - 1: # Don't put pause on last character
			if txtline[i+1] != ")":
				if get_pause_len(txtline[i]) > 0 and (i + 1 == txtline.length() or get_pause_len(txtline[i]) != get_pause_len(txtline[i+1])):
					var command := {}
					command.name = "p"
					command.args = []
					command.index = i + 1 - txtline.substr(0, i).count("\n")
				
					command.args.append(str(get_pause_len(txtline[i])))
				
					commands.push_back(command)

	return commands
	
	

func handle_command(command: Dictionary):
	match command.name:
		"pause", "p":
			pause_buffer = command.args[0].to_int()
		
		"speed", "sp":
			text_speed_multiplier = command.args[0].to_float()
		
		"advance", "a":
			emit_signal("advance_dialog")
		
		"waitsec", "w":
			realtime_wait = command.args[0].to_float()
		
		# Sayonara, kansas
		
		#"event", "e":
		#	process_event(command)
		
		_:
			print("WARN: Unrecognized dialog command: ", command.name)



func split_args(param_list: String):
	var stack_depth := 0
	var args := []
	var prev_idx := 0
	
	for i in param_list.length():
		match param_list[i]:
			",":
				if stack_depth == 0:
					args.append(param_list.substr(prev_idx, i - prev_idx))
					prev_idx = i + 1
			"(":
				stack_depth += 1
			")":
				stack_depth -= 1
	
	if stack_depth != 0:
		printerr("Unmatched '(' and ')' in parameter list.")
		return null
		
	args.append(param_list.substr(prev_idx))
	return args
	


# This is where event handling would happen in the `main` branch, but we're not
# about that fast-and-loose shit here. This is STABILITY TOWN, motherfucker.



func parse_expr(expr_txt: String, flags := {}):
	var expr = Expression.new()
	var error = expr.parse(expr_txt, PoolStringArray(flags.keys()))
	
	if error != OK:
		return
	
	# You could point this to a singleton or other script, to give the
	# expression parser extra functions and variables to use.
	#
	# (https://docs.godotengine.org/en/stable/tutorials/scripting/evaluating_expressions.html)
	
	var result = expr.execute(flags.values(), get_node(expression_base_node), true)
	
	if expr.has_execute_failed():
		printerr("Failed to execute expression: ", expr_txt)
		
	return result



# Could be extended if you want certain characters to be skipped.
# Not entirely sure the skipping works properly though
static func is_instant_char(c) -> bool:
	match c:
		WORDJOINER:
			return true
		_:
			return false
			

# RichTextLabel doesn't count newlines in visible_characters, so we correct for
# it to get the right character index here.
static func get_corrected_index(txtline: String, idx: int) -> int:
	return idx - txtline.substr(0, idx).count("\n")


static func get_char_at_index(txtline: String, idx: int) -> String:
	var correct_index := get_corrected_index(txtline, idx)
	if correct_index >= txtline.length():
		return ""
	return txtline[correct_index]
	
