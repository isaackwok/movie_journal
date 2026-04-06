---
name: Flutter Animation Testing
description: >
  This skill should be used when writing or debugging Flutter widget tests
  that involve AnimationController, animateTo, animateBack, Future.delayed,
  pumpAndSettle, chained animations, or any async animation sequencing.
  Use this skill to avoid known pitfalls with animation controller status,
  timer-based delays in tests, and async animation chaining.
version: 0.1.0
---

# Flutter Animation Testing Patterns

This skill documents hard-won lessons about testing Flutter animations.
These pitfalls are non-obvious and cause test failures that are difficult
to diagnose from error messages alone.

## Pitfall 1: `animateTo` vs `animateBack` — Controller Status Corruption

### The Problem

`animateTo(target)` **always** sets `_direction = _AnimationDirection.forward`
internally, regardless of whether the target is above or below the current
value. When the animation completes, Flutter sets the status based on
direction:

- `forward` direction → `AnimationStatus.completed`
- `reverse` direction → `AnimationStatus.dismissed`

This means `animateTo(0.0)` completes with **`isCompleted = true`** even
though the value is at the lower bound. Any code that uses `isCompleted` to
decide between `forward()` and `reverse()` will break:

```dart
// BROKEN: After animateTo(0.0), isCompleted is true
// so this calls reverse() from 0.0 → 0.0 (no-op)
void _flip() {
  if (_controller.isCompleted) {
    _controller.reverse();  // no-op!
  } else {
    _controller.forward();
  }
}
```

### The Fix

Use `animateBack(target)` when animating toward the lower bound. It sets
`_direction = reverse`, so completion at 0.0 produces `dismissed` status:

```dart
// Peek out
await _controller.animateTo(0.15, duration: peekDuration);

// Return — use animateBack, NOT animateTo
await _controller.animateBack(0.0, duration: returnDuration);
// Now: value=0.0, status=dismissed, isCompleted=false ✓
```

### Rule of Thumb

| Direction | Method | Completion Status |
|-----------|--------|-------------------|
| Toward upper bound | `animateTo()` | `completed` |
| Toward lower bound | `animateBack()` | `dismissed` |

If your code later checks `isCompleted` or `isDismissed`, the wrong method
will silently corrupt the controller state with no error or warning.

## Pitfall 2: `pumpAndSettle` Does Not Advance Past `Future.delayed`

### The Problem

`pumpAndSettle()` pumps frames in 100ms increments until
`hasScheduledFrame` is false. But `Future.delayed` creates a **Timer**,
not an animation frame. If no animation is running when `pumpAndSettle`
checks, it returns immediately — even though a timer is still pending.

```dart
// BROKEN: pumpAndSettle returns immediately because no frames are scheduled
await tester.pumpWidget(buildWidget()); // initState schedules Future.delayed(500ms)
await tester.pumpAndSettle();           // returns immediately, timer still pending
// Test ends → "A Timer is still pending" assertion error
```

### The Fix

Explicitly `pump()` past the timer duration first, then settle:

```dart
// CORRECT: advance past the timer, then settle the resulting animation
await tester.pumpWidget(buildWidget());
await tester.pump(const Duration(milliseconds: 500)); // fires the delayed future
await tester.pumpAndSettle();                          // settles any triggered animation
```

### Rule of Thumb

If `initState` or any lifecycle method uses `Future.delayed`,
**always** `pump(delay)` explicitly before `pumpAndSettle()`.

## Pitfall 3: `pumpAndSettle` Between Chained Async Animations

### The Problem

When two animations are chained with `await`:

```dart
await _controller.animateTo(0.15, duration: Duration(milliseconds: 350));
// ← microtask gap here after first animation completes
await _controller.animateBack(0.0, duration: Duration(milliseconds: 350));
```

`pumpAndSettle` **may** return in the microtask gap between the two
animations. After the first `animateTo` completes:

1. The TickerFuture resolves
2. The `await` continuation is scheduled as a microtask
3. `pumpAndSettle` checks `hasScheduledFrame` → false (first animation done)
4. `pumpAndSettle` returns before the second animation starts

Whether this actually happens depends on Flutter's internal microtask
processing order within `pump()`. It's flaky and framework-version-dependent.

### The Fix

For multi-phase animations, use explicit pump durations for each phase:

```dart
// RELIABLE: pump past each phase explicitly
await tester.pump(const Duration(milliseconds: 500)); // past Future.delayed
await tester.pump(const Duration(milliseconds: 400)); // past first animateTo (350ms + buffer)
await tester.pump(const Duration(milliseconds: 400)); // past second animateBack (350ms + buffer)
```

Or use a single large pump to cover everything:

```dart
// Also works: one pump past the total duration
await tester.pump(const Duration(milliseconds: 1300)); // 500 + 350 + 350 + buffer
```

After explicit pumps, `pumpAndSettle()` is safe to call — there are no
async gaps left to stumble over.

## Checklist for Animation Tests

Before writing a test for animated widgets:

1. **Does `initState` use `Future.delayed`?**
   → Pump past the delay explicitly before `pumpAndSettle`

2. **Does the animation chain multiple `animateTo`/`animateBack` with `await`?**
   → Don't rely on `pumpAndSettle` alone; pump past each phase

3. **Does the code check `isCompleted`/`isDismissed` after animation?**
   → Verify `animateTo` vs `animateBack` matches the expected status

4. **Can the user interact during the animation?**
   → Test the `isAnimating` guard and any cancellation flags

5. **Can the user interact during a pre-animation delay?**
   → Test the window between the delay and animation start

## Example: Testing a Peek + Flip Sequence

```dart
// Setup: widget has a 500ms delayed peek animation on mount
await tester.pumpWidget(buildSubject(hintOnMount: true));

// Phase 1: advance past the Future.delayed
await tester.pump(const Duration(milliseconds: 500));

// Phase 2: advance past peek out (350ms) + peek return (350ms)
await tester.pump(const Duration(milliseconds: 400));
await tester.pump(const Duration(milliseconds: 400));

// Now the animation is fully settled — safe to interact
await tester.tap(find.byType(GestureDetector));
await tester.pumpAndSettle(); // pumpAndSettle is fine for a single forward() call

expect(find.text('BACK'), findsOneWidget);
```
