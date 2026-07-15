---
target: lib/screens/analytics_screen.dart
total_score: 23
p0_count: 0
p1_count: 2
timestamp: 2026-06-07T13-10-40Z
slug: lib-screens-analytics-screen-dart
---
## Analytics Screen — Design Critique

### Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Loading states present; chart doesn't visually react to period change |
| 2 | Match System / Real World | 2 | Period toggle changes summary totals but leaves chart data untouched — broken contract |
| 3 | User Control and Freedom | 3 | All toggles freely reversible; no traps |
| 4 | Consistency and Standards | 2 | Period applies to summary card but not to SubsBar/SubsPie — same control, inconsistent scope |
| 5 | Error Prevention | 3 | Few error vectors; empty state handled; no destructive inputs |
| 6 | Recognition Rather Than Recall | 2 | `$`/`%` symbols require recall; no label or tooltip |
| 7 | Flexibility and Efficiency | 2 | 3 period presets, 2 chart modes; no sort, filter, or export |
| 8 | Aesthetic and Minimalist Design | 2 | Chart container double-boxed; N-identical breakdown cards |
| 9 | Error Recovery | 3 | Generic error string present; graceful empty state |
| 10 | Help and Documentation | 1 | Zero contextual help; no tooltips; no explanation of toggle scope |
| **Total** | | **23/40** | **Acceptable — significant improvements needed** |

### Anti-Patterns Verdict

Deterministic scan: clean (0 findings). No slop patterns detected. Design is coherent — coral accent restrained, border-radius 12px correct, no gradient text, no side-stripe borders.

### Overall Impression

Structurally sound but analytically misleading. The period toggle is the most prominent control and it only does half its job — charts always show monthly data regardless of period selected. That's the single biggest trust problem. Everything else is refinement.

### What's Working

1. Color-coded breakdown items — meaningful color, not decoration; semanticsLabel on progress bars is a deliberate accessibility choice.
2. Summary card data density — compact two-column layout with coral accent on total is clean and effective.
3. SegmentedButton reuse — consistent component for both controls; users learn it once.

### Priority Issues

**[P1] Period filter doesn't apply to chart data**
SubsBar and SubsPie always render `monthlyAmount` with no multiplier. Summary card says "Total Yearly: $1,200." Chart still shows monthly bars. Creates a misleading mental model. Fix: pass multiplier to chart widgets as a constructor parameter.

**[P1] Chart section has no contextual label**
Chart container begins directly with SegmentedButton — no heading, no sub-title. Users don't know what temporal scope the chart represents. Fix: add a text heading or subtitle tying the chart to the active period.

**[P2] `$`/`%` chart toggle labels too terse**
Symbols tell you the unit but not the chart type. First-time users have no way to infer `$` = bar chart, `%` = pie chart. Fix: use "Amount" / "Share" labels, or add icons.

**[P2] N-identical breakdown cards, no visual rhythm**
ListView emits N copies of the same structure. On 5+ subscriptions this creates visual fatigue. Fix: differentiate the top item; add grouping by price tier or size variation.

**[P3] Chart container double-boxes the chart widget**
Outer Container with surfaceContainer fill + 16px padding wraps SubsBar which already has its own data area. Fix: remove container fill color or reduce padding.

### Persona Red Flags

**Alex (Power User):** Selects "Year", summary updates, chart doesn't change → trust erosion. No sort, filter, date range, or export. Two controls total for an analytics screen.

**Sam (Accessibility-Dependent):** SegmentedButton and LinearProgressIndicator semantics are good. fl_chart widgets expose no semantic descriptions of chart data — screen reader users hear nothing on the chart region.

**Casey (Distracted Mobile User):** No loading skeleton — full-screen spinner on cold start. Period toggles sit above fold (good). State loss on backgrounding if period is non-default.

### Minor Observations

- `IntrinsicHeight` in `_SummaryCard` triggers double layout pass — cheaper to use fixed-height column children.
- `SubsPie` appends `SizedBox(height: 12)` inside already-padded chart container — ~28px dead space.
- `_coral` in `_SummaryCard` hardcodes `Color(0xFFD83434)` — same value as `kCoralAccent` in `app_theme.dart`; single source preferred.

### Questions to Consider

- "What does 'analytics' mean to a user who's tracked subscriptions for 6 months — 'what am I spending?' or 'what changed?'"
- "The period selector and chart mode toggle are the only two interactions — if you had to cut one, which gives more value?"
- "What if the chart were removed and the breakdown list did more heavy lifting — larger numbers, trend arrows, category grouping?"
