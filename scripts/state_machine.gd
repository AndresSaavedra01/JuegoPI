extends Node
class_name StateMachine

var graph : Dictionary[State,Array]

func _process(delta: float) -> void:
	if graph.is_empty():
		return
	for state : State in graph.keys():
		if state.isActive():
			state.callFunc()

func addState(state : State) -> void:
	graph[state] = []
	
func addRelation(stateFrom : State, stateTo : State) -> void:
	graph[stateFrom].append(stateTo)

func travel(stateName : String) -> bool:
	if graph.is_empty():
		return false
	var currentState : State = null
	for state : State in graph.keys():
		if state.isActive():
			currentState = state
	if currentState == null:
		return false
	var index = graph[currentState].find_custom(func(state : State): state.getStateName() == stateName)
	if not index == -1:
		currentState.setActive(false)
		currentState.callExit()
		var nextState : State = graph[currentState][index]
		nextState.setActive(true)
		return true
	return false

func setActiveState(stateName : String) -> bool:
	if graph.is_empty():
		return false
	var index = graph.keys().find_custom(func(state : State): state.getStateName() == stateName)
	if not index == -1:
		return false
	var currentState : State = graph.keys().get(index)
	currentState.setActive(true)
	return true
