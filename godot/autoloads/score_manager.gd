extends Node

var scoreNode: Label
var multiplierNode: Label
var MaxScoreNode: Label
var MaxMultiplierNode: Label


var score_current: int = 0
var multiplier_current: int = 1

var score_max: int = 0
var multiplier_max: int = 1


# resets scrore and game ?
func reset():
	scoreNode = get_tree().current_scene.find_node('Score')
	multiplierNode = get_tree().current_scene.find_node('Multiplier')
	MaxScoreNode = get_tree().current_scene.find_node('MaxScore')
	MaxMultiplierNode = get_tree().current_scene.find_node('MaxMultiplier')
	score_current = 0
	multiplier_current = 0
	resetMultiplier();
	resetComboScore()

func increaseMultiplier():
	setMultiplier(multiplier_current + 1)

func resetMultiplier():
	setMultiplier(1)

func resetComboScore():
	setComboScore(0)
		
func setMultiplier(multi: int):
	multiplier_current = multi
	multiplierNode.text = str(multiplier_current) + "x "
	if multiplier_current > multiplier_max:
		multiplier_max = multiplier_current
		MaxMultiplierNode.text = str(multiplier_max) + "x "
	
func addComboScore(gemCount: int):
	# if gemCount > 3 - then we already added the score for 3 gems, it only needs to add that one more gem
	if gemCount == 3:
		score_current += Vars.BASE_SCORE * multiplier_current
	else:
		score_current += (Vars.BASE_SCORE / 3.0) * (gemCount - 3) * multiplier_current
	
	if score_current > score_max:
		score_max = score_current
		MaxScoreNode.text = str(score_max)
		
	setComboScore(score_current)

func setComboScore(score: int):
	scoreNode.text = str(score_current)
