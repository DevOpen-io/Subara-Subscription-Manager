---
target: lib/widgets/glass_nav_bar.dart
total_score: 34
p0_count: 0
p1_count: 1
timestamp: 2026-06-04T17-35-39Z
slug: lib-widgets-glass-nav-bar-dart
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Active tab clear via icon color + bold + pill; no route-change transition feedback |
| 2 | Match System / Real World | 4 | Canonical iOS bottom-tab pattern: icons + labels, 4 tabs, sensible labels |
| 3 | User Control and Freedom | 3 | Clear navigation, no trap states; back via OS gesture only |
| 4 | Consistency and Standards | 4 | All 4 tabs identical treatment, spring motion consistent |
| 5 | Error Prevention | 4 | Navigation only; minimal error surface |
| 6 | Recognition Rather Than Recall | 3 | Icons labeled (excellent); "Analytics" icon ambiguous without label, label present |
| 7 | Flexibility and Efficiency | 3 | Spring motion communicates state clearly; haptic feedback absent |
| 8 | Aesthetic and Minimalist Design | 3 | Glass is purposeful; outer drop shadow fights glass material depth |
| 9 | Error Recovery | 4 | n/a — navigation |
| 10 | Help and Documentation | 3 | Labels self-explanatory |
| **Total** | | **34/40** | **Good** |

## Anti-Patterns Verdict

Not AI slop. Glass is technically sophisticated (GPU shaders via liquid_glass_renderer), intentional (Apple iOS 26 Liquid Glass), and on-brand for an iOS-first app. One tell: outer Container drop shadow is the default floating-card pattern — generic on a glass material.

## Overall Impression

Technically excellent foundation — native spring physics, real GPU glass, proper accessibility semantics. Gap: pill slides with iOS spring but icon colors snap; glass depth is undercut by external drop shadow.

## What's Working

1. Accessibility semantics — Semantics(label, selected, button) properly implemented. VoiceOver will announce correctly.
2. iOS-authentic spring motion — CupertinoMotion.snappy() + MotionCurve is correct physics for iOS 26.
3. Multi-scheme color resilience — cs.primary / cs.onSurfaceVariant adapts to all 16 color schemes.

## Priority Issues

**[P1] Icon color snaps while glass pill slides**
- isActive is a discrete boolean: new tab icon turns primary-colored immediately while pill takes ~350ms to arrive.
- The motion IS the design. When color commits before glass, the pill becomes decorative.
- Fix: drive each tab's color from the pill's animation progress, not discrete index.

**[P2] Outer drop shadow double-stacks with glass material depth**
- BoxShadow(blurRadius: 24, offset: Offset(0, 8)) on Container wrapping LiquidGlassLayer.
- Glass material generates its own elevation cues; two depth signals compete.
- Fix: remove BoxShadow entirely. If grounding needed: blurRadius 8, offset (0, 2), alpha 0.08.

**[P2] Label font size 11sp below WCAG minimum**
- fontSize: 11 with alpha 0.6 for inactive labels. MD3 spec and WCAG 1.4.4 set minimum at 12sp.
- Fix: raise to 12sp; drop inactive opacity to max 0.55.

**[P2] No haptic feedback on tab tap**
- GestureDetector.onTap triggers no system haptic.
- iOS-first app + premium glass + native spring = strong native-feel contract. Missing haptic breaks it.
- Fix: HapticFeedback.lightImpact() in onTap. One line.

## Persona Red Flags

**Sam (Accessibility-Dependent):** VoiceOver support excellent. Failure: 11sp inactive labels at baseline.

**Casey (Distracted Mobile User):** Bottom position, full-width tappable areas are good. Color snap before haptic means no confirmation signal for quick taps.

## Minor Observations

- Comments on lines 68 and 97 explain what the code does — remove per project convention.
- `const _kBarRadius = 28.0` would keep Container borderRadius and LiquidRoundedSuperellipse in sync.
