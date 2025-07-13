extends Node
var current_scene = null

var debug_labels: Array[Label]


func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

## Plays a sound from an array of sounds. Can be awaited.
func play_sound(sound_array: Array[String], instantiator = current_scene, volume := 0.0): 
	var sfx = load(sound_array[randi() % sound_array.size()])
	await play_single_sound(sfx, instantiator, volume)

## Plays a single sound with volume and pitch. Can be awaited.
func play_single_sound(sfx, instantiator = current_scene, volume := 0.0, pitch := 1.0):
	if sfx is String:
		sfx = load(sfx)
	var audio_player = AudioStreamPlayer3D.new()
	instantiator.add_child(audio_player)
	audio_player.stream = sfx
	audio_player.pitch_scale = pitch
	audio_player.volume_db = volume
	audio_player.play()
	await(audio_player.finished)
	audio_player.queue_free()

## Creates a new debug label in the top right of the screen
func new_debug_label(text: String = "Debug Label") -> Label:
	var debug_label: Label = Label.new()
	debug_label.text = text
	debug_labels.append(debug_label)
	debug_label.position = Vector2(20, 20 * debug_labels.size())
	add_child(debug_label)
	return debug_label
