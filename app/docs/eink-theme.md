# E-ink theme

E-ink is a theme choice alongside light and dark. Screen width selects the app
shell and page layout; selecting e-ink keeps the current route and responsive
breakpoints. Typography sizes, control dimensions, card margins, and spacing
match the regular themes. Black/white selection states, stronger borders, and
opaque surfaces keep controls legible without shadows or color alone.

Input labels stay above their fields in e-ink, and focus borders snap to their
target thickness instead of interpolating. Hints appear without fading. These
changes use the input theme and preserve the native field's text, selection,
keyboard focus, and validation. Light and dark retain floating-label and border
animations. Pixel comparisons in `test/themes/eink_input_focus_test.dart` cover
focus and blur, explicit form borders, and switching themes while editing.

`AppMotion` carries the motion policy independently of layout. E-ink enables it
through its theme extension; the existing reduced-animation preference and the
system reduced-motion setting are also respected by app-controlled transitions.

When adding UI:

- Use `AppMotion.duration` and `AppMotion.animationStyle` for animations and
  overlays. Stateful animations must also finish or reset when the policy changes.
- Use the shared progress indicators. Indeterminate indicators retain their
  loading semantics and a visible static phase; determinate values still update.
- Use `AppMotionControl` for framework controls with private animation
  controllers. Its local ticker scope and retained focus let controls update
  immediately without freezing an entire page.
- Use the shared date-picker and drawer entry points. Flutter's stock calendar
  has internal transitions independent of its route, so reduced-motion calendar
  controls change months and years directly. Cancel never saves a selection.
- Keep dimensions and navigation decisions independent of the theme.

Light and dark keep their normal animation timings. User-driven scrolling and
actual data/progress updates remain available in e-ink.

Regression coverage lives in `test/widgets/shell/eink_layout_test.dart`,
`test/themes/eink_theme_test.dart`, `test/widgets/app_motion_integration_test.dart`,
`test/widgets/app_motion_control_test.dart`, and
`test/widgets/static_date_picker_test.dart`.

Validated on `feature/eink-theme`, based on this repository's default `master`
branch: `flutter test --no-pub` passed 1,145 tests (10 skipped),
`flutter analyze --no-pub` reported no issues, and
`flutter build web --release --no-pub` succeeded.
