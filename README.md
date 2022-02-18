# DialogueTextLabel
**DialogueTextLabel** is an extension of Godot's `RichTextLabel`, designed for advanced dialogue systems of all kinds.

Originally built for my own game, **CHORDIOID**, this script is a stripped-down, more modular version of that cluttered mess.

It handles the logistical nightmare of displaying text with embedded commands and formatting properly, so you can focus on the *other* nightmare of creating a half-decent backend that feeds the lines into the label in the first place. 

## Features
- Escape sequences. This one's pretty self-explanatory.
- **"Typewriter" effect**: Lines are automatically presented one character at a time, with customizable speeds
- **Robust embedded command system:** 
	- Insert pauses, text speed changes, calls to other Nodes, all embedded in the text with a simple `{curly brace}` syntax
	- Works in harmony with BBCode, and adds the ability to use escape sequences on both
	- Inline expression evaluation
	- Toggleable automatic pauses after punctuation
- **Integration with your systems:** 
	- Using the group `dia_event`, Nodes can register themselves to receive calls to `dia_event(name, args)` whenever the `{event}` command is used in dialogue.
	- Use the `expression_base_node` property to expose your own variables and functions to the expression system.

## Usage

Use `set_new_text(new_line: DialogLine)` to start a new line. `DialogLine` is a class defined in the script that looks like this:

![DialogLine class description: extends Reference, two variables of type String called text and name, and a boolean called autopunc.](https://media.discordapp.net/attachments/857262465876099083/944330156397457488/unknown.png)

If you want a text advance sound, hook up an `AudioStreamPlayer` via the exported `voice_player` property.

That's about it.

## Showcase

![This is a DialogueTextLabel demonstration!](https://media.discordapp.net/attachments/857262465876099083/944323210546122842/gif01.gif)\
*Figure 1: graphic design is my passion*


![Look, I can use BBCode, or [color=yellow]escape it[/color]!](https://media.discordapp.net/attachments/857262465876099083/944323210730676264/gif02.gif)\
*Figure 2: they wont tell you what bbcode stands for but i know. it stands for bo-*


![Autopunc is on, which automatically puts pauses after punctuation.](https://media.discordapp.net/attachments/857262465876099083/944323209501765652/gif03.gif)

![But you can also do it manually!](https://media.discordapp.net/attachments/857262465876099083/944323209715658752/gif04.gif)\
*Figures 3, 4: i dont have a funny joke for these ones. its just a neat feature*

![As for the event system... Walter, would you help me demonstrate?](https://media.discordapp.net/attachments/857262465876099083/944323209954746450/gif05.gif)
![Thank you. Now, then: Watch as I turn Walter White... into Walter Wide.](https://media.discordapp.net/attachments/857262465876099083/944323210189602836/gif06.gif)
![As you can see, anything's possible with the event system! Thank you, Walter.](https://media.discordapp.net/attachments/857262465876099083/944323210369978408/gif07.gif)\
*Figures 5, 6, 7: jesy*

(Text used:)

```
var lines = [
	"This is a DialogueTextLabel demonstration!", 
	"Look, I can use [color=yellow]BBCode[/color], or \\[color=yellow]escape it[/color]!",
	"Autopunc is on, which automatically puts pauses after punctuation.",
	"But you can also do it{p 20} manually!",
	"As for the event system...{p 10} Walter, would you help me demonstrate? {e walterify()}",
	"Thank you. Now, then: Watch as I turn Walter White... into Walter Wide{e wideify(2.0)}.",
	"As you can see, anything's possible with the event system! Thank you, Walter.{e dewalterify()}",
	]
```

## License

Listen. Bucko. I'm no lawyer, nor a cop.

I could put this thing up as MIT, or BSD, or what have you. But I'm not about to slam you with a C&D for not including the right copyright notice for my 500-line Godot script. Do what you want, I'm not your mom.

That said, if you do use this in your game, just credit me in some reasonable way.

I ***WILL*** cry.
