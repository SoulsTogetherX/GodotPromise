# SUMMARY

Hello Everyone in the future!

I've noticed the current Promise types on the Asset Library to be lacking in a few ways, so I improved them.

I replicated ***ALL*** functions related to the [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise). type in Javascript (except try(), but that's becuase it's behavior is implied by default).

Promises can be accepted or rejected. then(), catch(), and finally() functions work as expected with this.

This type works for Signals, Callables, other Promises, and ***EVERY*** other type. to_string() converts the Promise into the format "Promise<Type>".

It is possible and *recommended* to chain Promises.

It is fully documented and the code is efficient and compact to help with easy understanding.

I made it easy to create custom Promise functionality with the use of modular Inner Classes.

Can be mindlessly plugged in to synchronize coroutines, or be easily extended to allow ***anything*** else you may need (for example, the result of first 3 coroutines to finished should be intuitive to add by extending from the Inner Classes at the bottom of the document).

# CODE EXAMPLES

To use, simply create a Promise type as such:
```
await Promise.new(val).finished
```
You may also use one of the premade static options already available. For example:
```
await Promise.any([val1, val2, val3, val4]).finished
await Promise.race([val1, val2, val3, val4]).finished
await Promise.allSettled([val1, val2, val3, val4]).finished
await Promise.all([val1, val2, val3, val4]).finished
```

...etc.

Again, you may also chain Promises. For example:

```
print(
	await Promise.any([val1, val2, val3, val4]).then(
		"At least one coroutine was resolved"
	).catch(
		"All coroutines were rejected! O:"
	).finished
)
```

For a full list of functions available, please refer to the documention provided.

Enjoy.
