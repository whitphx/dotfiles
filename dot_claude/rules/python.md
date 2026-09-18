---
paths:
  - "**/*.py"
---

# Python style rules

## `assert` is not for runtime invariants

Python strips `assert` statements when run with `-O` (and `-OO`). Anything inside an `assert` — both the expression *and* its side-effects — disappears in optimized builds. That makes `assert` unsafe for:

- Validating inputs at a public API boundary.
- Checking invariants the rest of the function depends on ("we trust this is non-None below").
- Any production-side check whose absence would let a bug slip through silently.

### What to do instead

- **Runtime check that must execute** → explicit `if ... raise`:
  ```python
  if user_id is None:
      raise ValueError("user_id is required")
  ```
  Pick the right exception type (`ValueError` / `TypeError` / a domain-specific one). Don't lose the check to `-O`.

- **Type narrowing for the type checker, no runtime check needed** → `typing.cast(T, value)`:
  ```python
  from typing import cast
  # We just constructed `worker` from non-None inputs, so the helper
  # cannot have returned None here.
  output = cast(MediaStreamTrack, build_output_track(...))
  ```
  `cast()` is purely a static annotation. No bytecode, no stripping under `-O`, same effect on mypy as `assert isinstance(...)` but without the disappearing safety net.

- **Defensive double-check at the boundary of a public API** → `if/raise` again, not `assert`. The fact that "callers shouldn't pass None" doesn't mean a hostile or buggy caller won't; if you actually want the check, make it survive `-O`.

### When `assert` is appropriate

- **Inside pytest tests.** `assert` is the test framework's mechanism — pytest rewrites assertions to give nice failure messages, and `-O` doesn't run in test CI.
- **Short one-off scripts you control.** Same reason: `-O` won't run there.
- **Truly unreachable-branch markers in deeply internal code** where the alternative would be a `raise NotImplementedError` and the difference is mostly aesthetic. Even then, prefer `raise AssertionError(...)` to make intent explicit (and immune to `-O` stripping).

The common rule: `assert` is a debugging / testing affordance, not a runtime contract.

## Pass arguments by keyword instead of splatting a sequence

`f(*pair)` and `f(**mapping)` hide which parameter each value lands in. Two things then break quietly:

- **The type checker loses the binding.** mypy sees a `Tuple[str, str]` going into two `str` parameters. It cannot tell you the two values are the wrong way round, because both orderings type-check.
- **A signature change misbinds silently.** Add, remove, or reorder a parameter and the call still has the right arity, so it keeps running with the values in the wrong slots.

Neither shows up as an error. The call just does the wrong thing with the right number of arguments.

### What to do instead

Unpack into named locals, then bind by keyword:

```python
# Not this
return get_cloudflare_ice_servers(*cloudflare_creds)

# This
turn_key_id, turn_key_api_token = cloudflare_creds
return get_cloudflare_ice_servers(
    turn_key_id=turn_key_id, turn_key_api_token=turn_key_api_token
)
```

The locals earn their place twice over: they bind by name, and they tell the reader what the values are, which "whatever came first in the tuple" does not.

A test that pins such a call should assert the keyword form (`assert_called_once_with(turn_key_id=..., turn_key_api_token=...)`), so a regression to positional binding fails the test.

### When splatting is fine

- **Forwarding `*args` / `**kwargs` through a wrapper or decorator**, where the whole point is to pass along a signature you do not control.
- **The callee is genuinely variadic** (`min(*values)`, `os.path.join(*parts)`), where the values have no individual names to give.

## Adding more rules to this file

When new Python-style guidance gets added (string formatting, async patterns, mypy-narrowing conventions, etc.), add it as its own H2 section in this file. Keep each rule short, with at least one concrete *what to do instead* example.
