# Made by Xavier Alvarez. A part of the "GodotPromise" Godot addon. @2025
@tool
extends Control

#region External Variables
@export_tool_button("Test Promises") var check_action = all_check;
#endregion


#region Helper Methods
func _check_answer(correct, check) -> String:
	return "[color=green]Good[/color]" if check == correct else "[color=red]Bad[/color]"

func _callback_test(resolver : Callable, rejecter : Callable, solution : bool) -> void:
	if solution:
		if resolver.is_valid():
			resolver.call("Resolved")
			return
	if rejecter.is_valid():
		rejecter.call("Rejected")
func _resolver_test(time : float, call : Callable) -> void:
	await timeout(time)
	await call.call()
func _resolver_callback_test(resolver : Callable, rejecter : Callable, time : float, solution : bool) -> void:
	await _resolver_test(time, _callback_test.bind(resolver, rejecter, solution))

func _pipeline_test_1(arg : int) -> int:
	return arg * 2
func _pipeline_test_2(output : int) -> int:
	return output + 1

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
#endregion


#region Promise Test Methods
func all_tests_check() -> void:
	await test_new()
	
	await test_all()
	await test_allSettled()
	
	await test_race()
	await test_any()
	
	await test_reject()
	await test_resolve()
	
	await test_withCallback()
	await test_withResolvers()
	await test_withCallbackResolvers()
	
	await test_finally()
	
	await test_catch()
	await test_then()

