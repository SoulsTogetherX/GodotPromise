# Made by Xavier Alvarez. A part of the "GodotPromise" Godot addon.
@tool
extends Control

@export var start_tests : bool:
	set(val):
		start_tests = val
		await all_tests_check()
		await all_EX_tests_check()


	# <HELPER FUNCTIONS>
func timeout(time : float) -> Signal:
	return get_tree().create_timer(time).timeout
func caller(time : float, message : String) -> String:
	await timeout(time)
	return "Returned with time (" + str(time) + ") and message: \"" + message + "\""

	# <PROMISE>
func all_tests_check() -> void:
	await test_new()
	
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

func test_new() -> void:
	print(
		"Start test_new()",
		"\n<null> Output:",
		await Promise.new().finished,
		"\n<signal> Output:",
		await Promise.new(timeout(0.1)).finished,
		"\n<Callable> Output:",
		await Promise.new(caller.bind(0.1, "Message")).finished,
		"\n<Promise (Unfinished)> Output:",
		await Promise.new(Promise.new(timeout(0.1))).finished,
		"\n<Promise (Finished)> Output:",
		await Promise.new(Promise.new(null)).finished,
		"\nEnd test_new()\n",
	)

func test_all() -> void:
	print(
		"Start test_all()",
		"\nOutput:",
		await Promise.all([
			caller.bind(0.3, "Resolved 0.3"),
			caller.bind(0.2, "Resolved 0.2"),
			caller.bind(0.4, "Resolved 0.4"),
			caller.bind(0.1, "Resolved 0.1"),
			caller.bind(0.5, "Resolved 0.5")
		]).finished,
		"\nEnd test_all()\n",
	)
func test_allSettled() -> void:
	print(
		"Start test_allSettled()",
		"\nOutput:",
		await Promise.allSettled([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5"))
		]).finished,
		"\nEnd test_allSettled()\n",
	)

func test_race() -> void:
	print(
		"Start test_race()",
		"\nOutput:",
		await Promise.race([
			caller.bind(0.3, "Resolved 0.3"),
			caller.bind(0.2, "Resolved 0.2"),
			caller.bind(0.4, "Resolved 0.4"),
			caller.bind(0.1, "Resolved 0.1"),
			caller.bind(0.5, "Resolved 0.5")
		]).finished,
		"\nEnd test_race()\n",
	)
func test_any() -> void:
	print(
		"Start test_any()",
		"\nOutput:",
		await Promise.allSettled([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5"))
		]).finished,
		"\nEnd test_any()\n",
	)

func test_reject() -> void:
	print(
		"Start test_reject()",
		"\nOutput:",
		await Promise.reject("Rejected").finished,
		"\nEnd test_reject()\n",
	)
func test_resolve() -> void:
	print(
		"Start test_resolve()",
		"\nOutput:",
		await Promise.resolve("Resolved").finished,
		"\nEnd test_resolve()\n",
	)

func test_withCallback() -> void:
	print(
		"Start test_withCallback()",
		"\nTest Inner Reject:",
		"\nOutput: ",
		await Promise.withCallback(_callback_test.bind(false)).catch("Output was Rejected").finished,
		"\nTest Inner Resolve:\nOutput: ",
		await Promise.withCallback(_callback_test.bind(true)).then("Output was Resolved").finished,
		"\nEnd test_withCallback()\n"
	)
func test_withResolvers() -> void:
	var reject := Promise.withResolvers(caller.bind(0.5, "Test Reject"))
	_resolver_test(0.2, reject.Reject.bind("Outer Rejected"))
	print(
		"Start test_withResolvers()",
		"\nTest Outer Reject:",
		"\nOutput: ",
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
		"Start withCallbackResolvers()",
		"\nTest Inner Reject:",
		"\nOutput: ",
		await Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, false)).Promise.catch("Output was Rejected").finished,
		"\nTest Inner Resolve:\nOutput: ",
		await Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, true)).Promise.then("Output was Resolved").finished,
	)
	
	var reject := Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, false))
	_resolver_test(0.2, reject.Reject.bind("Outer Rejected"))
	print(
		"Test Outer Reject:",
		"\nOutput: ",
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
		"Start test_finally()",
		"\nTest on Rejected:",
		"\nOutput: ",
		await Promise.reject("Rejected").then("Thened").finally("Test Rejected Output").finished,
		"\nTest on Resolved:\nOutput: ",
		await Promise.resolve("Resolved").catch("Catched").finally("Test Resolved Output").finished,
		"\nEnd test_finally()\n"
	)
