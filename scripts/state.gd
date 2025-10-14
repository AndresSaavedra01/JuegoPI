extends Node
class_name State

@export var stateName : String
@export var active : bool = false
@export var oneShot : bool = false
var function : Callable
var exitFunction : Callable

func _init(stateName : String, function : Callable, exitFunction : Callable = func(): pass) -> void:
	self.stateName = stateName
	self.function = function
	self.exitFunction = exitFunction

func isActive() -> bool:
	return active
	
func setActive(active : bool) -> void:
	self.active = active
	
func isOneShot() -> bool:
	return oneShot
	
func setOneShot(oneShot : bool) -> void:
	self.oneShot = oneShot
	
func setStateName(stateName : String) -> void:
	self.stateName = stateName

func getStateName() -> String:
	return stateName

func callFunc() -> void:
	function.call()
	if oneShot:
		active = false

func set_enter_method(function : Callable) -> void:
	self.function = function
	
func callExit() -> void:
	exitFunction.call()

func set_exit_method(exitFunction : Callable) -> void:
	self.exitFunction = exitFunction
