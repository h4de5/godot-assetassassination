extends Node
#
#var sounds = []
#
#func _ready():
#	sounds = []

func play(sound, pitch = 1.0, _pitch_range = 0.05, position = null, parent = self):
	var audio_stream

	if position != null:
		audio_stream = AudioStreamPlayer2D.new()
		audio_stream.position = position
#		parent = self
	elif parent != self:
		audio_stream = AudioStreamPlayer2D.new()
	else:
		audio_stream = AudioStreamPlayer.new()
#		parent = self

	# add sound to game scene
	parent.add_child(audio_stream)
	# add finished handler
#	audio_stream.connect("finished", self, "on_sound_finished", [audio_stream])

	if typeof(sound) == TYPE_STRING:
	# if sound is string:
		audio_stream.stream = load(sound)
	else:
		audio_stream.stream = sound
	# play the sound
	audio_stream.play()
	
#	audio_stream.pitch_scale = lerp(pitch - pitch_range, pitch + pitch_range, randf())
	audio_stream.pitch_scale = pitch
#	audio_stream.volume_db = linear2db(volume)
#    audio_stream.bus = AudioBus.SFX

	# add to list of sounds
#	sounds.append(audio_stream)
	
	yield(audio_stream, "finished")

	audio_stream.queue_free()


#
#func on_sound_finished(sound):
#	# print("sound finished", sound)
#	# find sound ?
#	sounds.find(sound)
#	# if has sound, remove it
#	if sounds.has(sound):
#		sounds.erase(sound)
#
#	# remove from game scene
#	sound.queue_free();
