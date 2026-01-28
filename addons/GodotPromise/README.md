# GodotPromise

Hello everyone in the future!

I've noticed the current Promise types on the Godot Asset Library are lacking in a few ways, so I improved on them.

## Godot Promise Vs ECMAScript Comparison

All features of the [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) type in `Javascript` has been implemented within `Godot Promise`. However, some features are harder to translate between the two mediums than others.

This section will provide a few notable comparisons to help you understand.

### Creating Promises
#### Base Constructor

**In ECMAScript**, there is only one proper way to create a promise.

```
var promise = new Promise(resolve => resolve(obj));
```

This will create a Promise that will **resolve** to the value 'obj`. (More information on **rejecting** and **resolving** will be given in a later section.)

It is also important to note that if we removed the `obj`, such that the method `resolve` wasn't given *any* parameters, the ECMAScript Promise would return a default `undefined`.

**In Godot**, however, there are multiple ways to define a `Godot Promise`.

```
# Base 'Godot Promise' constructor
Promise.new(obj)
```

The above code will create a basic `godot Promise` that automatically **resolves** to the value `obj`, without any need for additional code.

#### Receiving Output from Promises

**In ECMAScript**, you get output from `then`, `catch`, and `finally` chain methods. Meanwhile, `Godot Promises` have a few different methods available.

`Godot Promises`, instead, return their finished value via the `finished` `Signal`. If you want to get the value of a `Godot Promise` after it is **resolved** or **rejected**, you just await like so:

```
# Gets value when 'Godot Promise' finishes.
var val = await Promise.new(obj).finished
```

You can also get the output using the `get_result` method.

```
var p := Promise.new(obj)
await p.finished
var val = p.get_result()
```

*Note*: If `get_result` is called before the `Promise` has **resolved** or **rejected**, it will return a default `null` value. You can use the method `is_finished` to check if the `Promise` is `finished`.

It is also important to note that if we removed the `obj`, such that the Promise's constructor wasn't given *any* parameters, the `finished` signal would also return a default `null.`

As can already be seen, `Godot Promise` uses `null` in place of `ECMAScript`'s `undefined`.

#### Auto Async Parameter Awaiting

One more thing to notice: this constructor works differently depending on what `obj` is. If `obj` is **NOT** either a `Signal`, `Callable`, or another `Godot Promise`, the `Godot Promise` will instantly return the raw parameter as given. Otherwise, the `Godot Promise` will automatically `await` the `Signal`, `await` and call the `Callable`, or `await` the `Godot Promise` to finish, then return the result.

For example:

```
Signal test(param : String)
val foo := func():
	await get_tree().create_timer(1.0).timeout
	return "Hello"

# Resolves to "Hello" instantly
await Promise.new("Hello").finished

# Resolves to "Hello" in one second
await Promise.new(foo).finished

# Resolves to "Hello" when test.emit("Hello") is called
await Promise.new(test).finished

# Resolves to "Hello" instantly
await Promise.new(Promise.new("Hello")).finished
```

*Note*: `Callables` and `Signal` in a `Godot Promise` -- with no return value -- will output the default `null`.

As noticed, this is largely different from **ECMAScript**'s Promises, which do not automatically resolve async parameters given to it.

```
// Creates a 'Promise' that returns an unresolved 'Promise' (that will resolve by itself in 1 second). 
const myPromise = new Promise((resolve, reject) => {
	return new Promise((resolve, reject) => {
	    setTimeout(() => {
	      // Resolve the promise with a value
	      resolve("Data retrieved successfully!");
	    }, 1000);
	  });
  });
```

To do something similar in `Godot Promise`, you may want to use the `reject_raw` or `resolve_raw` methods. These static methods will automatically construct a `Godot Promise` that either **resolves** or **rejects** to the raw value of any parameter given. As these `Godot Promises` do not resolve anything async, they will always return a value the moment they are called.

Using them, an equivalent **Godot Promise** to the above `ECMAScript` example would be.

```
# Will reject a 'Godot Promise` that resolves 'null' after 1 second. 
await Promise.reject_raw(Promise.new(get_tree().create_timer(1.0).timeout)).finished

