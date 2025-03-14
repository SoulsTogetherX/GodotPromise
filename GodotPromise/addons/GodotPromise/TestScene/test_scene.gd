# Made by Xavier Alvarez. A part of the "GodotPromise" Godot addon.
@tool
extends Control

@export_tool_button("Start Tests") var start_tests = all_tests_check


func timeout(time : float) -> Signal:
	return get_tree().create_timer(time).timeout
func caller(time : float, message : String) -> String:
	await timeout(time)
	return "Returned with time (" + str(time) + ") and message: \"" + message + "\""
func all_tests_check() -> void:
	await test_all()
	await test_allSettled()
	
	await test_race()
	await test_any()
	
	await test_reject()
	await test_resolve()
	
	await test_withResolvers()
	await test_withCallback()
	await test_withCallbackResolvers()
	
	await test_finally()
	await test_catch()
	await test_then()


func test_all() -> void:
	print(
		"Start test_all()\n",
		"Output:",
		await Promise.all([
			caller.bind(0.3, "0.3"),
			caller.bind(0.2, "0.2"),
			caller.bind(0.4, "0.4"),
			caller.bind(0.1, "0.1"),
			caller.bind(0.5, "0.5")
		]).finished,
		"\nEnd test_all()\n",
	)
func test_allSettled() -> void:
	print(
		"Start test_allSettled()\n",
		"Output:",
		await Promise.allSettled([
			Promise.resolve("Resolved 0.3"),
			Promise.reject("Rejected 0.2"),
			Promise.new(caller.bind(0.4, "0.4")),
			Promise.reject("Rejected 0.1"),
			Promise.new(caller.bind(0.5, "0.5"))
		]).finished,
		"\nEnd test_allSettled()\n",
	)

func test_race() -> void:
	print(
		"Start test_race()\n",
		"Output:",
		await Promise.race([
			caller.bind(0.3, "0.3"),
			caller.bind(0.2, "0.2"),
			caller.bind(0.4, "0.4"),
			caller.bind(0.1, "0.1"),
			caller.bind(0.5, "0.5")
		]).finished,
		"\nEnd test_race()\n",
	)
func test_any() -> void:
	print(
		"Start test_any()\n",
		"Output:",
		await Promise.any([
			Promise.resolve("Resolved 0.3"),
			Promise.reject("Rejected 0.2"),
			Promise.new(caller.bind(0.4, "0.4")),
			Promise.reject("Rejected 0.1"),
			Promise.new(caller.bind(0.5, "0.5"))
		]).finished,
		"\nEnd test_any()\n",
	)

func test_reject() -> void:
	print(
		"Start test_reject()\n",
		"Output:",
		await Promise.reject("Rejected").finished,
		"\nEnd test_reject()\n",
	)
func test_resolve() -> void:
	print(
		"Start test_resolve()\n",
		"Output:",
		await Promise.resolve("Resolved").finished,
		"\nEnd test_resolve()\n",
	)

func test_withCallback() -> void:
	print(
		"Start test_withCallback()\n",
		"Test Inner Reject:\n",
		"Output: ",
		await Promise.withCallback(_callback_test.bind(false)).catch("Output was Rejected").finished,
		"\nTest Inner Resolve:\nOutput: ",
		await Promise.withCallback(_callback_test.bind(true)).then("Output was Resolved").finished,
		"\nEnd test_withCallback()\n"
	)
func test_withResolvers() -> void:
	var reject := Promise.withResolvers(caller.bind(0.5, "Test Reject"))
	_resolver_test(0.2, reject.Reject.bind("Outer Rejected"))
	print(
		"Start test_withResolvers()\n",
		"Test Outer Reject:\n",
		"Output: ",
		await reject.Promise.finished
	)
	
	var accept := Promise.withResolvers(caller.bind(0.5, "Test Accept"))
	_resolver_test(0.2, accept.Resolve.bind("Outer Resolved"))
	print(
		"Test Outer Resolve:\nOutput: ",
		await accept.Promise.finished,
		"\nEnd test_withResolvers()\n"
	)
func test_withCallbackResolvers() -> void:
	print(
		"Start withCallbackResolvers()\n",
		"Test Inner Reject:\n",
		"Output: ",
		await Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, false)).Promise.catch("Output was Rejected").finished,
		"\nTest Inner Resolve:\nOutput: ",
		await Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, true)).Promise.then("Output was Resolved").finished,
	)
	
	var reject := Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, false))
	_resolver_test(0.2, reject.Reject.bind("Outer Rejected"))
	print(
		"Test Outer Reject:\n",
		"Output: ",
		await reject.Promise.finished
	)
	
	var accept := Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, true))
	_resolver_test(0.2, accept.Resolve.bind("Outer Resolved"))
	print(
		"Test Outer Resolve:\nOutput: ",
		await accept.Promise.finished,
		"\nEnd withCallbackResolvers()\n"
	)
func _callback_test(resolver : Callable, rejecter : Callable, resolve : bool) -> void:
	if resolve:
		if resolver.is_valid(): resolver.call("Resolved")
	else:
		if rejecter.is_valid(): rejecter.call("Rejected")
func _resolver_test(time : float, call : Callable) -> void:
	timeout(time).connect(call)
func _resolver_callback_test(resolver : Callable, rejecter : Callable, time : float, resolve : bool) -> void:
	_resolver_test(time, _callback_test.bind(resolver, rejecter, resolve))

func test_finally() -> void:
	print(
		"Start test_finally()\n",
		"Test on Rejected:\n",
		"Output: ",
		await Promise.reject("Rejected").then("Thened").finally("Test Rejected Output").finished,
		"\nTest on Resolved:\nOutput: ",
		await Promise.resolve("Resolved").catch("Catched").finally("Test Resolved Output").finished,
		"\nEnd test_finally()\n"
	)
func test_catch() -> void:
	print(
		"Start test_catch()\n",
		"Test on Rejected:\n",
		"Output: ",
		await Promise.reject("Rejected").then("Thened").catch("Catched").finished,
		"\nTest on Resolved:\nOutput: ",
		await Promise.resolve("Resolved").then("Thened").catch("Catched").finished,
		"\nEnd test_catch()\n"
	)
func test_then() -> void:
	print(
		"Start test_then()\n",
		"Test on Rejected:\n",
		"Output: ",
		await Promise.reject("Rejected").catch("Catched").then("Thened").finished,
		"\nTest on Resolved:\nOutput: ",
		await Promise.resolve("Resolved").catch("Catched").then("Thened").finished,
		"\nEnd test_then()\n"
	)
