# Made by Xavier Alvarez. A part of the "GodotPromise" Godot addon.
@icon("res://addons/GodotPromise/assets/GodotPromise.svg")
@tool
class_name Promise extends RefCounted
## A class used to coordinate coroutines


## Emitted when [Promise] is Accepted or Rejected.
signal finished(output)
## Emitted when [Promise] is Accepted or Rejected. Returns the output of the [Promise]
## with the status. Also see [enum PromiseStatus].
signal finished_status(output, status : PromiseStatus)
## Emitted when [Promise] is Accepted.
signal accepted(output)
## Emitted when [Promise] is Rejected.
signal rejected(output)

## Current Status of the Promise
enum PromiseStatus {
	Initialized = 0, ## The promise hasn't yet been executed
	Pending = 1, ## The promise has been executed, but not finished
	Accepted = 2, ## The promise is finished and accepted
	Rejected = 3 ## The promise is finished, but rejected
}

var _logic : AbstractLogic


## Constructor function of the [Promise] class.[br]
## The parameter [param async] is the value for the promise to resolve.[br]
## If [param executeOnStart] is [code]true[/code], then the promise will immediately call [method execute].
func _init(async, executeOnStart : bool = true) -> void:
	if async is AbstractLogic:
		_logic = async
	else:
		_logic = DirectCoroutineLogic.new(async)
	if executeOnStart: execute()
	
	_logic.finished.connect(_finish_return)
func _finish_return(output) -> void:
	var status := get_status()
	
	finished.emit(output)
	finished_status.emit(output, status)
	
	if status == PromiseStatus.Accepted:
		accepted.emit(output)
		return
	rejected.emit(output)
func _to_string() -> String:
	return "Promise<" + str(get_promise_object()) + ">"


## Starts the resolving process of the [Promise]. Does nothing if this [Promise] has already
## executed.
func execute() -> void:
	_logic.execute()
## Gets the current status of the [Promise]. Also see [enum PromiseStatus].
func get_status() -> PromiseStatus:
	return _logic.get_status()
## Returns if the current [Promise] has finished.
func is_finished() -> bool:
	return _logic.is_finished()
## Gets the assigned [Object] or [Variant] is attempting to or has resolved or rejected.
func get_promise_object():
	return _logic.get_promise_object()
## Gets the current output of the [Promise]. Returns [code]null[/code] if [Promise] is not
## finished. Also see [method is_finished].
func get_result():
	return _logic.get_output()


## Returns a [Promise] of all coroutines, sorting their outputs in an [Array], and finishes
## only when all coroutines have finished.
static func all(promises : Array) -> Promise:
	return Promise.new(AllCoroutine.new(promises), true)
## Returns a [Promise] of all coroutines, returning their accepted or rejected status in an [Array],
## and finishes only when all coroutines have finished. Also see [enum PromiseStatus].
static func allSettled(promises : Array[Promise]) -> Promise:
	return Promise.new(AllSettledCoroutine.new(promises), true)


## Returns a [Promise] that finishes and returns the result of the first coroutine to finish from the
## given coroutines, regardless of if it was accepted or rejected.
## [br][br]
## Also sees [method reject] and [method resolve].
static func race(promises : Array) -> Promise:
	return Promise.new(RaceCoroutine.new(promises), true)
## Returns a [Promise] that finishes and returns the result of the first coroutine to be accepted
## from the given coroutines. It ignores all coroutines reject, unless all coroutines are rejected.
## If all coroutines are rejected, it will send an array of reject outputs.
## [br][br]
## Also sees [method reject] and [method resolve].
static func any(promises : Array[Promise]) -> Promise:
	return Promise.new(AnyCoroutine.new(promises), true)


## Returns a [Promise] that is rejected and gives [param async] as the reason.
static func reject(async) -> Promise:
	var logic := AbstractLogic.new()
	logic.reject(async)
	return Promise.new(logic, false)
## Returns a [Promise] that is resolved and gives [param async] as the output.
static func resolve(async) -> Promise:
	var logic := AbstractLogic.new()
	logic.resolve(async)
	return Promise.new(logic, false)


## Returns a [Promise] based on an async [Callable]. Uses the [method Callable.bind] method
## to bind two [Callable]s to resolve and reject the [Promise], respectfully. 
static func withCallback(async : Callable) -> Promise:
	var logic := DirectCoroutineLogic.new(null)
	logic._promise = async.bind(logic.resolve, logic.reject)
	return Promise.new(logic, true)
## Returns an object including a [Promise], based on an async [Callable], a function to resolve
## the [Promise], and a function to reject the [Promise].
static func withResolvers(async) -> Dictionary[String, Variant]:
	var logic := DirectCoroutineLogic.new(async)
	return {
		"Promise": Promise.new(logic, true),
		"Resolve": logic.resolve,
		"Reject": logic.reject
	}
## Returns an object including a [Promise], based on an async [Callable], a function to resolve
## the [Promise], and a function to reject the [Promise]. Also uses the [method Callable.bind]
## method to bind two [Callable]s to resolve and reject the [Promise], respectfully.
## [br][br]
## A combined form of [method withResolvers] and [method withCallback].
static func withCallbackResolvers(async : Callable) -> Dictionary[String, Variant]:
	var logic := DirectCoroutineLogic.new(null)
	logic._promise = async.bind(logic.resolve, logic.reject)
	
	return {
		"Promise": Promise.new(logic, true),
		"Resolve": logic.resolve,
		"Reject": logic.reject
	}