# Will resolve a 'Godot Promise` that resolves 'null' after 1 second.
await Promise.resolve_raw(Promise.new(get_tree().create_timer(1.0).timeout)).finished
```

Of course, there are also corresponding `reject` and `resolve` methods.

```
# Will reject 'null' after 1 second.
await Promise.reject(Promise.new(get_tree().create_timer(1.0).timeout)).finished

# Will resolve 'null' after 1 second.
await Promise.resolve(Promise.new(get_tree().create_timer(1.0).timeout)).finished
```

These methods *also* automatically `await` for `async` parameters to finish, similar to the base `Promise.new()` constructor. However, `Promise.new()` will always **resolve** 'obj`, while `reject` will **reject** `obj`.

The ``resolve`` is added only for consistency.

#### Stall Execution

In **Godot Promise**, you can also place an additional `boolean` parameter to defer a `Godot Promise`, stalling it from running. For example:

```
# Parameter version of basic 'Godot Promise' constructor 
Promise.new(async : Variant, executeOnStart)
```

If `executeOnStart` is `false`, then the `Godot Promise` will not run the moment it is constructed. To make it run later, you must use the `execute` method. For example:

```
# Will not execute or await anything async on construction.
var val = Promise.new(obj, false)

# Starts execution and awaits.
val.execute()
```

This is much simpler than the **ECMAScript** equivalent.

```
function createDeferredPromise() {
  let resolveExternal;
  let rejectExternal;

  const promise = new Promise((resolve, reject) => {
	// Store the internal resolve/reject functions in external variables
	resolveExternal = resolve;
	rejectExternal = reject;
  });

  return {
	promise: promise,
	resolve: (value) => {
	  if (resolveExternal) {
		resolveExternal(value);
	  }
	}
  };
}

const { promise, resolve } = createDeferredPromise();

promise.then((result) => {
  console.log("Promise resolved with:", result);
}).catch((error) => {
  console.error("Promise rejected with:", error);
});

// Allows Promise to execute.
resolve("Success value!");
```

Of course, all previous **Godot Promise** methods also have a corresponding `executeOnStart` parameter too.

```
# Won't resolve or reject when constructed
var p1 := Promise.reject_raw(obj, false)
var p2 := Promise.resolve_raw(obj, false)
var p3 := Promise.reject(obj, false)
var p4 := Promise.resolve(obj, false)

# Will now start resolving and rejecting
p4.execute()
p3.execute()
p2.execute()
p1.execute()
```

#### Reset Execution

After execution, you can even reset a `Godot Promise` to be reused. For example:

```
Signal test

# Executes on construction. Waits until `test` is emitted.
var val = Promise.new(test)

# Awaits until the Promise is finished
await val.finished

# Resets the Promise. Waits for `test` to be emitted again.
val.reset()
val.execute()

# Waits until `test` is emitted.
await val.finished
```

*Note*: for `Godot Promise` chains (referred to later), make sure to use `reset_chain` instead to reset every `Godot Promise`, including and before the current `Godot Promise`.

#### Callbacks and Resolvers

Lastly, you might have noticed that the above 'Godot Promise' constructors only either **resolve** or **reject** statically, with no ability to change during runtime based on the parameters. This is very lacking compared to **ECMAScript**. For example:

```
// Resolves or rejects if the `resolve` or `reject` lambdas are called inside the `Promise`.
new Promise((resolve, reject) => {
   if (ok) resolve()
   else reject()
})

// Resolves or rejects if the `resolve` or `reject` lambdas are called outside the 'Promise'.
const { promise, resolve, reject } = Promise.withResolvers()

// Resolves or rejects if the `resolveCallback` or `rejectCallback` lambdas are called inside or outside the `Promise`.
let resolveCallback, rejectCallback;
const promise = new Promise((resolve, reject) => {
	resolveCallback = resolve;
	rejectCallback = reject;
	
	if (ok) resolve()
	else reject()
});
```

To emulate this, use the **Godot Promise** equivalents `withCallback`, `withResolvers`, or `withCallbackResolvers`.

