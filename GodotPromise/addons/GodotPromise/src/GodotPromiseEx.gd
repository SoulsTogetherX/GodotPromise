# Made by Xavier Alvarez. A part of the "GodotPromise" Godot addon.
@icon("res://addons/GodotPromise/assets/GodotPromiseEx.svg")
@tool
class_name PromiseEx extends Promise
## An extension to the [Promise] class to showcase how easy it is to create custom [Promise] behavior.

	# <PROMISE CREATION FUNCTIONS>
## Requests two coroutines that race. If [param promise] finishes first, this [Promise] is accepted.
## If [param interfere] finishes first, this [Promise] is rejected.[br]
## If the coroutines end at the same time, [param promise] has the priority.
static func interfere(promise, interfere) -> Promise:
	return Promise.new(InterfereCoroutine.new(promise, interfere), true)

## Creates a [Promise] that attempts to resolve [param promise] and [param release] coroutines
## at the same time. However, this [Promise] will not resolve until [param release] has resolved
## first.
## [br][br]
## Also see [method hold].
static func hold(promise = null, release = null) -> Promise:
	return Promise.new(HoldCoroutine.new(promise, release), true)

## Waits until all coroutines, then returns their result in an [Array] sorted by order they finished
## in. First finished starts the [Array] and last finished ends the [Array].
## [br][br]
## Also see [method Promise.all].
static func sort(promises : Array) -> Promise:
	return Promise.new(SortCoroutine.new(promises), true)
## Waits until all coroutines, then returns their result in an [Array] reverse sorted by order they
## finished in. First finished ends the [Array] and last finished starts the [Array].
## [br][br]
## Also see [method Promise.all].
static func rSort(promises : Array) -> Promise:
	return Promise.new(RSortCoroutine.new(promises), true)

## Waits until all coroutines, then returns the results of the first [param num]
## coroutines to finish in an [Array], sorted by the order they finished in.
## [br][br]
## Also see [method sort].
static func firstN(promises : Array, num : int) -> Promise:
	return Promise.new(FirstNCoroutine.new(promises, num), true)
## Waits until all coroutines, then returns the results of the first [param num]
## coroutines to finish in an [Array], reverse sorted by the order they finished in.
## [br][br]
## Also see [method rSort].
static func lastN(promises : Array, num : int) -> Promise:
	return Promise.new(LastNCoroutine.new(promises, num), true)

## Returns a [Promise] that finishes and returns the result of the first coroutine to be rejected
## from the given coroutines. It ignores all coroutines accept, unless all coroutines are accepted.
## If all coroutines are accepted, it will send an array of accepted outputs.
## [br][br]
## Also sees [method Promise.any].
static func anyReject(promises : Array[Promise]) -> Promise:
	return Promise.new(AnyRejectCoroutine.new(promises), true)


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
	
	func emit_unpaused(_output = null) -> void:
		_unpaused_flag = true
		_unpause.emit()
	
	func _execute() -> void:
		connect_coroutine(_promise, _on_thread_finish)
		connect_coroutine(_interfere, emit_unpaused)
	func _on_thread_finish(output) -> void:
		if !_unpaused_flag: await _unpause
		_status_process.call(output)

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

## Class for AnyReject Coroutine Promise Logic
class AnyRejectCoroutine extends ArrayCoroutine:
	func _init(promises : Array[Promise]) -> void:
		super(promises)
	
	func _on_thread_finish(output, index : int) -> void:
		super(output, index)
		if (_promise[index] as Promise).get_status() == PromiseStatus.Rejected:
			resolve(output)
			return
		
		if _counter == 0:
			resolve(_outputs)
