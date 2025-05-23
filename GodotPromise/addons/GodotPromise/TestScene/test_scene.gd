# Made by Xavier Alvarez. A part of the "GodotPromise" Godot addon.
@tool
extends Control

@export var start_tests : bool:
	set(val):
		start_tests = val
		
		if is_node_ready():
			await all_check()


	# <HELPER FUNCTIONS>
func timeout(time : float) -> Signal:
	return get_tree().create_timer(time).timeout
func caller(time : float, message : String) -> String:
	await timeout(time)
	return "Returned with time (" + str(time) + ") and message: \"" + message + "\""


func all_check() -> void:
	print("Starting Check...\n")
	await all_tests_check()
	await all_EX_tests_check()
	print("Check Finished")


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
	var promise := Promise.new(null).finally("Message")
	var external := Promise.new(timeout(0.1), false).finally("Message")
	
	await promise.finished
	timeout(1).connect(external.execute)
	
	print(
		"Start test_new()",
		"\n<null> Output: ",
		await Promise.new().finished,
		"\n<signal> Output: ",
		await Promise.new(timeout(0.1)).finished,
		"\n<Callable> Output: ",
		await Promise.new(caller.bind(0.1, "Message")).finished,
		"\n<Promise (Unexecuted, Unfinished)> Output: ",
		await Promise.new(Promise.new(timeout(0.1), false).finally("Message")).finished,
		"\n<Promise (Unfinished)> Output: ",
		await Promise.new(Promise.new(timeout(0.1)).finally("Message")).finished,
		"\n<Promise (Finished)> Output: ",
		await Promise.new(promise).finished,
		"\n<Promise (External Resolve)> Output: ",
		await Promise.new(external.finished).finished,
		"\nEnd test_new()\n",
	)

