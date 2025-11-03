extends Node

var level_dic = {
	"Level1" : {
		"unlocked" : true,
		"unlocks" : "Level2",
		"beaten" : false
	},
	"Level2" : {
		"unlocked" : true,
		"unlocks" : "Level3",
		"beaten" : false
	}
}

func generate_level(level):
	if level not in level_dic:
		level_dic[level] = {
			"unlocked" : false,
			"unlocks" : generate_level_number(level),
			"beaten" : false
		}
		
func generate_level_number(level):
	var level_number = ""
	for character in level:
		if character.is_valid_int():
			level_number += character
	level_number = int(level_number) +1
	return "Level" + str(level_number)

func update_level(level, beaten):
	level_dic[level]["beaten"] = beaten
	