```
# Resolves or rejects if the `resolve` or `reject` lambdas are called inside the `Promise`.
var promise := Promise.withCallback(func (resolve, reject):
	# Since we cannot invoke a callable like a normal function, we need to use `.call()` manually.
	if ok: resolve.call()
	else: reject.call()
)

# Resolves or rejects if the `resolve` or `reject` lambdas are called outside the 'Promise'.
var resolvers := Promise.withResolvers()
# Since we cannot deconstruct a dictionary in GDScript, this function returns a Dictionary of everything relevant.
var promise: Promise = resolvers["promise"]
var resolve: Callable = resolvers["resolve"]
var reject: Callable = resolvers["reject"]

# Resolves or rejects if the `resolve` or `reject` lambdas are called inside or outside the `Promise`.
var resolvers := Promise.withCallbackResolvers(func (resolve, reject):
	# Since we cannot invoke a callable like a normal function, we need to use `.call()` manually.
	if ok: resolve.call()
	else: reject.call()
)
# Since we cannot deconstruct a dictionary in GDScript, this function returns a Dictionary of everything relevant.
var promise: Promise = resolvers["promise"]
var resolve: Callable = resolvers["resolve"]
var reject: Callable = resolvers["reject"]
```

Since "this" is not a built-in keyword in GDScript, a common pattern you may find using (when you need dynamic resolvers) is:

```
# Private Class Callback Callable
func _executor(resolve: Callable, reject: Callable):
   pass

# Public method to create Callback Promise
func do_some_thing() -> Promise:
   return Promise.withCallback(_executor)
```

And for consistency, these methods also also have a corresponding `executeOnStart` parameter.

```
# Private Class Callback Callable
func _executor(resolve: Callable, reject: Callable):
   pass

# Won't resolve or reject when constructed
var p1 := Promise.withCallback(_executor, false)
var p2 := Promise.withResolvers(false)
var p3 := Promise.withCallbackResolvers(_executor, false)

# Will now start resolving and rejecting
p3.execute()
p2.execute()
p1.execute()
```

#### Other Static Methods

For simplicity, we also have a few other basic constructors for your needs.

Here are some methods in **ECMAScript**:

```
const p1 = new Promise()
const p2 = new Promise()
const p3 = new Promise()

// If all are resolved
await Promise.all([p1, p2, p3])

// If all are either resolved or rejected
await Promise.allSettled([p1, p2, p3])

// Outputs the first one to resolve or reject
await Promise.race([p1, p2, p3])

// Outputs the first one to resolve, or returns an array of rejections if they all reject
await Promise.any([p1, p2, p3])
```

And here are their `Godot Promise` equivalents.

```
var p1 := Promise.new()
var p2 := Promise.new()
var p3 := Promise.new()

# If all are resolved
await Promise.all([p1, p2, p3]).finished

# If all are either resolved or rejected
await Promise.allSettled([p1, p2, p3]).finished

# Outputs the first one to resolve or reject
await Promise.race([p1, p2, p3]).finished

# Outputs the first one to resolve, or returns an array of rejections if they all reject
await Promise.any([p1, p2, p3]).finished
```

Pretty similar, right?

#### Try Constructor

*Note*: `Godot` already continues after errors, unless you purposefully use an `assert`. Therefore, the `try, catch` dynamic is implied by default.

### Promise Chains

#### Then and Catch Basics

`Promise Chains` are defined as the situation where `Promises` are delayed execution and only triggered when the previous `Promise` (within the chain) is triggered.

**In ECMAScript**, this is trivial with its `then`, `catch`, and `finally` methods. For example:

```
const promise = new Promise(resolve => resolve());

// Will print to console 1, 2, and then 3
promise
  .then(() => console.log(1))
  .then(() => console.log(2))
  .finally(() => console.log(3));
```

```
const promise = new Promise((_, reject) => reject());

// Will print to console 1 and then 3
promise
  .catch(() => console.log(1))
  .catch(() => console.log(2))
  .finally(() => console.log(3));
```

Similarly, you have access to `then`, `catch`, and `finally` methods **In Godot Promise** as well.

```
# Will print to log 1, 2, and then 3
Promise.resolve().then(print.bind(1)).then(print.bind(2)).finally(print.bind(3))
```

```
# Will print to log 1 and then 3
Promise.reject().catch(print.bind(1)).catch(print.bind(2)).finally(print.bind(3))
```