func test_new() -> void:
	var promise := Promise.new(null).finally("Message")
	var external := Promise.new(timeout(0.1), false).finally("Message")
	
	await promise.finished
	timeout(1).connect(external.execute)
	
	print_rich(
		"Start test_new()",
		"\n<null> Output: ",
		_check_answer(
			null,
			await Promise.new().finished
		),
		"\n<signal> Output: ",
		_check_answer(
			null,
			await Promise.new(timeout(0.1)).finished
		),
		"\n<Callable> Output: ",
		_check_answer(
			"Returned with time (0.1) and message: \"Message\"",
			await Promise.new(caller.bind(0.1, "Message")).finished
		),
		"\n<Promise (Unexecuted, Unfinished)> Output: ",
		_check_answer(
			"Message",
			await Promise.new(Promise.new(timeout(0.1), false).finally("Message")).finished
		),
		"\n<Promise (Unfinished)> Output: ",
		_check_answer(
			"Message",
			await Promise.new(Promise.new(timeout(0.1)).finally("Message")).finished
		),
		"\n<Promise (Finished)> Output: ",
		_check_answer(
			"Message",
			await Promise.new(promise).finished
		),
		"\n<Promise (External Resolve)> Output: ",
		_check_answer(
			"Message",
			await Promise.new(external.finished).finished
		),
		"\nEnd test_new()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_all() -> void:
	print_rich(
		"Start test_all()",
		"\nOutput: ",
		_check_answer(
			[
				"Returned with time (0.3) and message: \"Resolved 0.3\"",
				"Returned with time (0.2) and message: \"Resolved 0.2\"",
				"Returned with time (0.4) and message: \"Resolved 0.4\"",
				"Returned with time (0.1) and message: \"Resolved 0.1\"",
				"Returned with time (0.5) and message: \"Resolved 0.5\""
			],
			await Promise.all([
				caller.bind(0.3, "Resolved 0.3"),
				caller.bind(0.2, "Resolved 0.2"),
				caller.bind(0.4, "Resolved 0.4"),
				caller.bind(0.1, "Resolved 0.1"),
				caller.bind(0.5, "Resolved 0.5")
			]).finished
		),
		"\nEnd test_all()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
func test_allSettled() -> void:
	print_rich(
		"Start test_allSettled()",
		"\nOutput: ",
		_check_answer(
			[true, false, true, false, true],
			await Promise.allSettled([
				Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
				Promise.reject(caller.bind(0.2, "Rejected 0.2")),
				Promise.new(caller.bind(0.4, "Resolved 0.4")),
				Promise.reject(caller.bind(0.1, "Rejected 0.1")),
				Promise.new(caller.bind(0.5, "Resolved 0.5"))
			]).finished
		),
		"\nEnd test_allSettled()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_race() -> void:
	print_rich(
		"Start test_race()",
		"\nOutput: ",
		_check_answer(
			"Returned with time (0.1) and message: \"Resolved 0.1\"",
			await Promise.race([
				caller.bind(0.3, "Resolved 0.3"),
				caller.bind(0.2, "Resolved 0.2"),
				caller.bind(0.4, "Resolved 0.4"),
				caller.bind(0.1, "Resolved 0.1"),
				caller.bind(0.5, "Resolved 0.5")
			]).finished
		),
		"\nEnd test_race()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
func test_any() -> void:
	print_rich(
		"Start test_any()",
		"\nOutput: ",
		_check_answer(
			"Returned with time (0.3) and message: \"Resolved 0.3\"",
			await Promise.any([
				Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
				Promise.reject(caller.bind(0.2, "Rejected 0.2")),
				Promise.new(caller.bind(0.4, "Resolved 0.4")),
				Promise.reject(caller.bind(0.1, "Rejected 0.1")),
				Promise.new(caller.bind(0.5, "Resolved 0.5"))
			]).finished
		),
		"\nEnd test_any()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_reject() -> void:
	print_rich(
		"Start test_reject()",
		"\nOutput: ",
		_check_answer(
			"Rejected",
			await Promise.reject("Rejected").finished,
		),
		"\nOutput .new(): ",
		_check_answer(
			"Rejected",
			await Promise.new(Promise.reject("Rejected")).finished,
		),
		"\nEnd test_reject()\n",
		"\nOutput raw: ",
		_check_answer(
			"Rejected",
			await Promise.reject_raw("Rejected").finished,
		),
		"\nOutput .new(raw): ",
		_check_answer(
			"Rejected",
			await Promise.new(Promise.reject_raw("Rejected")).finished,
		),
		"\nEnd test_reject()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
func test_resolve() -> void:
	print_rich(
		"Start test_resolve()",
		"\nOutput: ",
		_check_answer(
			"Resolved",
			await Promise.resolve("Resolved").finished,
		),
		"\nOutput .new(): ",
		_check_answer(
			"Resolved",
			await Promise.new(Promise.resolve("Resolved")).finished,
		),
		"\nOutput raw: ",
		_check_answer(
			"Resolved",
			await Promise.resolve_raw("Resolved").finished,
		),
		"\nOutput .new(raw): ",
		_check_answer(
			"Resolved",
			await Promise.new(Promise.resolve_raw("Resolved")).finished,
		),
		"\nEnd test_resolve()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_withCallback() -> void:
	var output : Array = await Promise.all([
		Promise.withCallback(
			_resolver_callback_test.bind(0.5, false)
		).then("Output was Resolved").catch("Output was Rejected"),
		Promise.withCallback(
			_resolver_callback_test.bind(0.5, true)
		).then("Output was Resolved").catch("Output was Rejected"),
	]).finished
	
	print_rich(
		"Start test_withCallback()",
		"\nTest Inner Reject:",
		"\nOutput: ",
		_check_answer(
			"Output was Rejected",
			output[0],
		),
		"\nTest Inner Resolve:\nOutput: ",
		_check_answer(
			"Output was Resolved",
			output[1],
		),
		"\nEnd test_withCallback()\n"
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
func test_withResolvers() -> void:
	var promise_data := Promise.withResolvers(caller.bind(0.5, "Test Reject"))
	_resolver_test(0.2, promise_data.Reject.bind("Outer Rejected"))
	print_rich(
		"Start test_withResolvers()",
		"\nTest Outer Reject:",
		"\nOutput: ",
		_check_answer(
			"Output was Rejected",
			await promise_data.Promise.then(
				"Output was Resolved"
			).catch("Output was Rejected").finished
		)
	)
	
	var accept := Promise.withResolvers(caller.bind(0.5, "Test Accept"))
	_resolver_test(0.2, accept.Resolve.bind("Outer Resolved"))
	print_rich(
		"Test Outer Resolve:\nOutput: ",
		_check_answer(
			"Output was Resolved",
			await accept.Promise.then(
				"Output was Resolved"
			).catch("Output was Rejected").finished
		),
		"\nEnd test_withResolvers()\n"
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
func test_withCallbackResolvers() -> void:
	var output : Array = await Promise.all([
		Promise.withCallbackResolvers(
			_resolver_callback_test.bind(0.5, false)
		).Promise.then("Output was Resolved").catch("Output was Rejected"),
		Promise.withCallbackResolvers(
			_resolver_callback_test.bind(0.5, true)
		).Promise.then("Output was Resolved").catch("Output was Rejected"),
	]).finished
	
	print_rich(
		"Start withCallbackResolvers()",
		"\nTest Inner Reject:",
		"\nOutput: ",
		_check_answer(
			"Output was Rejected",
			output[0]
		),
		"\nTest Inner Resolve:\nOutput: ",
		_check_answer(
			"Output was Resolved",
			output[1]
		)
	)
	
	var reject := Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, false))
	_resolver_test(0.2, reject.Reject.bind("Outer Rejected"))
	print_rich(
		"Test Outer Reject:",
		"\nOutput: ",
		_check_answer(
			"Outer Rejected",
			await reject.Promise.finished
		)
	)
	
	var accept := Promise.withCallbackResolvers(_resolver_callback_test.bind(0.5, true))
	_resolver_test(0.2, accept.Resolve.bind("Outer Resolved"))
	print_rich(
		"Test Outer Resolve:\nOutput: ",
		_check_answer(
			"Outer Resolved",
			await accept.Promise.finished
		),
		"\nEnd withCallbackResolvers()\n"
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout


func test_finally() -> void:
	var output : Array = await Promise.all([
		Promise.reject("Rejected").catch("Catched").finally("Test Rejected Output"),
		Promise.resolve("Resolved").then("Thened").finally("Test Resolved Output"),
		Promise.reject("Rejected").then("Thened").finally("Test Rejected Output"),
		Promise.resolve("Resolved").catch("Catched").finally("Test Resolved Output"),
		Promise.reject("Rejected").finally(Promise.resolve("Resolved")).then("Accepted").catch("Rejected"),
		Promise.resolve("Resolved").finally(Promise.reject("Rejected")).then("Accepted").catch("Rejected"),
		Promise.reject("Rejected").finally("finally-1").finally("finally-2"),
		Promise.resolve("Resolved").finally("finally-1").finally("finally-2"),
		Promise.new(1).finally(_pipeline_test_1, true),
		Promise.new(Promise.reject(1)).finally(_pipeline_test_1, true).finally(_pipeline_test_1, true).finally(_pipeline_test_1, true),
		Promise.new(1).finally(_pipeline_test_1, true).finally(_pipeline_test_1, true).finally(_pipeline_test_1, true),
	]).finished
	
	print_rich(
		"Start test_finally()",
		"\nTest on Rejected (Catched):\nOutput: ",
		_check_answer(
			"Test Rejected Output",
			output[0]
		),
		"\nTest on Resolved (Thened):\nOutput: ",
		_check_answer(
			"Test Resolved Output",
			output[1]
		),
		"\nTest on Rejected (Thened):\nOutput: ",
		_check_answer(
			"Test Rejected Output",
			output[2]
		),
		"\nTest on Resolved (Catched):\nOutput: ",
		_check_answer(
			"Test Resolved Output",
			output[3]
		),
		"\nOutput Rejected to Accepted: ",
		_check_answer(
			"Rejected",
			output[4]
		),
		"\nOutput Accepted to Rejected: ",
		_check_answer(
			"Accepted",
			output[5]
		),
		"\nFinally X2 (Rejected): ",
		_check_answer(
			"finally-2",
			output[6]
		),
		"\nFinally X2 (Resolved): ",
		_check_answer(
			"finally-2",
			output[7]
		),
		"\nPipeline X1 (Resolved): ",
		_check_answer(
			2,
			output[8]
		),
		"\nPipeline X3 (Reject): ",
		_check_answer(
			8,
			output[9]
		),
		"\nPipeline X3 (Resolved): ",
		_check_answer(
			8,
			output[10]
		),
		"\nEnd test_finally()\n"
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_catch() -> void:
	var output : Array = await Promise.all([
		Promise.reject("Rejected").then("Thened").catch("Catched"),
		Promise.resolve("Resolved").then("Thened").catch("Catched"),
		Promise.reject("Resolved").then("Thened").catch("Catched").then("Thened"),
		Promise.resolve("Resolved").then("Thened").catch("Catched").then("Thened"),
		Promise.reject("Rejected").then("Thened").catch("Catched"),
		Promise.resolve("Resolved").then("Thened").catch("Catched"),
		Promise.reject("Rejected").then("Thened-1").catch("Catched").then("Thened-2"),
		Promise.resolve("Resolved").then("Thened-1").catch("Catched").then("Thened-2"),
		Promise.reject("Rejected").catch("Catched-1", true, true).catch("Catched-2"),
		Promise.reject("Rejected").catch("Catched-1", true, false).catch("Catched-2"),
		Promise.reject(1).catch(_pipeline_test_1, true, false),
		Promise.resolve(1).catch(_pipeline_test_1, true, false).catch(_pipeline_test_1, true, false).catch(_pipeline_test_1, true, false),
		Promise.reject(1).catch(_pipeline_test_1, true, false).catch(_pipeline_test_1, true, false).catch(_pipeline_test_1, true, false),
	]).finished
	
	print_rich(
		"Start test_catch()",
		"\nTest on Rejected:\nOutput: ",
		_check_answer(
			"Catched",
			output[0]
		),
		"\nTest on Resolved:\nOutput: ",
		_check_answer(
			"Thened",
			output[1]
		),
		"\nTest on Rejected x2:\nOutput: ",
		_check_answer(
			"Catched",
			output[2]
		),
		"\nTest on Resolved x2:\nOutput: ",
		_check_answer(
			"Thened",
			output[3]
		),
		"\nTest on .new(Rejected):\nOutput: ",
		_check_answer(
			"Catched",
			output[4]
		),
		"\nTest on .new(Resolved):\nOutput: ",
		_check_answer(
			"Thened",
			output[5]
		),
		"\nTest on .new(Rejected) x2:\nOutput: ",
		_check_answer(
			"Catched",
			output[6]
		),
		"\nTest on .new(Resolved) x2:\nOutput: ",
		_check_answer(
			"Thened-2",
			output[7]
		),
		"\nTest on .new(Rejected, stopgate) x2:\nOutput: ",
		_check_answer(
			"Catched-1",
			output[8]
		),
		"\nTest on .new(Resolved, not stopgate) x2:\nOutput: ",
		_check_answer(
			"Catched-2",
			output[9]
		),
		"\nPipeline X1 (Rejected): ",
		_check_answer(
			2,
			output[10]
		),
		"\nPipeline X3 (Resolved): ",
		_check_answer(
			1,
			output[11]
		),
		"\nPipeline X3 (Rejected): ",
		_check_answer(
			8,
			output[12]
		),
		"\nEnd test_catch()\n"
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
func test_then() -> void:
	var output : Array = await Promise.all([
		Promise.reject("Rejected").catch("Catched").then("Thened"),
		Promise.resolve("Resolved").catch("Catched").then("Thened"),
		Promise.reject("Both").catch("Catched").then("Thened").catch("Catched"),
		Promise.resolve("Both").catch("Catched").then("Thened").catch("Catched"),
		Promise.reject("Rejected").catch("Catched").then("Thened"),
		Promise.resolve("Resolved").catch("Catched").then("Thened"),
		Promise.reject("Rejected").catch("Catched-1").then("Thened").catch("Catched-2"),
		Promise.resolve("Resolved").catch("Catched-1").then("Thened").catch("Catched-2"),
		Promise.resolve("Resolved").then("Thened-1", true, false).then("Thened-2"),
		Promise.resolve("Resolved").then("Thened-1", true, true).then("Thened-2"),
		Promise.resolve(1).then(_pipeline_test_1, true),
		Promise.reject(1).then(_pipeline_test_1, true).then(_pipeline_test_1, true).then(_pipeline_test_1, true),
		Promise.resolve(1).then(_pipeline_test_1, true).then(_pipeline_test_1, true).then(_pipeline_test_1, true),
	]).finished
	
	print_rich(
		"Start test_then()",
		"\nTest on Rejected:\nOutput: ",
		_check_answer(
			"Catched",
			output[0]
		),
		"\nTest on Resolved:\nOutput: ",
		_check_answer(
			"Thened",
			output[1]
		),
		"\nTest on Rejected x2:\nOutput: ",
		_check_answer(
			"Catched",
			output[2]
		),
		"\nTest on Resolved x2:\nOutput: ",
		_check_answer(
			"Thened",
			output[3]
		),
		"\nTest on .new(Rejected):\nOutput: ",
		_check_answer(
			"Catched",
			output[4]
		),
		"\nTest on .new(Resolved):\nOutput: ",
		_check_answer(
			"Thened",
			output[5]
		),
		"\nTest on .new(Rejected) x2:\nOutput: ",
		_check_answer(
			"Catched-1",
			output[6]
		),
		"\nTest on .new(Resolved) x2:\nOutput: ",
		_check_answer(
			"Thened",
			output[7]
		),
		"\nTest on .new(Rejected, not stopgate) x2:\nOutput: ",
		_check_answer(
			"Thened-2",
			output[8]
		),
		"\nTest on .new(Resolved, stopgate) x2:\nOutput: ",
		_check_answer(
			"Thened-1",
			output[9]
		),
		"\nPipeline X1 (Resolved): ",
		_check_answer(
			2,
			output[10]
		),
		"\nPipeline X3 (Rejected): ",
		_check_answer(
			1,
			output[11]
		),
		"\nPipeline X3 (Resolved): ",
		_check_answer(
			8,
			output[12]
		),
		"\nEnd test_then()\n"
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
#endregion


#region	PromiseEx Test Methods
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
	
	print_rich(
		"Start test_interfere()",
		"\nPromise 0.25, Interfere 0.5",
		"\nOutput: ",
		_check_answer(
			"Returned with time (0.25) and message: \"Accepted 0.25\"",
			output[0]
		),
		"\nPromise 0.5, Interfere 0.25",
		"\nOutput: ",
		_check_answer(
			"Returned with time (0.25) and message: \"Rejected 0.25\"",
			output[1]
		),
		"\nPromise 0.5, Interfere 0.5",
		"\nOutput: ",
		_check_answer(
			"Returned with time (0.5) and message: \"Accepted 0.5\"",
			output[2]
		),
		"\nEnd test_interfere()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_hold() -> void:
	timeout(0.25).connect(print.bind("0.25 seconds have passed"))
	
	var output : Array = await Promise.all([
		PromiseEx.hold(caller.bind(0.25, "Resolved 0.25"), timeout(0.5)),
		PromiseEx.hold(caller.bind(0.5, "Resolved 0.5"), timeout(0.25)),
	]).finished
	
	print_rich(
		"Start test_hold()\n",
		"Promise 0.25, Hold 0.5",
		"\nOutput: ",
		_check_answer(
			"Returned with time (0.25) and message: \"Resolved 0.25\"",
			output[0]
		),
		"\nPromise 0.5, Hold 0.25",
		"\nOutput: ",
		_check_answer(
			"Returned with time (0.5) and message: \"Resolved 0.5\"",
			output[1]
		),
		"\nEnd test_hold()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_resource() -> void:
	var output : Array = await Promise.all([
		PromiseEx.resource(get_tree().process_frame, "res://addons/GodotPromise/src/GodotPromise.gd"),
		PromiseEx.resource(get_tree().process_frame, "res://addons/GodotPromise/src/FileDoesn'tExist.gd"),
	]).finished
	
	print_rich(
		"Start test_resource()",
		"\nFile Exists - Output: ",
		_check_answer(
			false,
			output[0] is int && output[0] == ERR_CANT_ACQUIRE_RESOURCE
		),
		"\nFile Doesn't Exist - Output: ",
		_check_answer(
			true,
			output[1] is int && output[1] == ERR_CANT_ACQUIRE_RESOURCE
		),
		"\nEnd test_resource()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_sort() -> void:
	print_rich(
		"Start test_sort()",
		"\nOutput: ",
		_check_answer(
			[
				"Returned with time (0.1) and message: \"Rejected 0.1\"",
				"Returned with time (0.2) and message: \"Rejected 0.2\"",
				"Returned with time (0.3) and message: \"Resolved 0.3\"",
				"Returned with time (0.4) and message: \"Resolved 0.4\"",
				"Returned with time (0.5) and message: \"Resolved 0.5\""
			],
			await PromiseEx.sort([
				Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
				Promise.reject(caller.bind(0.2, "Rejected 0.2")),
				Promise.new(caller.bind(0.4, "Resolved 0.4")),
				Promise.reject(caller.bind(0.1, "Rejected 0.1")),
				Promise.new(caller.bind(0.5, "Resolved 0.5")),
			]).finished
		),
		"\nEnd test_sort()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
func test_rsort() -> void:
	print_rich(
		"Start test_rsort()",
		"\nOutput: ",
		_check_answer(
			[
				"Returned with time (0.5) and message: \"Resolved 0.5\"",
				"Returned with time (0.4) and message: \"Resolved 0.4\"",
				"Returned with time (0.3) and message: \"Resolved 0.3\"",
				"Returned with time (0.2) and message: \"Rejected 0.2\"",
				"Returned with time (0.1) and message: \"Rejected 0.1\""
			],
			await PromiseEx.rSort([
				Promise.resolve(caller.bind(0.3, "Resolved 0.3")),
				Promise.reject(caller.bind(0.2, "Rejected 0.2")),
				Promise.new(caller.bind(0.4, "Resolved 0.4")),
				Promise.reject(caller.bind(0.1, "Rejected 0.1")),
				Promise.new(caller.bind(0.5, "Resolved 0.5")),
			]).finished
		),
		"\nEnd test_rsort()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

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
	
	print_rich(
		"Start test_firstN()",
		"\nFive coroutines, n=3",
		"\nOutput: ",
		_check_answer(
			[
				"Returned with time (0.1) and message: \"Rejected 0.1\"",
				"Returned with time (0.2) and message: \"Rejected 0.2\"",
				"Returned with time (0.3) and message: \"Resolved 0.3\""
			],
			output[0]
		),
		"\nThree coroutines, n=5",
		"\nOutput: ",
		_check_answer(
			[
				"Returned with time (0.2) and message: \"Rejected 0.2\"",
				"Returned with time (0.3) and message: \"Resolved 0.3\"",
				"Returned with time (0.5) and message: \"Resolved 0.5\""
			],
			output[1]
		),
		"\nEnd test_firstN()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
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
	
	print_rich(
		"Start test_lastN()",
		"\nFive coroutines, n=3",
		"\nOutput: ",
		_check_answer(
			[
				"Returned with time (0.5) and message: \"Resolved 0.5\"",
				"Returned with time (0.4) and message: \"Resolved 0.4\"",
				"Returned with time (0.3) and message: \"Resolved 0.3\""
			],
			output[0]
		),
		"\nThree coroutines, n=5",
		"\nOutput: ",
		_check_answer(
			[
				"Returned with time (0.5) and message: \"Resolved 0.5\"",
				"Returned with time (0.3) and message: \"Resolved 0.3\"",
				"Returned with time (0.2) and message: \"Rejected 0.2\""
			],
			output[1]
		),
		"\nEnd test_lastN()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_pipe() -> void:
	var output : Array = await Promise.all([
		PromiseEx.pipe([
			_pipeline_test_2.bind(0),
			_pipeline_test_2,
			_pipeline_test_2,
			Promise.new(_pipeline_test_2, false),
			_pipeline_test_2,
			_pipeline_test_2,
		], 3),
		PromiseEx.pipe([
			_pipeline_test_2.bind(0),
			_pipeline_test_2,
			_pipeline_test_2,
			Promise.reject("FAILED"),
			_pipeline_test_2,
			_pipeline_test_2,
		], 5),
	]).finished
	
	print_rich(
		"Start test_pipe()",
		"\nAdd 1+1+1+1+1+1. Output: ",
		_check_answer(
			6,
			output[0]
		),
		"\nForce Reject. Output: ",
		_check_answer(
			"FAILED",
			output[1]
		),
		"\nEnd test_pipe()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout

func test_anyReject() -> void:
	print_rich(
		"Start test_anyReject()",
		"\nOutput: ",
		_check_answer(
			"Returned with time (0.3) and message: \"Rejected 0.3\"",
			await PromiseEx.anyReject([
				Promise.resolve(caller.bind(0.2, "Resolved 0.2")),
				Promise.reject(caller.bind(0.7, "Rejected 0.7")),
				Promise.new(caller.bind(0.4, "Resolved 0.4")),
				Promise.reject(caller.bind(0.3, "Rejected 0.3")),
				Promise.new(caller.bind(0.1, "Resolved 0.1")),
			]).finished,
		),
		"\nEnd test_anyReject()\n",
	)
	
	# Gives terminal time to print message
	await get_tree().create_timer(0.1).timeout
#endregion

# Made by Xavier Alvarez. A part of the "GodotPromise" Godot addon. @2025
