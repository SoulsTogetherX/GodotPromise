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

	# <OVERWRITED OBJECT FUNCTIONS>
## Constructor function of the [Promise] class.[br]
## The parameter [param async] is the value for the promise to resolve.[br]
## If [param executeOnStart] is [code]true[/code], then the promise will immediately call [method execute].
func _init(
	async = null,
	executeOnStart : bool = true
) -> void:
	if async is AbstractLogic:
		_logic = async
	else:
		_logic = DirectCoroutineLogic.new(async)
	
	_logic.finished.connect(_finish_return)
	if executeOnStart: execute()
func _finish_return(output) -> void:
	var status := peek()
	
	finished.emit(output)
	finished_status.emit(output, status)
	
	if status == PromiseStatus.Accepted:
		accepted.emit(output)
		return
	rejected.emit(output)
func _to_string() -> String:
	return "Promise<" + str(get_promise_object()) + ">"


	# <USER ACCESS FUNCTIONS>
## Starts the resolving process of the [Promise]. Does nothing if this [Promise] has already
## executed.
func execute() -> void:
	_logic.execute()
## Resets the the [Promise] so it can resolve/reject the given task again. If called while
## the task is pending, the task is cancled.
## [br][br]
## Also see [method execute].
func reset() -> void:
	_logic.reset()
## Similar to [method reset], but resets all the [Promise] and all previous [Promise]s
## executed in the [Promise[ chain.
## [br][br]
## Also see [method execute].
func reset_chain() -> void:
	_logic.reset_chain()

## Returns if the current [Promise] has finished.
func is_finished() -> bool:
	return _logic.is_finished()
## Gets the current status of the [Promise]. Also see [enum PromiseStatus].
func peek() -> PromiseStatus:
	return _logic.peek()
## Gets the previous [Promise] in this [Promise] chain, if it exists.
func get_prev() -> Promise:
	return _logic.get_prev()
## Gets the assigned [Object] or [Variant] is attempting to or has resolved or rejected.
func get_promise_object():
	return _logic.get_promise_object()

## Gets the current output of the [Promise]. Returns [code]null[/code] if [Promise] is not
## finished. Also see [method is_finished].
func get_result():
	return _logic.get_output()


	# <PROMISE CREATION FUNCTIONS>