#### Then and Catch Parameters

Notice that the `Promise Chain` for both `ECMAScript` and `Godot Promise` stops at the first `catch` statement, but runs for every then statement.

You can change this in `Godot Promise` via its arguments.

```
# Parameter version of 'Godot Promise''s `then` and `catch` methods.
Promise.new().then(async = null, pipe_prev : bool = false, is_stopgate : bool = false)
Promise.new().catch(async = null, pipe_prev : bool = false, is_stopgate : bool = true)
 ```

This is where `Godot Promise` provides more customizability than `ECMAScript`.

*Note*:
	1.) The `Godot Promise` output (in a chain) will be binded (as an Callable parameter) to the next `then` or `catch` `Godot Promise` in the chain (if it's a Callable) *ONLY IF* `pipe_prev` is `true`.
	2.) The previous `Godot Promise` output will cancel all following `Godot Promise`s in the chain *ONLY IF* `is_stopgate` is `true` and an unexpected status is found in the previous `Godot Promise` of the chain.

With these parameters, you can flip the purpose of `then` and `catch` whenever needed.

```
# Will print to log 1 and then 3
Promise.resolve().then(print.bind(1), false, true).then(print.bind(2), false, true).finally(print.bind(3))

## Notice that finally still runs.
```

```
# Will print to log 1, 2, and then 3
Promise.reject().catch(print.bind(1), false, false).catch(print.bind(2), false, false).finally(print.bind(3))

## Notice that finally still runs.
```

...or, you can prevent the result of some `Promises` from messing up other `Callables`.

```
var c1 := func(): return
var c2 := func(obj = true): print(obj)

# Will print to log 'null'
Promise.new().then(c1, false).then(c2, true)
# Will print to log 'true'
Promise.new().then(c1, false).then(c2, false)
```

*Note*: Although piping from `Promise` to `Promise` is a standard feature in **ECMAScript**, attempting to bind arguments to a `Callable` that does ask for parameters in `Godot` causes an error. Thus, to avoid common errors, `pipe_prev` is defaulted to `false`. Use it only when you need to.

#### Split Chains

Keep in mind you can also split `Promises`.

In **ECMAScript**...

```
const promise = new Promise((resolve) => resolve());

// Outputs both 1 and 2 to the console immediately after `promise` finishes execution.
promise.then(() => {
  console.log(1);
});
promise.then(() => {
  console.log(2);
});
```

...and in **Godot Promise**.

```
var promise := Promise.new()

# Outputs both 1 and 2 to the log immediately after `promise` finishes execution.
promise.then(print.bind(1))
promise.then(print.bind(2))
```

#### Other Chain Information

For chains to function in `Godot`, each `Godot Promise` is given a current `status`. You can use the method `peek` to get the status of a `Promise`.

The possible `statuses` a `Promise` can have are shown in the documentation:

```
enum PromiseStatus {
	Initialized = 0, ## The promise hasn't yet been executed
	Pending = 1, ## The promise has been executed, but not finished
	Accepted = 2, ## The promise is finished and accepted
	Rejected = 3, ## The promise is finished, but rejected
	Canceled = 4  ## The promise's execution is skipped/canceled
}
```

You may also use `get_prev` to get the previous `Godot Promise` in the `Godot Promise` chain.

Also, to reset a `Godot Promise chain`, you use `reset_chain` instead of `reset`.

```
var p1 := Promise.new().then().then().then()
var p2 := Promise.new().then().then().then()

p1.reset() # Only resets the head (the last 'then()')
p1.reset_chain() # Resets all promises before and including the head (the entire chain)
```

### Common mistakes

*Note*: that Promise is a complex object, so it's easy to misuse.

### reset_chain()

After attempting to `reset_chain`, you may want to execute the `method` again, like so:

```
var p := Promise.new().then().then().catch().then()
await p.finished
p.reset_chain()
p.execute()
```

However, `p` is a variable that only stores the tail of the `Godot Promise chain`. Thus, doing `p.execute()` will only execute the last `then()`. In order to execute the `Godot Promise Chain` again, then...

```
var p := Promise.new().then().then().catch().then()
await p.finished
p.reset_chain(true) # Auto executes
```

...or...

