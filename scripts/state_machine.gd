extends Node
class_name StateMachine

var graph : Dictionary[State,Array]

func _physics_process(delta: float) -> void:
	if graph.is_empty():
		return
	for state : State in graph.keys():
		if state.isActive():
			state.callFunc()

func addState(state : State) -> void:
	graph[state] = []

func addRelation(stateFromName : String, stateToName : String) -> bool:
	var stateFrom : State = null
	for state : State in graph.keys():
		if state.getStateName() == stateFromName:
			stateFrom = state
	if stateFrom == null:
		return false
	var stateTo : State = null
	for state : State in graph.keys():
		if state.getStateName() == stateToName:
			stateTo = state
	if stateTo == null:
		return false
	graph[stateFrom].append(stateTo)
	return true

func addRelations(stateFromName : String, stateToArr : Array) -> bool:
	var stateFrom : State = null
	for state : State in graph.keys():
		if state.getStateName() == stateFromName:
			stateFrom = state
	if stateFrom == null:
		return false
	for stateToName in stateToArr:
		var stateTo : State = null
		for state : State in graph.keys():
			if state.getStateName() == stateToName:
				stateTo = state
				graph[stateFrom].append(stateTo)
	return true

func travel(stateName : String) -> bool:
	var comp = func(state : State) -> bool: return state.getStateName() == stateName
	if graph.is_empty():
		return false
	var currentState : State = null
	for state : State in graph.keys():
		if state.isActive():
			currentState = state
	if currentState == null:
		return false
	var index = graph[currentState].find_custom(comp)
	if not index == -1:
		currentState.setActive(false)
		currentState.callExit()
		var nextState : State = graph[currentState][index]
		nextState.setActive(true)
		return true
		
	return false

func setActiveState(stateName : String) -> bool:
	var comp = func(state : State) -> bool: return state.getStateName() == stateName
	if graph.is_empty():
		return false
	var index = graph.keys().find_custom(comp)
	if index == -1:
		return false
	var currentState : State = graph.keys().get(index)
	currentState.setActive(true)
	return true

func setInactiveState(stateName : String) -> bool:
	var comp = func(state : State) -> bool: return state.getStateName() == stateName
	if graph.is_empty():
		return false
	var index = graph.keys().find_custom(comp)
	if index == -1:
		return false
	graph.keys().get(index).setActive(false)
	return true
	