## Returns a [Promise] of all coroutines, sorting their outputs in an [Array], and finishes
## only when all coroutines have finished.
static func all(
	promises : Array = [],
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(AllCoroutine.new(promises), executeOnStart)
## Returns a [Promise] of all coroutines, returning their accepted ([code]true[/code])
## or rejected ([code]false[/code]) status in an [Array], and finishes only when all
## coroutines have finished. Also see [enum PromiseStatus].
static func allSettled(
	promises : Array[Promise] = [],
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(AllSettledCoroutine.new(promises), executeOnStart)


## Returns a [Promise] that finishes and returns the result of the first coroutine to finish from the
## given coroutines, regardless of if it was accepted or rejected.
## [br][br]
## Also sees [method reject] and [method resolve].
static func race(
	promises : Array = [],
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(RaceCoroutine.new(promises), executeOnStart)
## Returns a [Promise] that finishes and returns the result of the first coroutine to be accepted
## from the given coroutines. It ignores all coroutines reject, unless all coroutines are rejected.
## If all coroutines are rejected, it will send an array of reject outputs.
## [br][br]
## Also sees [method reject] and [method resolve].
static func any(
	promises : Array[Promise] = [],
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(AnyCoroutine.new(promises), executeOnStart)


## Returns a [Promise] that is rejected and gives [param async] as the reason.
## [br][br]
## Unlike [method reject_direct], if [param async] is a coroutine, it will wait
## for it to finish.
static func reject(
	async = null,
	executeOnStart : bool = true
) -> Promise:
	var logic := StatusCoroutineLogic.new(async)
	logic.pass_status(false)
	return Promise.new(logic, executeOnStart)
## Returns a [Promise] that is resolved and gives [param async] as the output.
## [br][br]
## Unlike [method reject_direct], if [param async] is a coroutine, it will wait
## for it to finish. [br]
## Functionally, this is equalvent [method Promise.new].
static func resolve(
	async = null,
	executeOnStart : bool = true
) -> Promise:
	var logic := StatusCoroutineLogic.new(async)
	logic.pass_status(true)
	return Promise.new(logic, executeOnStart)

## Returns a [Promise] that is rejected and gives [param async] as the reason.
## [br][br]
## If given a coroutine as parameter, it does not attempt to resolve or reject it.
static func reject_raw(
	async = null,
	executeOnStart : bool = true
) -> Promise:
	var logic := AbstractLogic.new()
	logic.reject(async)
	return Promise.new(logic, executeOnStart)
## Returns a [Promise] that is resolved and gives [param async] as the output.
## [br][br]
## If given a coroutine as parameter, it does not attempt to resolve or reject it.
static func resolve_raw(
	async = null,
	executeOnStart : bool = true
) -> Promise:
	var logic := AbstractLogic.new()
	logic.resolve(async)
	return Promise.new(logic, executeOnStart)


## Returns a [Promise] based on an async [Callable]. Uses the [method Callable.bind] method
## to bind two [Callable]s to resolve and reject the [Promise], respectfully. 
static func withCallback(
	async : Callable,
	executeOnStart : bool = true
) -> Promise:
	var logic := DirectCoroutineLogic.new(null)
	logic._promise = async.bind(logic.resolve, logic.reject)
	return Promise.new(logic, executeOnStart)
## Returns an object including a [Promise], based on an async [Callable], a function to resolve
## the [Promise], and a function to reject the [Promise].
static func withResolvers(
	async = null,
	executeOnStart : bool = true
) -> Dictionary:
	var logic := DirectCoroutineLogic.new(async)
	return {
		"Promise": Promise.new(logic, executeOnStart),
		"Resolve": logic.resolve,
		"Reject": logic.reject
	}
## Returns an object including a [Promise], based on an async [Callable], a function to resolve
## the [Promise], and a function to reject the [Promise]. Also uses the [method Callable.bind]
## method to bind two [Callable]s to resolve and reject the [Promise], respectfully.
## [br][br]
## A combined form of [method withResolvers] and [method withCallback].
static func withCallbackResolvers(
	async : Callable,
	executeOnStart : bool = true
) -> Dictionary:
	var logic := DirectCoroutineLogic.new(null)
	logic._promise = async.bind(logic.resolve, logic.reject)
	
	return {
		"Promise": Promise.new(logic, executeOnStart),
		"Resolve": logic.resolve,
		"Reject": logic.reject
	}


	# <PROMISE CHAIN EXTENSIONS FUNCTIONS>
## Extends the [Promise] chain by returning a new [Promise] that is executed immediately
## after this [Promise] is finished, regardless of if it is accepted or rejected.
## [br]
## If [param pipe_prev] is [code]true[/code], then the output of the previous [Promise] will be
## used as a binded argument if the [param async] is a [Callable].
## [br][br]
## Also see [method execute] and [method Callable.bind].
func finally(
	async = null,
	pipe_prev : bool = false
) -> Promise:
	var promise := Promise.new(StatusCoroutineLogic.new(async), false)
	_chain_extention(_copy_status, promise._logic, [pipe_prev])
	return promise
## Extends the [Promise] chain by returning a new [Promise] that is executed immediately after
## this [Promise] is rejected. If this [Promise] is accepted instead, then the newly created
## [Promise] is also immediately accepted.
## [br]
## If [param pipe_prev] is [code]true[/code], then the output of the previous [Promise] will be
## used as a binded argument if the [param async] is a [Callable].
## [br][br]
## Also see [method execute] and [method Callable.bind].
func catch(
	async = null,
	pipe_prev : bool = false
) -> Promise:
	var promise := Promise.new(ForceCoroutineLogic.new(async), false)
	_chain_extention(_passthrough_at_desired, promise._logic, [async, PromiseStatus.Rejected, pipe_prev])
	return promise
## Extends the [Promise] chain by returning a new [Promise] that is executed immediately after
## this [Promise] is accepted. If this [Promise] is rejected instead, then the newly created
## [Promise] is also immediately rejected.
## [br]
## If [param pipe_prev] is [code]true[/code], then the output of the previous [Promise] will be
## used as a binded argument if the [param async] is a [Callable].
## [br][br]
## Also see [method execute] and [method Callable.bind].
func then(
	async = null,
	pipe_prev : bool = false
) -> Promise:
	var promise := Promise.new(ForceCoroutineLogic.new(async), false)
	_chain_extention(_passthrough_at_desired, promise._logic, [async, PromiseStatus.Accepted, pipe_prev])
	return promise


	# <HELPER FUNCTIONS>
func _chain_extention(call : Callable, logic : AbstractLogic, args : Array = []) -> void:
	logic._prev = self
	call = call.bind(logic).bindv(args)
	
	if _logic.is_finished():
		call.call(get_result())
		return
	finished.connect(call, CONNECT_ONE_SHOT)

func _inline(
	input,
	bind_input : bool,
	logic : AbstractLogic,
) -> void:
	if bind_input: logic.bind(input)
	logic.execute()
func _copy_status(
	input,
	bind_input : bool,
	logic : AbstractLogic,
) -> void:
	if logic is StatusCoroutineLogic:
		logic.pass_status(peek() == PromiseStatus.Accepted)
	
	_inline(input, bind_input, logic)
func _passthrough_at_desired(
	input,
	async,
	desired_status : PromiseStatus,
	bind_input : bool,
	logic : AbstractLogic,
) -> void:
	if logic is ForceCoroutineLogic:
		var overwrite = async if peek() == desired_status else input
		logic.pass_overwrite(overwrite)
	
	_copy_status(input, bind_input, logic)


	# <BASE CLASSES>
## BASE Class for ALL Promise Logic
class AbstractLogic extends RefCounted:
	signal finished(output)
	
	class Task extends RefCounted:
		signal finished(output)
		var _promise : Callable
		
		func _init(async, args : Array) -> void:
			if async is Callable:
				_promise = _call_callback.bind(async.bindv(args))
				return
			_promise = _signal_callback.bind(async)
		func _call_callback(async : Callable) -> void:
			finished.emit(await async.call())
		func _signal_callback(async : Signal) -> void:
			finished.emit(await async)
		
		func execute() -> void:
			_promise.call()
	
	var _args : Array
	var _tasks : Array[Task]
	var _prev : Promise # Needed so Godot doesn't clear a chain of Promises Prematurely
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
	func peek() -> PromiseStatus:
		return _status
	func get_prev() -> Promise:
		return _prev
	func get_promise_object():
		return _promise
	func get_output():
		return _output
	
	## Don't overwrite this. Call this to execute the [Promise].
	func execute() -> void:
		if _status != PromiseStatus.Initialized: return
		_status = PromiseStatus.Pending
		_execute()
	func reset() -> void:
		_tasks = []
		_output = null
		_status = PromiseStatus.Initialized
	func reset_chain() -> void:
		if _prev: _prev.reset_chain()
		reset()
	
	## Binds an argument. These arguments will be used if this [Promise] is
	## tasked with a [Callable].
	func bind(arg) -> void:
		_args.append(arg)
	## Binds arguments. These arguments will be used if this [Promise] is
	## tasked with a [Callable].
	func bindv(args : Array) -> void:
		_args.append_array(args)
	## Unbinds all arguments.
	func unbind() -> void:
		_args = []
	
	## A method to connect the coroutine to a resolving function.
	func connect_coroutine(promise, process : Callable) -> void:
		if promise is Promise:
			if promise.is_finished():
				process.call(promise.get_result())
				return
			promise.finished.connect(process, CONNECT_ONE_SHOT)
			return
		
		if promise is Callable:
			if !promise.is_valid():
				reject("Invaild Callable")
				return
		elif !(promise is Signal):
			process.call(promise)
			return
		
		var task := Task.new(promise, _args)
		task.finished.connect(process, CONNECT_ONE_SHOT)
		task.execute()
		_tasks.append(task)
	
	## Overwrite this method to create custom execute logic
	func _execute() -> void: pass
	## Allows deferred emition of the [finished] signal.
	func _emit_finished(output) -> void: finished.emit(output)

## BASE Class for Single Coroutine Promise Logic
class DirectCoroutineLogic extends AbstractLogic:
	func _init(promise) -> void:
		_promise = promise
	
	func _execute() -> void:
		connect_coroutine(_promise, _on_thread_finish)
	func _on_thread_finish(output) -> void:
		if _promise is Promise:
			if _promise.peek() == PromiseStatus.Rejected:
				reject(output)
				return
		resolve(output)

## Class for Status Coroutine Promise Logic
class StatusCoroutineLogic extends AbstractLogic:
	var _on_thread_finish : Callable = resolve
	
	func _init(promise) -> void:
		_promise = promise
	func _execute() -> void:
		connect_coroutine(_promise, _on_thread_finish)
	
	func pass_status(accept : bool = true) -> void:
		_on_thread_finish = resolve if accept else reject
## Class for Force Coroutine Promise Logic
class ForceCoroutineLogic extends StatusCoroutineLogic:
	var _overwrite = null
	func pass_overwrite(overwrite) -> void:
		_overwrite = overwrite
	
	func _execute() -> void:
		connect_coroutine(_overwrite, _on_thread_finish)

## BASE Class for OnSignal Frame Coroutine Promise Logic
class OnSignalCoroutine extends AbstractLogic:
	var _signal : Signal
	func _init(sig : Signal) -> void:
		_signal = sig
	
	func reject(output) -> void:
		_disconnect_to_signal()
		super(output)
	func resolve(output) -> void:
		_disconnect_to_signal()
		super(output)
	
	func _connect_to_signal() -> void:
		if _signal && !_signal.is_connected(_on_signal):
			_signal.connect(_on_signal)
	func _disconnect_to_signal() -> void:
		if _signal && _signal.is_connected(_on_signal):
			_signal.disconnect(_on_signal)
	func _on_signal() -> void:
		resolve(null)
	
	func _execute() -> void:
		_connect_to_signal()

## BASE Class for Multi Coroutine Promise Logic
class MultiCoroutine extends AbstractLogic:
	func _init(promises : Array) -> void:
		_promise = promises
	
	func _execute() -> void:
		if _promise.is_empty():
			resolve([])
			return
		for idx : int in range(0, _promise.size()):
			connect_coroutine(_promise[idx], _on_thread_finish.bind(idx))
	## Overwrite this method to create custom thread logic
	func _on_thread_finish(output, _index : int) -> void: pass
## Class for Race Coroutine Promise Logic
class RaceCoroutine extends MultiCoroutine:
	func _on_thread_finish(output, _index : int) -> void:
		resolve(output)

## BASE Class for Multi Coroutine Promise Logic that returns an array
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
## Class for All Coroutine Promise Logic
class AllCoroutine extends ArrayCoroutine:
	func _on_thread_finish(output, index : int) -> void:
		super(output, index)
		if _counter == 0:
			resolve(_outputs)
## Class for AllSettled Coroutine Promise Logic
class AllSettledCoroutine extends ArrayCoroutine:
	func _init(promises : Array[Promise]) -> void:
		super(promises)
	
	func _on_thread_finish(output, index : int) -> void:
		_outputs[index] = (_promise[index] as Promise).peek() == PromiseStatus.Accepted
		_counter -= 1
		if _counter == 0:
			resolve(_outputs)
## Class for Any Coroutine Promise Logic
class AnyCoroutine extends ArrayCoroutine:
	func _init(promises : Array[Promise]) -> void:
		super(promises)
	
	func _on_thread_finish(output, index : int) -> void:
		super(output, index)
		if (_promise[index] as Promise).peek() == PromiseStatus.Accepted:
			resolve(output)
			return
		
		if _counter == 0:
			resolve(_outputs)