```
var head := Promise.new()
var tail := head.then().then().catch().then()
await p.finished
p.reset_chain()
head.execute()
```

...or...

```
var p := Promise.new().then().then().catch().then()
await p.finished

p.reset_chain()
while p.get_prev() != null:
	p = p.get_prev()
p.execute()
```

### ReferenceCounter
#### Basic

When using `Godot Promise`, you might want to return the `finished` output of the `Signal`. To do that, you might try something like...

```
func _test() -> Signal:
	return Promise.new().finished

func other_test() -> void:
	await _test()
```

However, this will cause an error.

`Promise` is a `RefCounter` object. This means that, in a situation where the reference to a `Godot Promise` is no longer stored anywhere, the `Godot Promise` will automatically clear itself, which will clear the `Signal` too. Hence, the `error` when attempting to use the `signal`.


To fix this, you must store the Promise somehow...

```
var p : Promise

func _test() -> Signal:
	p = Promise.new().finished
	return p

func other_test() -> void:
	await _test()
```

...or return the Promise itself...

```
func _test() -> Promise:
	return Promise.new()

func other_test() -> void:
	await _test().finished
```

This may appear ugly, but it's something needed.

#### Promise Chains

*Note* that `Godot Promises` can store a reference to the previous `Godot Promise` in a `Godot Promise Chain`, but they do not store a reference to the next `Godot Promise` in a chain.

For example:
```
func _test_1() -> Promise:
	var p := Promise.new(1)
	p.then(2)
	return p

func _test_2() -> Promise:
	return Promise.new(1).then(2)

func other_test-1() -> void:
	// Outputs 1
	await _test_1().finished

func other_test_2() -> void:
	// Outputs 2
	await _test_2().finished
```

### Promises And Timers

Look at the code below...

```
func test() -> void:
	p = Promise.new()
	for n in 10:
		p.then(get_tree().create_timer(0.1).timeout)
	await p.finished
```

At first glance, it appears that this function will await for exactly `0.1 * 10` seconds. However, no. It waits for exactly 0.1 seconds.

This is because you are creating all `get_tree().create_timer(0.1)` in the same frame. These timers will all finish `0.1` seconds later, regardless of what happens, and the `Godot Promises` respect that.

Instead, you need to create and await the timers on demand. For example...

```
func test_helper() -> void:
	await get_tree().create_timer(0.1).timeout

func test() -> void:
	p = Promise.new()
	for n in 10:
		p.then(test_helper)
	await p.finished
```

This will work and await for exactly `0.1 * 10` seconds, as the timers are being created and awaited on demand.

### Promises Ouputing Callables

It's easy to confuse Callables with return values.

Notice the difference between...

```
Promise.new().then(get_tree().create_timer(1).timeout).new(print("Hello"))
```

...and...

```
Promise.new().then(get_tree().create_timer(1).timeout).then(print.bind("Hello"))
```

The first one will print `"Hello"` instantly, and then have an ouput of `null` after 1 second.
The second one will print `"Hello"` and have an ouput `null` after 1 second.

It's an easy mistake to make, and it can be a pain to debug.

## Modularability

*Note*: This framework is developed via modular blocks, which YOU may also edit.

For example, the `all` coroutine is built on the inner class `AllCoroutine`, which is an extension of the inner class `ArrayCoroutine`, which is an extension of the inner class `MultiCoroutine`, which is an extension of the inner class `AbstractLogic`.

All methods to handel `Godot Promise` logic is built on `AbstractLogic`. By iteratively making new inner class extentions to `AbstractLogic`, you can create building blocks to create new ways of handeling `Godot Promise`s.

To see the full extend how, it's best to look at the code comments to do so. Examples of how to create custom logic are given via the **PromiseEx** object class, also included within this addon.

The **PromiseEx** has `Promise` methods that load resources, an `all` that sorts signals from first to finish to last, a reverse `any`, and more. Check it out. 

## Documentation

For more information, the documentation includes a full list of functions and utility. A few more niche methods, not discussed here, are fully explained in there.

Enjoy.

## Known Issues

None

## Profile
If you like what I do, check out my [other stuff](https://ko-fi.com/soulstogether). Maybe buy me a coffee, if you want.