func test_all() -> void:
	print(
		"Start test_all()",
		"\nOutput: ",
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
		"\nOutput: ",
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
		"\nOutput: ",
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
		"\nOutput: ",
		await Promise.any([
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
		"\nOutput: ",
		await Promise.reject("Rejected").finished,
		"\nOutput .new(): ",
		await Promise.new(Promise.reject("Rejected")).finished,
		"\nEnd test_reject()\n",
	)
func test_resolve() -> void:
	print(
		"Start test_resolve()",
		"\nOutput: ",
		await Promise.resolve("Resolved").finished,
		"\nOutput .new(): ",
		await Promise.new(Promise.resolve("Rejected")).finished,
		"\nEnd test_resolve()\n",
	)

func test_withCallback() -> void:
	var output : Array = await Promise.all([
		Promise.withCallback(
			_resolver_callback_test.bind(0.5, false)
		).then("Output was Resolved").catch("Output was Rejected"),
		Promise.withCallback(
			_resolver_callback_test.bind(0.5, true)
		).then("Output was Resolved").catch("Output was Rejected"),
	]).finished
	
	print(
		"Start test_withCallback()",
		"\nTest Inner Reject:",
		"\nOutput: ",
		output[0],
		"\nTest Inner Resolve:\nOutput: ",
		output[1],
		"\nEnd test_withCallback()\n"
	)
func test_withResolvers() -> void:
	var promise_data := Promise.withResolvers(caller.bind(0.5, "Test Reject"))
	_resolver_test(0.2, promise_data.Reject.bind("Outer Rejected"))
	print(
		"Start test_withResolvers()",
		"\nTest Outer Reject:",
		"\nOutput: ",
		await promise_data.Promise.then(
			"Output was Resolved"
		).catch("Output was Rejected").finished
	)
	
	var accept := Promise.withResolvers(caller.bind(0.5, "Test Accept"))
	_resolver_test(0.2, accept.Resolve.bind("Outer Resolved"))
	print(
		"Test Outer Resolve:\nOutput: ",
		await accept.Promise.then(
			"Output was Resolved"
		).catch("Output was Rejected").finished,
		"\nEnd test_withResolvers()\n"
	)
func test_withCallbackResolvers() -> void:
	var output : Array = await Promise.all([
		Promise.withCallbackResolvers(
			_resolver_callback_test.bind(0.5, false)
		).Promise.then("Output was Resolved").catch("Output was Rejected"),
		Promise.withCallbackResolvers(
			_resolver_callback_test.bind(0.5, true)
		).Promise.then("Output was Resolved").catch("Output was Rejected"),
	]).finished
	
	print(
		"Start withCallbackResolvers()",
		"\nTest Inner Reject:",
		"\nOutput: ",
		output[0],
		"\nTest Inner Resolve:\nOutput: ",
		output[1],
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
func _resolver_test(time : float, call : Callable) -> void:
	await timeout(time)
	await call.call()
func _resolver_callback_test(resolver : Callable, rejecter : Callable, time : float, solution : bool) -> void:
	await _resolver_test(time, _callback_test.bind(resolver, rejecter, solution))
func _callback_test(resolver : Callable, rejecter : Callable, solution : bool) -> void:
	if solution:
		if resolver.is_valid():
			resolver.call("Resolved")
			return
	if rejecter.is_valid():
		rejecter.call("Rejected")

func _pipe_test_funcs(arg : int) -> int:
	return arg * 2
func test_finally() -> void:
	var output : Array = await Promise.all([
		Promise.reject("Rejected").then("Thened").finally("Test Rejected Output"),
		Promise.resolve("Resolved").catch("Catched").finally("Test Resolved Output"),
		Promise.reject("Rejected").finally(Promise.resolve("Resolved")).then("Accepted").catch("Rejected"),
		Promise.resolve("Resolved").finally(Promise.reject("Rejected")).then("Accepted").catch("Rejected"),
		Promise.new(1).finally(_pipe_test_funcs, true),
		Promise.new(Promise.reject(1)).finally(_pipe_test_funcs, true).finally(_pipe_test_funcs, true).finally(_pipe_test_funcs, true),
		Promise.new(1).finally(_pipe_test_funcs, true).finally(_pipe_test_funcs, true).finally(_pipe_test_funcs, true),
	]).finished
	
	print(
		"Start test_finally()",
		"\nTest on Rejected:",
		"\nOutput: ",
		output[0],
		"\nTest on Resolved:\nOutput: ",
		output[1],
		"\nOutput Rejected to Accepted: ",
		output[2],
		"\nOutput Accepted to Rejected: ",
		output[3],
		"\nPipeline X1 (Resolved): ",
		output[4],
		"\nPipeline X3 (Reject): ",
		output[5],
		"\nPipeline X3 (Resolved): ",
		output[6],
		"\nEnd test_finally()\n"
	)

func test_catch() -> void:
	var output : Array = await Promise.all([
		Promise.reject("Rejected").then("Thened").catch("Catched"),
		Promise.resolve("Resolved").then("Thened").catch("Catched"),
		Promise.reject("Resolved").then("Thened").catch("Catched").then("Thened"),
		Promise.resolve("Resolved").then("Thened").catch("Catched").then("Thened"),
		Promise.new(Promise.reject("Rejected")).then("Thened").catch("Catched"),
		Promise.new(Promise.resolve("Resolved")).then("Thened").catch("Catched"),
		Promise.new(Promise.reject("Resolved")).then("Thened").catch("Catched").then("Thened"),
		Promise.new(Promise.resolve("Resolved")).then("Thened").catch("Catched").then("Thened"),
		Promise.new(Promise.reject(1)).catch(_pipe_test_funcs, true),
		Promise.new(Promise.resolve(1)).catch(_pipe_test_funcs, true).catch(_pipe_test_funcs, true).catch(_pipe_test_funcs, true),
		Promise.new(Promise.reject(1)).catch(_pipe_test_funcs, true).catch(_pipe_test_funcs, true).catch(_pipe_test_funcs, true),
	]).finished
	
	print(
		"Start test_catch()",
		"\nTest on Rejected:\nOutput: ",
		output[0],
		"\nTest on Resolved:\nOutput: ",
		output[1],
		"\nTest on Rejected x2:\nOutput: ",
		output[2],
		"\nTest on Resolved x2:\nOutput: ",
		output[3],
		"\nTest on .new(Rejected):\nOutput: ",
		output[4],
		"\nTest on .new(Resolved):\nOutput: ",
		output[5],
		"\nTest on .new(Rejected) x2:\nOutput: ",
		output[6],
		"\nTest on .new(Resolved) x2:\nOutput: ",
		output[7],
		"\nPipeline X1 (Rejected): ",
		output[8],
		"\nPipeline X3 (Resolved): ",
		output[9],
		"\nPipeline X3 (Rejected): ",
		output[10],
		"\nEnd test_catch()\n"
	)
func test_then() -> void:
	var output : Array = await Promise.all([
		Promise.reject("Rejected").catch("Catched").then("Thened"),
		Promise.resolve("Resolved").catch("Catched").then("Thened"),
		Promise.reject("Both").catch("Catched").then("Thened").catch("Catched"),
		Promise.resolve("Both").catch("Catched").then("Thened").catch("Catched"),
		Promise.new(Promise.reject("Rejected")).catch("Catched").then("Thened"),
		Promise.new(Promise.resolve("Resolved")).catch("Catched").then("Thened"),
		Promise.new(Promise.reject("Resolved")).catch("Catched").then("Thened").catch("Catched"),
		Promise.new(Promise.resolve("Resolved")).catch("Catched").then("Thened").catch("Catched"),
		Promise.new(1).then(_pipe_test_funcs, true),
		Promise.new(Promise.reject(1)).then(_pipe_test_funcs, true).then(_pipe_test_funcs, true).then(_pipe_test_funcs, true),
		Promise.new(1).then(_pipe_test_funcs, true).then(_pipe_test_funcs, true).then(_pipe_test_funcs, true),
	]).finished
	
	print(
		"Start test_then()",
		"\nTest on Rejected:\nOutput: ",
		output[0],
		"\nTest on Resolved:\nOutput: ",
		output[1],
		"\nTest on Rejected x2:\nOutput: ",
		output[2],
		"\nTest on Resolved x2:\nOutput: ",
		output[3],
		"\nTest on .new(Rejected):\nOutput: ",
		output[4],
		"\nTest on .new(Resolved):\nOutput: ",
		output[5],
		"\nTest on .new(Rejected) x2:\nOutput: ",
		output[6],
		"\nTest on .new(Resolved) x2:\nOutput: ",
		output[7],
		"\nPipeline X1 (Resolved): ",
		output[8],
		"\nPipeline X3 (Rejected): ",
		output[9],
		"\nPipeline X3 (Resolved): ",
		output[10],
		"\nEnd test_then()\n"
	)



	# <PROMISE EX>
func all_EX_tests_check() -> void:
	await test_interfere()
	
	await test_hold()
	
	await test_resource()
	
	await test_sort()
	await test_rsort()
	
	await test_firstN()
	await test_lastN()
	
	await test_pipe()
	
	await test_anyReject()

func test_interfere() -> void:
	var output : Array = await Promise.all([
		PromiseEx.interfere(
			caller.bind(0.25, "Accepted 0.25"),
			caller.bind(0.5, "Rejected 0.5")
		),
		PromiseEx.interfere(
			caller.bind(0.5, "Accepted 0.5"),
			caller.bind(0.25, "Rejected 0.25")
		),
		PromiseEx.interfere(
			caller.bind(0.5, "Accepted 0.5"),
			caller.bind(0.5, "Rejected 0.5")
		),
	]).finished
	
	print(
		"Start test_interfere()",
		"\nPromise 0.25, Interfere 0.5",
		"\nOutput: ",
		output[0],
		"\nPromise 0.5, Interfere 0.25",
		"\nOutput: ",
		output[1],
		"\nPromise 0.5, Interfere 0.5",
		"\nOutput: ",
		output[2],
		"\nEnd test_interfere()\n",
	)

func test_hold() -> void:
	print("Start test_hold()")
	timeout(0.25).connect(print.bind("0.25 seconds have passed"))
	
	var output : Array = await Promise.all([
		PromiseEx.hold(caller.bind(0.25, "Resolved 0.25"), timeout(0.5)),
		PromiseEx.hold(caller.bind(0.5, "Resolved 0.5"), timeout(0.25)),
	]).finished
	
	print(
		"Promise 0.25, Hold 0.5",
		"\nOutput: ",
		output[0],
		"\nPromise 0.5, Hold 0.25",
		"\nOutput: ",
		output[1],
		"\nEnd test_hold()\n",
	)

func test_resource() -> void:
	var output : Array = await Promise.all([
		PromiseEx.resource(get_tree().process_frame, "res://addons/GodotPromise/src/GodotPromise.gd"),
		PromiseEx.resource(get_tree().process_frame, "res://addons/GodotPromise/src/FileDoesn'tExist.gd"),
	]).finished
	
	print(
		"Start test_resource()",
		"\nFile Exists - Output: ",
		"No Resource Found" if output[0] is int && output[0] == ERR_CANT_ACQUIRE_RESOURCE else output[0],
		"\nFile Doesn't Exist - Output: ",
		"No Resource Found" if output[1] is int && output[1] == ERR_CANT_ACQUIRE_RESOURCE else output[1],
		"\nEnd test_resource()\n",
	)

func test_sort() -> void:
	print(
		"Start test_sort()",
		"\nOutput: ",
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
		"\nOutput: ",
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
	var output : Array = await Promise.all([
		PromiseEx.firstN([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5"))
		], 3),
		PromiseEx.firstN([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		], 5),
	]).finished
	
	print(
		"Start test_firstN()",
		"\nFive coroutines, n=3",
		"\nOutput: ",
		output[0],
		"\nThree coroutines, n=5",
		"\nOutput: ",
		output[1],
		"\nEnd test_firstN()\n",
	)
func test_lastN() -> void:
	var output : Array = await Promise.all([
		PromiseEx.lastN([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.1, "Rejected 0.1")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		], 3),
		PromiseEx.lastN([
			Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
			Promise.reject(caller.bind(0.2, "Rejected 0.2")),
			Promise.new(caller.bind(0.5, "Resolved 0.5")),
		], 5),
	]).finished
	
	print(
		"Start test_lastN()",
		"\nFive coroutines, n=3",
		"\nOutput: ",
		output[0],
		"\nThree coroutines, n=5",
		"\nOutput: ",
		output[1],
		"\nEnd test_lastN()\n",
	)

func test_pipe() -> void:
	var output : Array = await Promise.all([
		PromiseEx.pipe([
			_pipeline_test.bind(0),
			_pipeline_test,
			_pipeline_test,
			Promise.new(_pipeline_test, false),
			_pipeline_test,
			_pipeline_test,
		], 3),
		PromiseEx.pipe([
			_pipeline_test.bind(0),
			_pipeline_test,
			_pipeline_test,
			Promise.reject("FAILED"),
			_pipeline_test,
			_pipeline_test,
		], 5),
	]).finished
	
	print(
		"Start test_pipe()",
		"\nAdd 1+1+1+1+1+1. Output: ",
		output[0],
		"\nForce Reject. Output: ",
		output[1],
		"\nEnd test_pipe()\n",
	)
func _pipeline_test(output : int) -> int:
	return output + 1

func test_anyReject() -> void:
	print(
		"Start test_anyReject()",
		"\nOutput: ",
		await PromiseEx.anyReject([
			Promise.resolve(caller.bind(0.2, "Resolved 0.2")),
			Promise.reject(caller.bind(0.7, "Rejected 0.7")),
			Promise.new(caller.bind(0.4, "Resolved 0.4")),
			Promise.reject(caller.bind(0.3, "Rejected 0.3")),
			Promise.new(caller.bind(0.1, "Resolved 0.1")),
		]).finished,
		"\nEnd test_anyReject()\n",
	)
