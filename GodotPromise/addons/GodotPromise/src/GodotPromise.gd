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

	# <MEMBERS>
## If [code]true[/code], the result of this [Promise] will be binded to the next [Promise]
## in a [Promise] chain, and used as arguments. This is only relevant is the next [Promise]
## in the chain is tasked with a [Callable]. [Array]s are unzipped for this purpose. 
var chaining : bool:
	get = get_chaining,
	set = set_chaining


	# <MEMBER DEFINITION FUNCTIONS>
func get_chaining() -> bool:
	return chaining
func set_chaining(val) -> void:
	chaining = val


	# <OVERWRITED OBJECT FUNCTIONS>
## Constructor function of the [Promise] class.[br]
## The parameter [param async] is the value for the promise to resolve.[br]
## If [param executeOnStart] is [code]true[/code], then the promise will immediately call [method execute].
func _init(async = null, executeOnStart : bool = true) -> void:
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


	# <USER ACCESS FUNCTIONS>
## Starts the resolving process of the [Promise]. Does nothing if this [Promise] has already
## executed.
func execute() -> void:
	_logic.execute()
## Gets the current status of the [Promise]. Also see [enum PromiseStatus].
func get_status() -> PromiseStatus:
	return _logic.get_status()
## Gets the previous [Promise] in this [Promise] chain, if it exists.
func get_prev() -> Promise:
	return _logic.get_prev()
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


	# <PROMISE CREATION FUNCTIONS>
## Returns a [Promise] of all coroutines, sorting their outputs in an [Array], and finishes
## only when all coroutines have finished.
static func all(promises : Array = []) -> Promise:
	return Promise.new(AllCoroutine.new(promises), true)
## Returns a [Promise] of all coroutines, returning their accepted ([code]true[/code])
## or rejected ([code]false[/code]) status in an [Array], and finishes only when all
## coroutines have finished. Also see [enum PromiseStatus].
static func allSettled(promises : Array[Promise] = []) -> Promise:
	return Promise.new(AllSettledCoroutine.new(promises), true)


## Returns a [Promise] that finishes and returns the result of the first coroutine to finish from the
## given coroutines, regardless of if it was accepted or rejected.
## [br][br]
## Also sees [method reject] and [method resolve].
static func race(promises : Array = []) -> Promise:
	return Promise.new(RaceCoroutine.new(promises), true)
## Returns a [Promise] that finishes and returns the result of the first coroutine to be accepted
## from the given coroutines. It ignores all coroutines reject, unless all coroutines are rejected.
## If all coroutines are rejected, it will send an array of reject outputs.
## [br][br]
## Also sees [method reject] and [method resolve].
static func any(promises : Array[Promise] = []) -> Promise:
	return Promise.new(AnyCoroutine.new(promises), true)


## Returns a [Promise] that is rejected and gives [param async] as the reason.
## [br][br]
## Unlike [method reject_direct], if [param async] is a coroutine, it will wait
## for it to finish.
static func reject(async = null) -> Promise:
	var logic := StatusCoroutineLogic.new(async)
	logic.pass_status(false)
	return Promise.new(logic, true)
## Returns a [Promise] that is resolved and gives [param async] as the output.
## [br][br]
## Unlike [method reject_direct], if [param async] is a coroutine, it will wait
## for it to finish. [br]
## Functionally, this is equalvent [method Promise.new].
static func resolve(async = null) -> Promise:
	var logic := StatusCoroutineLogic.new(async)
	logic.pass_status(true)
	return Promise.new(logic, true)

## Returns a [Promise] that is rejected and gives [param async] as the reason.
## [br][br]
## If given a coroutine as parameter, it does not attempt to resolve or reject it.
static func reject_raw(async = null) -> Promise:
	var logic := AbstractLogic.new()
	logic.reject(async)
	return Promise.new(logic, true)
## Returns a [Promise] that is resolved and gives [param async] as the output.
## [br][br]
## If given a coroutine as parameter, it does not attempt to resolve or reject it.
static func resolve_raw(async = null) -> Promise:
	var logic := AbstractLogic.new()
	logic.resolve(async)
	return Promise.new(logic, true)


## Returns a [Promise] based on an async [Callable]. Uses the [method Callable.bind] method
## to bind two [Callable]s to resolve and reject the [Promise], respectfully. 
static func withCallback(async : Callable) -> Promise:
	var logic := DirectCoroutineLogic.new(null)
	logic._promise = async.bind(logic.resolve, logic.reject)
	return Promise.new(logic, true)
## Returns an object including a [Promise], based on an async [Callable], a function to resolve
## the [Promise], and a function to reject the [Promise].
static func withResolvers(async = null) -> Dictionary:
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
static func withCallbackResolvers(async : Callable) -> Dictionary:
	var logic := DirectCoroutineLogic.new(null)
	logic._promise = async.bind(logic.resolve, logic.reject)
	
	return {
		"Promise": Promise.new(logic, true),
		"Resolve": logic.resolve,
		"Reject": logic.reject
	}


	# <PROMISE CHAIN EXTENSIONS FUNCTIONS>
## Extends the [Promise] chain.[br]
## Sets the value of [member chaining] to the param [param toggle] and returns the
## same [Promise].
func chain(toggle : bool = true) -> Promise:
	chaining = toggle
	return self
