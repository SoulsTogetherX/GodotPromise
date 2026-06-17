<p align="center">
  
</p>

<p align="center">
  <a href="https://godotengine.org/download/windows/">
	  <img alt="Static Badge" src="https://img.shields.io/badge/Godot-4.5%2B-blue">
  </a>
  <a href="./LICENSE"> 
	<img alt="Static Badge" src="https://img.shields.io/badge/license-Apache%202.0-green">
  </a>
</p>

# GodotPromise

GodotPromise is a Godot 4.5+ addon created to improve how people use async Callables and Signals. It primarily uses the javascript [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) type as inspiration.

Look here for knowledge on [Use Promises](#creating-promises), [Promise Chains](#promise-chains), and [Common Mistakes](#common-mistakes).

## Quick Reference

Here is a quick reference of the tools provided for this addon.

### Construction Methods

These methods are used to construct useable Promises.

| Name                  | Arguments                                    | Use                                                                                   | Result                                                                                                | Reject                         | Resolve                                                 |
| --------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------- |
| new()                 | Any                                          | The basic constructor for Promises                                                    | Returns the same result as 'await' would                                                              | Never                          | Always                                                  |
| all()                 | An array of Promises                         | Awaits for all Promises to finish                                                     | Returns an array of values, from the Promises, once they all resolve                                  | If any Promise rejects         | If all Promises resolve                                 |
| allSettled()          | An array of Promises                         | Provides the state of all Promises after finishing                                    | Returns an array of integer values representing the rejected or resolved states of all given Promises | Never                          | Always                                                  |
| race()                | An array of Promises                         | Finishes when the first of the provided Promises finish                               | Returns the result of the first finished Promise                                                      | If the first Promise rejects   | If the first Promise resolves                           |
| any()                 | An array of Promises                         | Finishes when the first, of the provided Promises, resolve. Or if they all reject     | Returns the result of the first resolved Promise, or an array of all Promises if none resolved        | If all Promises are rejected   | If at least one Promise is resolved                     |
| reject()              | Any                                          | Always rejects                                                                        | Same as new(), but always rejects                                                                     | Always                         | Never                                                   |
| resolve()             | Any                                          | Always Resolves                                                                       | Same as new()                                                                                         | Never                          | Always                                                  |
| reject_raw()          | Any                                          | Always rejects without awaiting                                                       | Rejects any give argument, without awaiting                                                           | Always                         | Never                                                   |
| resolve_raw()         | Any                                          | Always resolves without awaiting                                                      | Resolves any give argument, without awaiting                                                          | Never                          | Always                                                  |
| withCallback()        | A Callable that takes two Callable arguments | Allows users to manipulate the resolve or rejection of a Promise via provided methods | A Promise that can be resolved or rejected by the provided Callable Arguments                         | If the Reject Method is called | If the Resolve Method is called or the Promise finishes |
| withResolvers()       | Any                                          | Allows users to manipulate the resolve or rejection of a Promise via provided methods | Returns a dictionary with methods to resolve or reject the Promise.                                   | If the Reject Method is called | If the Resolve Method is called or the Promise finishes |
| withCallbackResolvers | A Callable that takes two Callable arguments | Allows users to manipulate the resolve or rejection of a Promise via provided methods | withCallback() and withResolvers() combined                                                           |                                |

The below are methods located only in the `PromiseEx` class.

| Name        | Arguments                                   | Use                                                                                            | Result                                                                         | Reject                                                                 | Resolve                                                                     |
| ----------- | ------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| interfere() | Any two arguments                           | Rejects or resolves the first argument depending on the speed of the second argument           | Same as awaiting the first argument                                            | If the second argument is returned before the first, reject the first. | If the second argument is not finished before the first, resolve the first. |
| hold()      | Any two arguments                           | Holds until the second argument is finished                                                    | Same as awaiting the first argument, but delayed by the second                 | If the first argument rejects                                          | If the first arguments resolve                                              |
| resource()  | An updater signal and a resource path       | Used to load a resource via a background thread                                                | Returns a resource or null, depending on if the resource could be loaded       | If the resource could not be loaded                                    | If the resource was loaded successfully                                     |
| sort()      | An array of Promises                        | Processes Promises in the order they finished                                                  | Returns the result of the Promises in the order they were finished in          | Never                                                                  | Always                                                                      |
| rsort()     | An array of Promises                        | Processes Promises in the reversed order they finished                                         | Returns the result of the Promises in the reversed order they were finished in | Never                                                                  | Always                                                                      |
| firstN()    | An array of Promises and a positive integer | Processes the first N Promises in the order they finished                                      | Returns the first N results of the Promises in the order they were finished in | Never                                                                  | Always                                                                      |
| lastN()     | An array of Promises and a positive integer | Processes the last N Promises in the order they finished                                       | Returns the last N results of the Promises in the order they were finished in  | Never                                                                  | Always                                                                      |
| pipe()      | An array of Promises or Callables           | Binds the previous Promise's result as an argument to the next for all given arguments         | Returns the result of chaining all given async values together                 | If any given Promises values reject                                    | If all given Promises resolve                                               |
| anyReject() | An array of Promises                        | Returns the result of the first rejected Promise, or an array of all Promises if none rejected | If at least one Promises is rejected                                           | If all Promises are resolved                                           |

Keep in mind that the extra functionality of these methods are ignored in the above table for simplicity. Read the Godot annotations for a full overview.

### Chain Methods

These methods are used to chain useable Promises together.

| Name      | Arguments | Use                                                        | Result                                                                                          | Reject                                    | Resolve                                         |
| --------- | --------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------- | ----------------------------------------------- |
| then()    | any       | Awaits the given argument if the previous Promise resolves | If the previous Promise resolves, returns the same as await. Otherwise, return previous Promise | If this and the previous Promise resolves | If either this or the previous Promise rejects  |
| catch()   | any       | Awaits the given argument if the previous Promise rejects  | If the previous Promise resolves, returns the same as await. Otherwise, return previous Promise | If this and the previous Promise rejects  | If either this or the previous Promise resolves |
| finally() | any       | Awaits the given argument                                  | Returns the same as await.                                                                      | If the previous Promise rejects           | If the previous Promise resolves                |

Keep in mind that the extra functionality of these methods are ignored in the above table for simplicity. Read the Godot annotations for a full overview.

### Helper Methods

| Name               | Use                                                                                            |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| execute            | Starts a paused Promise's execution                                                            |
| reset              | Resets a Promise to be executed again                                                          |
| reset_chain        | Resets a Promise, and all prior Promises (in the Promise chain), to be executed again          |
| is_finished        | Returns if a Promise has finished                                                              |
| peek               | Returns the current status of a Promise: Initialized, Pending, Accepted, Rejected, or Canceled |
| get_prev           | Returns the prior Promises (in the Promise chain)                                              |
| get_promise_object | Returns the async object the Promise is awaiting for                                           |
| get_result         | Returns the result of awaiting, or null if the Promise hasn't finished                         |

Keep in mind that the extra functionality of these methods are ignored in the above table for simplicity. Read the Godot annotations for a full overview.

### Logic Classes

Logic Classes are this addon's method in implementing and extending Promise Logic

| Name                         | Use                                                                                              | Extends From   | Used in                                                                      |
| ---------------------------- | ------------------------------------------------------------------------------------------------ | -------------- | ---------------------------------------------------------------------------- |
| AbstractLogic                | The base logic for all Promises                                                                  | RefCounted     | All                                                                          |
| DirectCoroutineLogic         | A logic class that handles both resolve and rejected cases of a direct Promise                   | AbstractLogic  | new(), withCallback(), withResolvers(), withCallbackResolvers()              |
| OverrideStatusCoroutineLogic | A logic class for overwriting a Promises return state                                            | AbstractLogic  | reject(), reject_raw(), resolve(), resolve_raw(), then(), catch(), finally() |
| OnSignalCoroutine            | A logic class used to update a Promise via an external signal                                    | AbstractLogic  | --                                                                           |
| MultiCoroutine               | A logic class used to handle an array of async types                                             | AbstractLogic  | --                                                                           |
| RaceCoroutine                | A logic class that returns the first result to finish awaiting                                   | MultiCoroutine | race()                                                                       |
| ArrayCoroutine               | A logic class that handles an array of async types, and return an array of values                | MultiCoroutine | --                                                                           |
| AllCoroutine                 | A logic class that resolves an array of async types                                              | ArrayCoroutine | all()                                                                        |
| AllSettledCoroutine          | A logic class that resolves a status array of finished Promises                                  | ArrayCoroutine | allSettled()                                                                 |
| AnyCoroutine                 | A logic class that resolves the first resolved Promise, or rejects an array of rejected Promises | ArrayCoroutine | any()                                                                        |

The below are logic classes located only in the `PromiseEx` class.

| Name               | Use                                                                                                                  | Extends From         | Used in     |
| ------------------ | -------------------------------------------------------------------------------------------------------------------- | -------------------- | ----------- |
| InterfereCoroutine | A logic class that takes two arguments, and rejects or resolves the first depending on the order the Promises finish | DirectCoroutineLogic | interfere() |
| HoldCoroutine      | A logic class that takes two arguments, and doesn't finish the first until the second one is finished                | DirectCoroutineLogic | hold()      |
| ResourceCoroutine  | A logic class that loads a resource in the background                                                                | OnSignalCoroutine    | resource()  |
| SortCoroutine      | A logic class that resolves an array of all Promises results in the order they were resolved in                      | AllCoroutine         | sort()      |
| RSortCoroutine     | A logic class that resolves an array of all Promises results in the reverse order they were resolved in              | AllCoroutine         | rsort()     |
| FirstNCoroutine    | A logic class that resolves an array of the first N Promises results in the order they were resolved in              | SortCoroutine        | firstN()    |
| LastNCoroutine     | A logic class that resolves an array of the last N Promises results in the order they were resolved in               | RSortCoroutine       | lastN()     |
| PipeCoroutine      | A logic class to pipe the result of an array of Promises into each other for a final result                          | MultiCoroutine       | pipe()      |
| AnyRejectCoroutine | A logic class used to either return the first rejected result, or an array of all resolved Promises                  | ArrayCoroutine       | anyReject() |

Feel free to extend or create your own logic classes to create custom Promise routines.

## How To Use

Godot Promise can be a complicated object to use. Here is a basic explanation to help.

### Base Constructor

In `ECMAScript`, there is only one proper way to construct a promise.

```
var promise = new Promise(resolve => resolve(obj));
```

This will create a `Promise` that will **resolve** to the value `obj`. (More information on **rejecting** and **resolving** will be given in a later section.)

It is also important to note that if we removed the `obj`, such that the method `resolve` wasn't given _any_ parameters, the ECMAScript Promise would return a default `undefined`.

In **Godot**, however, there are multiple ways to construct a `Godot Promise`.

```
# Base 'Godot Promise' constructor
Promise.new(obj)
```

The above code will create a basic `Godot Promise` that automatically **resolves** to the value `obj`, without any need for additional code.

### Receiving Output from Promises

In `ECMAScript`, you can get a ` Godot Promise`'s output via the available `then`, `catch`, and `finally` chain methods. On the other hand, `Godot Promises` has a few different ways to get the output.

Firstly, `Godot Promises` automatically return their finished value via the `finished` Signal. If you want to get the value of a `Godot Promise` after it is **resolved** or **rejected**, you just `await` like so:

```
# Gets value when 'Godot Promise' finishes.
var val = await Promise.new(obj).finished
```

You can also get the output using the `get_result()` method.

```
var p := Promise.new(obj)
await p.finished
var val = p.get_result()
```

_Note_: If `get_result()` is called before the `Godot Promise` has **resolved** or **rejected**, it will return a default `null` value. You can use the method `is_finished()` to check if a `Promise` is `finished`.

_Technical Info_: All output processing of a `Godot Promise` happens in the defer section of the frame.

It is also important to note that if we removed the `obj`, such that the Promise's constructor wasn't given _any_ parameters, the `finished` signal would also return a default `null.`

As can already be seen, `Godot Promise` uses `null` in place of `ECMAScript`'s `undefined`.

### Auto Async Parameter Awaiting

_One more thing to notice_: this constructor works differently depending on what it’s given constructor argument is.

If `obj` is **NOT** a Signal, Callable, or another `Godot Promise`, the `Godot Promise` will not defer the result and immediately return the raw parameter as given.
Otherwise, the `Godot Promise` will automatically `await` for the Signal, Callable, or `Godot Promise` to finish before then returning the result.

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

_Note_: Callable and Signal types -- with no return value -- will output the default `null` after processing in a `Godot Promise`

As noticed, this is largely different from `ECMAScript`'s Promises, which do not automatically resolve async parameters given to it.

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

To do something similar in `Godot Promise`, you may want to use the `reject_raw()` or `resolve_raw()` methods. These static methods will automatically construct a `Godot Promise` that either **resolves** or **rejects** to the raw value of any parameter given. As these `Godot Promises` do not resolve anything `async`, they will always return a value the moment they are _executed_ (without deferring).

When using them, a `Godot Promise` equivalent to the above `ECMAScript` example would be:

```
# Will reject a 'Godot Promise` that resolves 'null' after 1 second.
await Promise.reject_raw(Promise.new(get_tree().create_timer(1.0).timeout)).finished

# Will resolve a 'Godot Promise` that resolves 'null' after 1 second.
await Promise.resolve_raw(Promise.new(get_tree().create_timer(1.0).timeout)).finished
```

Of course, there are also corresponding `reject()` and `resolve()` methods as well.

```
# Will reject 'null' after 1 second.
await Promise.reject(Promise.new(get_tree().create_timer(1.0).timeout)).finished

# Will resolve 'null' after 1 second.
await Promise.resolve(Promise.new(get_tree().create_timer(1.0).timeout)).finished
```

These methods _also_ automatically `await` for async parameters to finish, similar to the base `Promise.new()` constructor. However, `Promise.new()` will always **resolve** `obj`, while `reject()` will always **reject** `obj`.

`resolve()` is functionally identical to `Promise.new()` and was only added for consistency.

### Stall Execution

In `Godot Promise`, you can also use an additional `boolean` parameter to defer a `Godot Promise`, stalling it from executing. For example:

```
# Parameter version of basic 'Godot Promise' constructor
Promise.new(async : Variant, executeOnStart)
```

_Note_: If `executeOnStart` is `false`, then the `Godot Promise` will not run the moment it is constructed. To make it run after stalling, you must use the `execute()` method. For example:

```
# Will not execute or await anything async on construction.
var val = Promise.new(obj, false)

# Starts execution and awaits.
val.execute()
```

This is much simpler than the `ECMAScript` equivalent.

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

Of course, all previous `Godot Promise` methods also have a corresponding `executeOnStart` parameter too.

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

### Reset Execution

After execution, you can also reset a `Godot Promise` to be reused. For example:

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

_Note_: for `Godot Promise` chains (referred to later), make sure to use `reset_chain` instead.

### Callbacks and Resolvers

Lastly, you might have noticed that the above `Godot Promise` constructors only either **resolve** or **reject**, with no ability to change (after the Promise started) from runtime factors. This is very lacking compared to `ECMAScript`. For example:

```
// Resolves or rejects if the `resolve` or `reject` lambdas are called inside the `Promise`.
new Promise((resolve, reject) => {
   // Depends on the variable 'ok'
   if (ok) resolve()
   else reject()
})

// Resolves or rejects if the `resolve` or `reject` lambdas are called outside the 'Promise'.
const { promise, resolve, reject } = Promise.withResolvers()
// Depends on the variable 'ok'
if (ok) resolve()
else reject()

// Resolves or rejects if the `resolveCallback` or `rejectCallback` lambdas are called inside or outside the `Promise`.
let resolveCallback, rejectCallback;
const promise = new Promise((resolve, reject) => {
    resolveCallback = resolve;
    rejectCallback = reject;

    // Depends on the variable 'ok'
    if (ok) resolve()
    else reject()
});

// Depends on the variable 'ok'
if (ok) resolveCallback()
else rejectCallback()
```

To emulate this, use the `Godot Promise` equivalents `withCallback`, `withResolvers`, or `withCallbackResolvers`.

```
# Resolves or rejects if the `resolve` or `reject` lambdas are called inside the `Promise`.
var promise := Promise.withCallback(func (resolve, reject):
    # Since we cannot invoke a callable like a normal function, we need to use `.call()` manually.

    # Depends on the variable 'ok'
    if ok: resolve.call()
    else: reject.call()
)

# Resolves or rejects if the `resolve` or `reject` lambdas are called outside the 'Promise'.
var resolvers := Promise.withResolvers()
# Since we cannot deconstruct a dictionary in GDScript, this function returns a Dictionary of everything relevant.
var promise: Promise = resolvers["promise"]
var resolve: Callable = resolvers["resolve"]
var reject: Callable = resolvers["reject"]

# Depends on the variable 'ok'
if ok: resolve.call()
else: reject.call()

# Resolves or rejects if the `resolve` or `reject` lambdas are called inside or outside the `Promise`.
var resolvers := Promise.withCallbackResolvers(func (resolve, reject):
    # Since we cannot invoke a callable like a normal function, we need to use `.call()` manually.
    # Depends on the variable 'ok'
    if ok: resolve.call()
    else: reject.call()
)
# Since we cannot deconstruct a dictionary in GDScript, this function returns a Dictionary of everything relevant.
var promise: Promise = resolvers["promise"]
var resolve: Callable = resolvers["resolve"]
var reject: Callable = resolvers["reject"]

# Depends on the variable 'ok'
if ok: resolve.call()
else: reject.call()
```

Since "this" is not a built-in keyword in GDScript, a common pattern you may use (when you need dynamic resolvers/rejectors) is:

```
# Private Class Callback Callable
func _executor(resolve: Callable, reject: Callable):
   pass

# Public method to create Callback Promise
func do_some_thing() -> Promise:
   return Promise.withCallback(_executor)
```

And for consistency, these methods also have a corresponding `executeOnStart` parameter.

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

### Other Static Methods

For simplicity, we also have a few other basic built-in constructors for your needs.

Here are some methods in `ECMAScript`:

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

### Try Constructor

_Note_: Unless you purposefully use an assert, `Godot` already continues after errors. Therefore, the `try-catch` cannot be implemented exactly according to `ECMAScript` standards.

Instead, it is recommended to code your own error handling instead of relying on exceptions.

## Promise Chains

### Then and Catch Basics

`Promise Chains` are defined as the situation where `Promises` are delayed execution and only trigger when the previous `Promise` (within the chain) is finished.

In `ECMAScript`, this is trivial with its `then`, `catch`, and `finally` methods. For example:

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

Similarly, you have access to `then`, `catch`, and `finally` methods in `Godot Promise` as well.

```
# Will print to log 1, 2, and then 3
Promise.resolve().then(print.bind(1)).then(print.bind(2)).finally(print.bind(3))
```

```
# Will print to log 1 and then 3
Promise.reject().catch(print.bind(1)).catch(print.bind(2)).finally(print.bind(3))
```

### Then and Catch Parameters

Notice that the `Promise Chain`s for both `ECMAScript` and `Godot Promise` stops at the first `catch` statement, yet continues through every `then` statement.

You can actually change this via the methods’ arguments.

```
# Parameter version of 'Godot Promise''s `then`, `catch`, and `finally` methods.
Promise.new().then(async = null, pipe_prev : bool = false)
Promise.new().then(async = null, pipe_prev : bool = false, is_stopgate : bool = false)
Promise.new().catch(async = null, pipe_prev : bool = false, is_stopgate : bool = true)
```

This is where `Godot Promise` provides more customizability than `ECMAScript`.

_Note_:

1. When `pipe_prev` is `true`, then the previous output of the previous `Godot Promise` (within the current promise chain) will be binded to the current `Godot Promise`’s argument as a Callable argument. This only works if the current `Godot Promise` is given a `Callable` to await on.
2. If `is_stopgate` is `true`, then the previous `Godot Promise` output will cancel all following `Godot Promise`’s in the chain if an unexpected status is found in the previous `Godot Promise` of the chain. “Unexpected” means **Rejected** for ` then` method or **Resolved** for ` catch` method.

With these parameters, you can flip the purpose of `then` and `catch` whenever needed.

```
# Will print to log 1 and then 3
Promise.resolve().then(
    print.bind(1), false, true
).then(
    print.bind(2), false, true
).finally(print.bind(3))

## Notice that finally still runs.
```

```
# Will print to log 1, 2, and then 3
Promise.reject().catch(
    print.bind(1), false, false
).catch(
    print.bind(2), false, false
).finally(print.bind(3))

## Notice that finally still runs.
```

...or, you can prevent the result of some `Godot Promise`s from interacting with other `Callables`.

```
var c1 := func(): return
var c2 := func(obj = true): print(obj)

# Will print to log 'null'
Promise.new().then(c1, false).then(c2, true)
# Will print to log 'true'
Promise.new().then(c1, false).then(c2, false)
```

_Note_: Although piping from `Promise` to `Promise` is a standard feature in `ECMAScript`, attempting to bind arguments to a `Callable` (that doesn't ask for parameters) in `Godot` causes an error. Thus, to avoid common errors, `pipe_prev` is defaulted to `false`. Use it only when you need to.

### Split Chains

Keep in mind you can also split `Promises`.

In `ECMAScript`...

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

...and in `Godot Promise`...

```
var promise := Promise.new()

# Outputs both 1 and 2 to the log immediately after `promise` finishes execution.
promise.then(print.bind(1))
promise.then(print.bind(2))
```

### Other Chain Information

For chains to function in `Godot`, each `Godot Promise` is has a known `status`. You can use the method `peek` to check the status of a `Promise`.

All possible statuses a `Promise` can have are shown in the documentation:

```
enum PromiseStatus {
    Initialized = 0, ## The promise hasn't yet been executed
    Pending = 1, ## The promise has been executed, but not finished
    Accepted = 2, ## The promise is finished and accepted
    Rejected = 3, ## The promise is finished, but rejected
    Canceled = 4  ## The promise's execution is skipped/canceled
}
```

You may also use `get_prev()` to get the previous `Godot Promise` in the `Godot Promise` chain.

Also, to reset a `Godot Promise Chain`, you use `reset_chain()` instead of `reset()`.

```
var p1 := Promise.new().then().then().then()
var p2 := Promise.new().then().then().then()

p1.reset() # Only resets the head (the last 'then()')
p1.reset_chain() # Resets all promises before and including the head (the entire chain)
```

## Common Mistakes

_Note_: that Promise is a complex object, so it's easy to misuse.

### reset_chain()

After attempting to `reset_chain()`, you may want to execute the `Godot Promise` again, like so:

```
var p := Promise.new().then().then().catch().then()
await p.finished
p.reset_chain()
p.execute()
```

However, `p` is a variable that only stores the tail of the `Godot Promise Chain`. Thus, doing `p.execute()` will only execute the last `then()`. In order to execute the full `Godot Promise Chain` again, do...

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

## ReferenceCounter

### Basic Ref

When using `Godot Promise`, you might want to return the `finished` output of the Signal. To do that, you might try something like...

```
func _test() -> Signal:
    return Promise.new().finished

func other_test() -> void:
    await _test()
```

However, this will cause an error.

`Promise` is a `RefCounter` object. This means that, in a situation where the reference to a `Godot Promise` is no longer stored anywhere, the `Godot Promise` will automatically clear itself, which will clear the Signal too. Hence, the `error` when attempting to use the Signal.

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

This may appear ugly, but it's something needed for the object to be automatically constructed and destroyed.

### Promise Chain Refs

_Note_: `Godot Promises` can store a reference to the previous `Godot Promise` in a `Godot Promise Chain`, but they do not store a reference to the next `Godot Promise` in a chain.

For example:

```
func _test_1() -> Promise:
    var p := Promise.new(1)
    p.then(2)
    return p

func _test_2() -> Promise:
    return Promise.new(1).then(2)

func other_test_1() -> void:
    // Outputs 1
    await _test_1().finished

func other_test_2() -> void:
    // Outputs 2
    await _test_2().finished
```

## Promises And Timers

Look at the code below...

```
func test() -> void:
    p = Promise.new()
    for n in 10:
        p.then(get_tree().create_timer(0.1).timeout)
    await p.finished
```

At first glance, it appears that this function will `await` for exactly `0.1 * 10` seconds. However, no. It waits for exactly `0.1` seconds only.

This is because you are creating all `get_tree().create_timer(0.1)` in the same frame. These timers will all finish `0.1` seconds later, regardless of what happens, and the `Godot Promises` respect that.

Instead, you need to create and `await` the timers on demand. For example...

```
func test_helper() -> void:
    await get_tree().create_timer(0.1).timeout

func test() -> void:
    p = Promise.new()
    for n in 10:
        p.then(test_helper)
    await p.finished
```

This will work and `await` for exactly `0.1 * 10` seconds, as the timers are being created only when needed.

## Promises Ouputing Callables

It's easy to confuse `Callables` with return values.

Notice the difference between...

```
Promise.new().then(get_tree().create_timer(1).timeout).new(print("Hello"))
```

...and...

```
Promise.new().then(get_tree().create_timer(1).timeout).then(print.bind("Hello"))
```

The first one will print `"Hello"` instantly and then have an output of `null` after `1` second.
The second one will print `"Hello"` and have an output `null` after 1 second.

It's an easy mistake to make, and it can be a pain to debug. Be sure to pay attention.

## Modularability

_Note_: This framework is developed via modular blocks, which YOU may also edit.

For example, the `all` coroutine is built on the inner class `AllCoroutine`, which is an extension of the inner class `ArrayCoroutine`, which is an extension of the inner class `MultiCoroutine`, which is an extension of the inner class `AbstractLogic`.

All methods that handle `Godot Promise` logic is built on `AbstractLogic`. By iteratively making new inner class extension to `AbstractLogic`, you can create building blocks for any imaginable way of handling a promise routine.

Examples of how to create custom logic are given via the **PromiseEx** object class (also included within this addon) and Documentation.

The **PromiseEx** has methods that load resources, an `all` that sorts signals from first to finish to last, a reverse `any`, and more. Check it out. The sky is the limit.

## Installation

#### Asset Library or Asset Store (Recommended - Stable)

- In Godot, open the [AssetLib](https://godotengine.org/asset-library/asset) or [AssetStore](https://store.godotengine.org/) tab.
- Search for and select "GodotPromise".
- Download then install the plugin (be sure to only select the `GodotPromise` directory).
- Enable the plugin inside Project/Project Settings/Plugins.

#### Github Releases (Recommended - Stable)

- Download a release build.
- Extract the zip file and move the `addons/GodotPromise` directory into the project `addon` folder location.
- Enable the plugin inside Project/Project Settings/Plugins.

#### Github Main (Latest - Unstable)

- Download the latest main branch.
- Extract the zip file and move the `addons/GodotPromise` directory into project's `addon` folder location.
- Enable the plugin inside Project/Project Settings/Plugins.

For more help, see [Godot's official documentation](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

## Documentation

For more information, the documentation includes a full list of functions and utilities. A few more niche methods, not discussed here, are fully explained there.

Enjoy.

## Known Issues

None

## Links

<a href='https://ko-fi.com/E2J420AV1G' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