func test_catch() -> void:
	print(
		"Start test_catch()",
		"\nTest on Rejected:",
		"\nOutput: ",
		await Promise.reject("Rejected").then("Thened").catch("Catched").finished,
		"\nTest on Resolved:\nOutput: ",
		await Promise.resolve("Resolved").then("Thened").catch("Catched").finished,
		"\nEnd test_catch()\n"
	)
func test_then() -> void:
	print(
		"Start test_then()",
		"\nTest on Rejected:",
		"\nOutput: ",
		await Promise.reject("Rejected").catch("Catched").then("Thened").finished,
		"\nTest on Resolved:\nOutput: ",
		await Promise.resolve("Resolved").catch("Catched").then("Thened").finished,
		"\nEnd test_then()\n"
	)



	# <PROMISE EX>
func all_EX_tests_check() -> void:
	await test_interfere()
	
	#await test_hold()
	await test_on_hold()
	
	await test_sort()
	await test_rsort()
	
	await test_firstN()
	await test_lastN()
	
	await test_anyReject()

func test_interfere() -> void:
	print(
		"Start test_interfere()",
		"\nPromise 0.5, Interfere 0.25",
		"\nOutput:",
		await PromiseEx.interfere(
			caller.bind(0.25, "Accepted 0.25"),
			caller.bind(0.5, "Rejected 0.5")
		).finished,
		"\nPromise 0.25, Interfere 0.5",
		"\nOutput:",
		await PromiseEx.interfere(
			caller.bind(0.5, "Accepted 0.5"),
			caller.bind(0.25, "Rejected 0.25")
		).finished,
		"\nPromise 0.5, Interfere 0.5",
		"\nOutput:",
		await PromiseEx.interfere(
			caller.bind(0.5, "Accepted 0.5"),
			caller.bind(0.5, "Rejected 0.5")
		).finished,
		"\nEnd test_interfere()\n",
	)

func test_hold() -> void:
	print("Start test_hold()")
	timeout(0.25).connect(print.bind("0.25 seconds have passed"))
	print(
		"promise 0.25, hold 0.5",
		"\nOutput:",
		await Promise.new("").hold(caller.bind(0.25, "Resolved 0.25"), timeout(0.5)).finished,
		"\npromise 0.5, hold 0.25",
		"\nOutput:",
		await Promise.new("").hold(caller.bind(0.5, "Resolved 0.5"), timeout(0.25)).finished,
		"\nEnd test_hold()\n",
	)
func test_on_hold() -> void:
	print("Start test_on_hold()")
	timeout(0.25).connect(print.bind("0.25 seconds have passed"))
	print(
		"promise 0.25, hold 0.5",
		"\nOutput:",
		await PromiseEx.on_hold(caller.bind(0.25, "Resolved 0.25"), timeout(0.5)).finished,
		"\npromise 0.5, hold 0.25",
		"\nOutput:",
		await PromiseEx.on_hold(caller.bind(0.5, "Resolved 0.5"), timeout(0.25)).finished,
		"\nEnd test_on_hold()\n",
	)

func test_sort() -> void:
	print(
		"Start test_sort()",
		"\nOutput:",
		await PromiseEx.sort([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		]).finished,
		"\nEnd test_sort()\n",
	)
func test_rsort() -> void:
	print(
		"Start test_rsort()",
		"\nOutput:",
		await PromiseEx.rSort([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		]).finished,
		"\nEnd test_rsort()\n",
	)

func test_firstN() -> void:
	print(
		"Start test_firstN()",
		"\nFive coroutines, n=3",
		"\nOutput:",
		await PromiseEx.firstN([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5"))
		], 3).finished,
		"\nThree coroutines, n=5",
		"\nOutput:",
		await PromiseEx.firstN([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		], 5).finished,
		"\nEnd test_firstN()\n",
	)
func test_lastN() -> void:
	print(
		"Start test_lastN()",
		"\nFive coroutines, n=3",
		"\nOutput:",
		await PromiseEx.lastN([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		], 3).finished,
		"\nThree coroutines, n=5",
		"\nOutput:",
		await PromiseEx.lastN([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		], 5).finished,
		"\nEnd test_lastN()\n",
	)

func test_anyReject() -> void:
	print(
		"Start test_anyReject()",
		"\nOutput:",
		await PromiseEx.anyReject([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		]).finished,
		"\nEnd test_anyReject()\n",
	)
