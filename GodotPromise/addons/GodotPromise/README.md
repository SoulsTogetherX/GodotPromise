# SUMMARY

Hello everyone in the future!

I've noticed the current Promise types on the Godot Asset Library to be lacking in a few ways, so I improved them.

I replicated ***ALL*** functions related to the [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) type in Javascript (except try(), but that's becuase it's behavior is implied by default).

Promises can be accepted or rejected. then(), catch(), and finally() functions work as expected with this.

This type works for Signals, Callables, other Promises, and ***EVERY*** other type.

The function to_string() converts the Promise into the format "Promise<Type>".

It is possible and *recommended* to chain Promises.

It is fully documented and the code is efficient and compact to help with easy understanding.

I made it easy to create custom Promise functionality with the use of modular Inner Classes.

Can be mindlessly plugged in to synchronize coroutines, or be easily extended to allow ***anything*** else you may need by extending from the Inner Classes at the bottom of the document.

# CODE EXAMPLES

To use, simply create a Promise type as such:
```
await Promise.new(val).finished
```

You may also nest Promises.
```
await Promise.new(Promise.new(val)).finished
```

You can delay the execution of promises and activate them on command.
```
var p := Promise.new(Promise.new(val), false)
p.execute()
await p.finished
```
[b]NOTE[/b]: Nesting a Promise does not automatically activate it. You may still manually control the nested Promise.

You may also use one of the premade static options already available. A few examples:
```
await Promise.any([val1, val2, val3, val4]).finished
await Promise.race([val1, val2, val3, val4]).finished
await Promise.allSettled([val1, val2, val3, val4]).finished
await Promise.all([val1, val2, val3, val4]).finished
```

You may directly cause a rejection or a resolution.
```
await Promise.reject(val).finished
await Promise.reject_raw(val).finished
await Promise.resolve(val).finished
await Promise.resolve_raw(val).finished
```

You may also chain Promises.
```
print(
	await Promise.any([val1, val2, val3, val4]).then(
		"At least one coroutine was resolved"
	).then(
		"A coroutine was accepted! :O"
	).catch(
		"All coroutines were rejected! O:"
	).finally(
		"I always run!!! :D"
	).finished
)
```

You may also pipeline the result of Promises.
```
func _pipe_test_funcs(arg : int) -> int:
	return arg * 2

print(
	Promise.new(1).then(_pipe_test_funcs, true).then(_pipe_test_funcs, true).then(_pipe_test_funcs, true)
) <- Returns 8
```

## Common mistakes

Note that Promise is a complex object, so it's easy to misuse.

You'd expect the below code to work, for instance...
```
func test() -> Signal:
	return Promise.new().finished
```
...but this actually causes an error.

Promise is a RefCounter object. This means that, in a siduation where reference to the Promise is no longer stored anywhere, the Promise will automatically clear itself. Reference to it's finished signal does not count.

To fix this, you must store the Promise somehow...
```
var p : Promise
func test() -> Signal:
	p = Promise.new()
	return p.finished
```
...or return the Promise itself...
```
func test() -> Promise:
	return Promise.new()
```

It is also to fix up how to delay Promises.

Look at the below code...
```
func test() -> void:
	p = Promise.new()
	for n in 10:
		p.then(get_tree().create_timer(0.1).timeout)
	await p.finished
```
At first glace, it appears that this function will await for exactly '0.1 * 10' seconds. However, no. It waits for exactly 0.1 seconds.

This is because you are creating all 'get_tree().create_timer(0.1)' in the same frame. These timers will all finish `0.1` seconds later, regardless of what happens, and the Promises respect that.

Instead, you need to create and await the timers on the fly. For example...
```
func _test_helper() -> void:
	await get_tree().create_timer(0.1).timeout
func test() -> void:
	p = Promise.new()
	for n in 10:
		p.then(_test_helper)
	await p.finished
```
This will work and await for exactly `0.1 * 10` seconds, as the timers are being created and awaited on demand.

It's also easy to confuse Callables with Return values.

In 'Promise.new(print("Hello"))`, we are promising the return value of `print`, which is interpreted as `null`.

Meanwhile, in 'Promise.new(print.bind("Hello"))`, we are promising the Callable `print`, which will be callabled when the Promise needs it to be called.

For more information, the documention includes a full list of functions and utlity. And, as stated, the MAIN purpose of this framework is to allow user customizability. No matter your requirement, it will be easy to code a custom Promise protocol to handle it when using this framework.

Enjoy.
