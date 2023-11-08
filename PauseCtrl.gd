extends Node

export(bool) var can_toggle_pause: bool = true
signal Restart

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		if !get_tree().paused:
			pause()
		else:
			resume()

func pause():
	if can_toggle_pause:
		get_tree().set_deferred("paused", true)
		$PauseMenu.visible = true
		$PauseMenu/VBoxContainer/ResumeBtn.grab_focus()

func resume():
	if can_toggle_pause:
		get_tree().set_deferred("paused", false)
		$PauseMenu.visible = false

func gameover():
	pause()
	$PauseMenu/VBoxContainer/GameOver.visible = true
	$PauseMenu/VBoxContainer/RestartBtn.visible = true
	$PauseMenu/VBoxContainer/ResumeBtn.visible = false
	$PauseMenu/VBoxContainer/RestartBtn.grab_focus()
	

func _on_QuitBtn_button_down():
	get_tree().quit()

func _on_ResumeBtn_button_down():
	resume()

func _on_RestartBtn_button_down():	
	$PauseMenu/VBoxContainer/GameOver.visible = false
	$PauseMenu/VBoxContainer/RestartBtn.visible = false
	$PauseMenu/VBoxContainer/ResumeBtn.visible = true
	emit_signal("Restart")
	resume()