## Returns a new [Promise] that is executed immediately after this [Promise] is finished, regardless
## of if it is accepted or rejected.
## [br][br]
## Also see [method execute].
func finally(async) -> Promise:
	var promise := Promise.new(async, false)
	if _logic.is_finished():
		promise._logic.execute()
	else:
		finished.connect(promise._logic.execute, CONNECT_ONE_SHOT)
	return promise
## Returns a new [Promise] that is executed immediately after this [Promise] is rejected. If this
## [Promise] is accepted instead, then the newly created [Promise] is also immediately accepted.
## [br][br]
## Also see [method execute].
func catch(async) -> Promise:
	var promise := Promise.new(async, false)
	if _logic.is_finished():
		_callback_check(_logic.get_output(), async, PromiseStatus.Rejected, promise._logic)
	else:
		finished.connect(_callback_check.bind(async, PromiseStatus.Rejected, promise._logic), CONNECT_ONE_SHOT)
	return promise
## Returns a new [Promise] that is executed immediately after this [Promise] is accepted. If this
## [Promise] is rejected instead, then the newly created [Promise] is also immediately rejected.
## [br][br]
## Also see [method execute].
func then(async) -> Promise:
	var promise := Promise.new(async, false)
	if _logic.is_finished():
		_callback_check(_logic.get_output(), async, PromiseStatus.Accepted, promise._logic)
	else:
		finished.connect(_callback_check.bind(async, PromiseStatus.Accepted, promise._logic), CONNECT_ONE_SHOT)
	return promise
func _callback_check(
	current_output = null,
	async_output = null,
	desired_status : PromiseStatus = PromiseStatus.Accepted,
	logic : AbstractLogic = null
) -> void:
	var output = async_output if _logic.get_status() == desired_status else current_output
	match _logic.get_status():
		PromiseStatus.Accepted:
			logic.resolve(output)
		PromiseStatus.Rejected:
			logic.reject(output)


class AbstractLogic extends RefCounted:
	signal finished(output)
	
	class Task extends RefCounted:
		signal finished(output)
		func _call_callback(async : Callable) -> void:
			finished.emit(await async.call())
		func _signal_callback(async : Signal) -> void:
			finished.emit(await async)
		func _init(async) -> void:
			if async is Callable:
				_call_callback(async) 
				return
			_signal_callback(async)
	
	var tasks : Array[Task]
	var _status : PromiseStatus = PromiseStatus.Initialized
	var _promise = null
	var _output = null
	
	func reject(output) -> void:
		if _status > PromiseStatus.Pending: return
		
		_status = PromiseStatus.Rejected
		_output = output
		_emit_finished.call_deferred(output)
	func resolve(output) -> void:
		if _status > PromiseStatus.Pending: return
		
		_status = PromiseStatus.Accepted
		_output = output
		_emit_finished.call_deferred(output)
	
	func is_finished() -> bool:
		return _status >= PromiseStatus.Accepted
	func get_status() -> PromiseStatus:
		return _status
	func get_promise_object():
		return _promise
	func get_output():
		return _output
	
	func execute() -> void:
		if _status != PromiseStatus.Initialized: return
		_status = PromiseStatus.Pending
		_execute()
	
	func _execute() -> void: pass
	func _emit_finished(output) -> void: finished.emit(output)
	func _connect_signal(promise, resolve : Callable) -> void:
		if promise is Promise:
			promise.finished.connect(resolve)
		else:
			if promise is Callable:
				if !promise.is_valid():
					reject("Invaild Callable")
					return
			elif !(promise is Signal):
				resolve(promise)
				return
			
			var task := Task.new(promise)
			tasks.append(task)
			task.finished.connect(resolve)

class DirectCoroutineLogic extends AbstractLogic:
	func _init(promise) -> void:
		_promise = promise
	
	func _execute() -> void: _connect_signal(_promise, resolve)

class MultiCoroutine extends AbstractLogic:
	func _init(promises : Array) -> void:
		_promise = promises
	
	func _execute() -> void:
		for idx : int in range(0, _promise.size()):
			_connect_signal(_promise[idx], _on_thread_finish.bind(idx))
	func _on_thread_finish(output, _index : int) -> void: pass
class RaceCoroutine extends MultiCoroutine:
	func _on_thread_finish(output, _index : int) -> void:
		resolve(output)

class ArrayCoroutine extends MultiCoroutine:
	var _outputs : Array
	var _counter : int
	
	func _init(promises : Array) -> void:
		_outputs.resize(promises.size())
		_counter = promises.size()
		super(promises)
	
	func _on_thread_finish(output, index : int) -> void:
		_outputs[index] = output
		_counter -= 1
class AllCoroutine extends ArrayCoroutine:
	func _on_thread_finish(output, index : int) -> void:
		super(output, index)
		if _counter == 0:
			resolve(_outputs)

class AllSettledCoroutine extends ArrayCoroutine:
	func _init(promises : Array[Promise]) -> void:
		super(promises)
	
	func _on_thread_finish(output, index : int) -> void:
		_outputs[index] = (_promise[index] as Promise).get_status()
		_counter -= 1
		if _counter == 0:
			resolve(_outputs)
class AnyCoroutine extends ArrayCoroutine:
	func _init(promises : Array[Promise]) -> void:
		_outputs.resize(promises.size())
		_counter = promises.size()
		super(promises)
	
	func _on_thread_finish(output, index : int) -> void:
		super(output, index)
		if (_promise[index] as Promise).get_status() == PromiseStatus.Accepted:
			resolve(output)
			return
		
		if _counter == 0:
			resolve(_outputs)