## Extends the [Promise] chain.[br]
## Returns a new [Promise] that is executed immediately after this [Promise] is finished, regardless
## of if it is accepted or rejected.[br]
## [br][br]
## Also see [method execute].
func finally(async = null) -> Promise:
	var promise := Promise.new(StatusCoroutineLogic.new(async), false)
	_chain_extention(_copy_status, promise, [false])
	return promise
## Extends the [Promise] chain.[br]
## Returns a new [Promise] that is executed immediately after this [Promise] is rejected. If this
## [Promise] is accepted instead, then the newly created [Promise] is also immediately accepted.[br]
## If [member chaining] is [code]true[/code], the ouput of the perevious [Promise] in this [Promise]
## chain will be pushed to the next.
## [br][br]
## Also see [method execute].
func catch(async = null) -> Promise:
	var promise := Promise.new(ForceCoroutineLogic.new(async), false)
	_chain_extention(_passthrough_at_desired, promise, [async, PromiseStatus.Rejected, true])
	return promise
## Extends the [Promise] chain.[br]
## Returns a new [Promise] that is executed immediately after this [Promise] is accepted. If this
## [Promise] is rejected instead, then the newly created [Promise] is also immediately rejected.[br]
## If [member chaining] is [code]true[/code], the ouput of the perevious [Promise] in this [Promise]
## chain will be pushed to the next.
## [br][br]
## Also see [method execute].
func then(async = null) -> Promise:
	var promise := Promise.new(ForceCoroutineLogic.new(async), false)
	_chain_extention(_passthrough_at_desired, promise, [async, PromiseStatus.Accepted, true])
	return promise


	# <HELPER FUNCTIONS>
func _chain_extention(call : Callable, promise : Promise, args : Array = []) -> void:
	promise._logic._prev = self
	call = call.bind(promise).bindv(args)
	
	if _logic.is_finished():
		call.call(get_result())
		return
	finished.connect(call)
func _handle_chain(arg, propagate : bool, promise : Promise) -> void:
	if chaining:
		promise.chaining = true
		promise._logic._propagate = propagate
		if _logic._propagate && !_logic._args.is_empty():
			promise._logic.bind(_logic._args)
		else:
			if arg is Array:
				promise._logic.bind(arg)
			else:
				promise._logic.bind([arg])

func _inline(input, propagate : bool, promise : Promise) -> void:
	_handle_chain(input, propagate, promise)
	promise.execute()
func _copy_status(input, propagate : bool, promise : Promise) -> void:
	if promise._logic is StatusCoroutineLogic:
		promise._logic.pass_status(get_status() == PromiseStatus.Accepted)
	
	_inline(input, propagate, promise)
func _passthrough_at_desired(
	input,
	async,
	desired_status : PromiseStatus,
	propagate : bool,
	promise : Promise,
) -> void:
	if promise._logic is ForceCoroutineLogic:
		var overwrite = async if get_status() == desired_status else input
		promise._logic.pass_overwrite(overwrite)
	
	_copy_status(input, propagate, promise)


	# <BASE CLASSES>
## Base Class for Promise Logic
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
	var _propagate : bool = false
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
	## Binds arguments. These arguments will be used if this [Promise] is
	## tasked with a [Callable].
	func bind(args : Array) -> void:
		_args.append_array(args)
	
	## A method to connect the coroutine to a resolving function.
	func connect_coroutine(promise, process : Callable) -> void:
		if promise is Promise:
			if promise.is_finished():
				process.call(promise.get_result())
				return
			promise.finished.connect(process)
			return
		
		if promise is Callable:
			if !promise.is_valid():
				reject("Invaild Callable")
				return
		elif !(promise is Signal):
			process.call(promise)
			return
		
		var task := Task.new(promise, _args)
		task.finished.connect(process)
		task.execute()
		_tasks.append(task)
	
	## Overwrite this method to create custom execute logic
	func _execute() -> void: pass
	## Allows deferred emition of the [finished] signal.
	func _emit_finished(output) -> void: finished.emit(output)

## Base Class for Single Coroutine Promise Logic
class DirectCoroutineLogic extends AbstractLogic:
	func _init(promise) -> void:
		_promise = promise
	
	func _execute() -> void:
		connect_coroutine(_promise, _on_thread_finish)
	func _on_thread_finish(output) -> void:
		if _promise is Promise:
			if _promise.get_status() == PromiseStatus.Rejected:
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

## Base Class for Multi Coroutine Promise Logic
class MultiCoroutine extends AbstractLogic:
	func _init(promises : Array) -> void:
		_promise = promises
	
	func _execute() -> void:
		for idx : int in range(0, _promise.size()):
			connect_coroutine(_promise[idx], _on_thread_finish.bind(idx))
	## Overwrite this method to create custom thread logic
	func _on_thread_finish(output, _index : int) -> void: pass
## Class for Race Coroutine Promise Logic
class RaceCoroutine extends MultiCoroutine:
	func _on_thread_finish(output, _index : int) -> void:
		resolve(output)

## Base Class for Multi Coroutine Promise Logic that returns an array
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
		_outputs[index] = (_promise[index] as Promise).get_status() == PromiseStatus.Accepted
		_counter -= 1
		if _counter == 0:
			resolve(_outputs)
## Class for Any Coroutine Promise Logic
class AnyCoroutine extends ArrayCoroutine:
	func _init(promises : Array[Promise]) -> void:
		super(promises)
	
	func _on_thread_finish(output, index : int) -> void:
		super(output, index)
		if (_promise[index] as Promise).get_status() == PromiseStatus.Accepted:
			resolve(output)
			return
		
		if _counter == 0:
			resolve(_outputs)
