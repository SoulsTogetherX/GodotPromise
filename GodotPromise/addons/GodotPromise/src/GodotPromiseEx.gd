# Made by Xavier Alvarez. A part of the "GodotPromise" Godot addon.
@icon("res://addons/GodotPromise/assets/GodotPromiseEx.svg")
@tool
class_name PromiseEx extends Promise
## An extension to the [Promise] class to showcase how easy it is to create custom [Promise] behavior.

	# <PROMISE CREATION FUNCTIONS>
## Requests two coroutines that race. If [param promise] finishes first, this [Promise] is accepted.
## If [param interfere] finishes first, this [Promise] is rejected.[br]
## If the coroutines end at the same time, [param promise] has the priority.
static func interfere(
	promise = null,
	interfere = null,
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(InterfereCoroutine.new(promise, interfere), executeOnStart)
## Creates a [Promise] that attempts to resolve [param promise] and [param release] coroutines
## at the same time. However, this [Promise] will not resolve until [param release] has resolved
## first.
static func hold(
	promise = null,
	release = null,
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(HoldCoroutine.new(promise, release), executeOnStart)


## Creates a [Promise] that attempts to load a resource using [ResourceLoader].[br]
## This [Promise] will reject an [constant Error.ERR_CANT_ACQUIRE_RESOURCE] if an
## error occurs during loading.
## [br][br]
## [b]NOTE[/b]: This [Promise] will only check if it's finished when [param event]
## has emited. For that reason, it is recomended you use [signal SceneTree.process_frame]
## as this argument.
static func resource(
	event : Signal,
	resource_path : String,
	executeOnStart : bool = true,
	type_hint : String = "",
	use_sub_threads : bool = false,
	cache_mode : ResourceLoader.CacheMode = 1,
) -> Promise:
	return Promise.new(ResourceCoroutine.new(
		event,
		resource_path,
		type_hint,
		use_sub_threads,
		cache_mode,
		),
		executeOnStart
	)


## Waits until all coroutines, then returns their result in an [Array] sorted by order they finished
## in. First finished starts the [Array] and last finished ends the [Array].
## [br][br]
## Also see [method Promise.all].
static func sort(
	promises : Array,
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(SortCoroutine.new(promises), executeOnStart)
## Waits until all coroutines, then returns their result in an [Array] reverse sorted by order they
## finished in. First finished ends the [Array] and last finished starts the [Array].
## [br][br]
## Also see [method Promise.all].
static func rSort(
	promises : Array,
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(RSortCoroutine.new(promises), executeOnStart)


## Waits until all coroutines, then returns the results of the first [param num]
## coroutines to finish in an [Array], sorted by the order they finished in.
## [br][br]
## Also see [method sort].
static func firstN(
	promises : Array,
	num : int,
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(FirstNCoroutine.new(promises, num), executeOnStart)
## Waits until all coroutines, then returns the results of the first [param num]
## coroutines to finish in an [Array], reverse sorted by the order they finished in.
## [br][br]
## Also see [method rSort].
static func lastN(
	promises : Array,
	num : int,
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(LastNCoroutine.new(promises, num), executeOnStart)


## Returns a [Promise] that finishes and returns the result of a pipline of coroutines. If the 
## coroutine is a Callable, or a [Promise] tasked with a [Callable], the previous output
## in the chain will be binded to it as an argument.[br]
## If a [Promise] is rejected within the chain, this [Promise] will immediately reject that
## error and cancel all future methods in the pipeline.
## [br][br]
## Also sees [method Callable.bind].
static func pipe(
	promises : Array,
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(PipeCoroutine.new(promises), executeOnStart)


## Returns a [Promise] that finishes and returns the result of the first coroutine to be rejected
## from the given coroutines. It ignores all coroutines accept, unless all coroutines are accepted.
## If all coroutines are accepted, it will send an array of accepted outputs.
## [br][br]
## Also sees [method Promise.any].
static func anyReject(
	promises : Array[Promise],
	executeOnStart : bool = true
) -> Promise:
	return Promise.new(AnyRejectCoroutine.new(promises), executeOnStart)


	# <BASE CLASSES>
## Class for Interfere Coroutine Promise Logic
class InterfereCoroutine extends DirectCoroutineLogic:
	var _interfere
	
	func _init(promise, interfere) -> void:
		super(promise)
		_interfere = interfere
	
	func _execute() -> void:
		super()
		connect_coroutine(_interfere, reject)

## Class for Hold Coroutine Promise Logic
class HoldCoroutine extends DirectCoroutineLogic:
	signal _unpause
	
	var _unpaused_flag : bool
	var _interfere
	
	func _init(promise, interfere) -> void:
		super(promise)
		_interfere = interfere
	
	func unpause_coroutine(_output = null) -> void:
		_unpaused_flag = true
		_unpause.emit()
	
	func _execute() -> void:
		connect_coroutine(_promise, _on_promise_finish)
		connect_coroutine(_interfere, unpause_coroutine)
	func _on_promise_finish(output) -> void:
		if !_unpaused_flag: await _unpause
		_on_thread_finish.call(output)

## Class for Resource Loading Coroutine Promise Logic
class ResourceCoroutine extends OnSignalCoroutine:
	var _resource_name : String
	var _type_hint : String
	var _use_sub_threads : bool
	var _cache_mode : ResourceLoader.CacheMode
	
	func _init(
		sig : Signal,
		resource_name : String,
		type_hint : String = "",
		use_sub_threads : bool = false,
		cache_mode : ResourceLoader.CacheMode = 1,
	) -> void:
		super(sig)
		_resource_name = resource_name
		_type_hint = type_hint
		_use_sub_threads = use_sub_threads
		_cache_mode = cache_mode
	
	func _on_signal() -> void:
		match ResourceLoader.load_threaded_get_status(_resource_name):
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
				reject(ERR_CANT_ACQUIRE_RESOURCE)
			ResourceLoader.THREAD_LOAD_LOADED:
				resolve(ResourceLoader.load_threaded_get(_resource_name))
	
	func _execute() -> void:
		if !ResourceLoader.exists(_resource_name):
			reject(ERR_CANT_ACQUIRE_RESOURCE)
			return
		
		ResourceLoader.load_threaded_request(
			_resource_name,
			_type_hint,
			_use_sub_threads,
			_cache_mode,
		)
		super()
		_on_signal()

## Class for Sort Coroutine Promise Logic
class SortCoroutine extends AllCoroutine:
	func _on_thread_finish(output, _index : int) -> void:
		_outputs[_outputs.size() - _counter] = output
		_counter -= 1
		
		if _counter == 0:
			resolve(_outputs)
## Class for FirstN Coroutine Promise Logic
class FirstNCoroutine extends SortCoroutine:
	func _init(promises : Array, num : int) -> void:
		_outputs.resize(min(promises.size(), num))
		_counter = _outputs.size()
		_promise = promises
	
	func _on_thread_finish(output, _index : int) -> void:
		if _counter <= 0: return
		super(output, _index)

## Class for RSort Coroutine Promise Logic
class RSortCoroutine extends AllCoroutine:
	func _on_thread_finish(output, _index : int) -> void:
		_counter -= 1
		_outputs[_counter] = output
		
		if _counter == 0:
			resolve(_outputs)
## Class for LastN Coroutine Promise Logic
class LastNCoroutine extends RSortCoroutine:
	var _ignore_threads : int
	
	func _init(promises : Array, num : int) -> void:
		_outputs.resize(min(promises.size(), num))
		_counter = _outputs.size()
		_ignore_threads = promises.size() - _counter
		_promise = promises
	
	func _on_thread_finish(output, _index : int) -> void:
		if _ignore_threads > 0:
			_ignore_threads -= 1
			return
		super(output, _index)


## Class for Pipe Coroutine Promise Logic
class PipeCoroutine extends MultiCoroutine:
	func _init(promises : Array) -> void:
		_promise = promises
	
	func _execute() -> void:
		connect_coroutine(_promise[0], _on_thread_finish.bind(1))
	func _on_thread_finish(output, next_index : int) -> void:
		var promise = _promise[next_index - 1]
		if promise is Promise && promise.peek() == PromiseStatus.Rejected:
			reject(output)
			return
		if next_index >= _promise.size():
			resolve(output)
			return
		
		promise = _promise[next_index]
		if promise is Callable:
			promise = promise.bind(output)
		elif promise is Promise:
			promise.reset()
			promise._logic.unbind()
			promise._logic.bind(output)
		
		connect_coroutine(
			promise,
			_on_thread_finish.bind(next_index + 1)
		)
		if promise is Promise && promise.peek() == PromiseStatus.Initialized:
			promise.execute()

## Class for AnyReject Coroutine Promise Logic
class AnyRejectCoroutine extends ArrayCoroutine:
	func _init(promises : Array[Promise]) -> void:
		super(promises)
	
	func _on_thread_finish(output, index : int) -> void:
		super(output, index)
		if (_promise[index] as Promise).peek() == PromiseStatus.Rejected:
			resolve(output)
			return
		
		if _counter == 0:
			resolve(_outputs)
