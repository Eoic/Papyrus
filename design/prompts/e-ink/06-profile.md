# Profile & Settings - E-ink

Self-contained design prompt for Profile and Settings screens on e-ink devices.

---

## Color Reference (E-ink Only)

| Token | Value | Usage |
|-------|-------|-------|
| Black | `#000000` | Text, borders |
| White | `#FFFFFF` | Background |
| Dark Gray | `#404040` | Secondary text |
| Light Gray | `#C0C0C0` | Dividers |
| Container | `#F5F5F5` | Cards |

---

## Screen 1: Profile Page

### Layout (1072 x 1448 viewport)

```
┌───────────────────────────────────────────────────────────────────┐
│  PROFILE                                                          │  Header: 72px
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│                    ┌─────────────┐                                │
│                    │             │                                │
│                    │   [Avatar]  │                                │  Avatar: 120px
│                    │    120px    │                                │
│                    │             │                                │
│                    └─────────────┘                                │
│                                                                   │
│                       JOHN DOE                                    │  Name: 24px bold
│                    john@email.com                                 │  Email: 16px
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    EDIT PROFILE                             │  │  Button: 56px
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  SETTINGS                                               [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  STORAGE MANAGEMENT                                     [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  INFORMATION                                            [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ─────────────────────────────────────────────────────────────────│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  LOG OUT                                                    │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│  DASHBOARD  │  LIBRARY  │  GOALS  │  SETTINGS                    │
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Avatar:**
- Size: 120 x 120px
- Border: 2px solid Black
- Border radius: 0px (square for e-ink)
- Placeholder: Initials in center

**User Info:**
- Name: 24px, bold, uppercase, centered
- Email: 16px, centered
- Margin: 16px below avatar

**Edit Profile Button:**
- Full width - 96px margins
- Height: 56px
- Border: 2px solid Black
- Background: White
- Text: 18px, bold

**Menu Item:**
```
┌─────────────────────────────────────────────────────────────────┐
│  MENU LABEL                                                 [>] │
└─────────────────────────────────────────────────────────────────┘
```
- Height: 64px
- Padding: 16px
- Text: 18px, uppercase
- Chevron: > character or icon
- Touch target: Full width

**Logout Item:**
- Same as menu item
- No chevron

**Divider:**
- 1px Light Gray between items

---

## Screen 2: Settings Page

### Layout

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  SETTINGS                                                    │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  APPEARANCE                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  THEME                                                      │  │
│  │  ─────────────────────────────────────────────────────────  │  │
│  │  ○ LIGHT                                                    │  │
│  │  ● DARK                                                     │  │
│  │  ○ SYSTEM                                                   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  READING                                                          │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  DEFAULT FONT                                               │  │
│  │  ─────────────────────────────────────────────────────────  │  │
│  │  ○ GEORGIA                                                  │  │
│  │  ● LITERATA                                                 │  │
│  │  ○ BOOKERLY                                                 │  │
│  │  ○ OPEN DYSLEXIC                                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  FONT SIZE                                                  │  │
│  │  ─────────────────────────────────────────────────────────  │  │
│  │  [ - ]  ████████████████  18px  [ + ]                      │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  STORAGE                                                          │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  STORAGE BACKEND                                        [>] │  │
│  │  Currently: Local Storage                                   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ABOUT                                                            │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  VERSION                                              1.0.0 │  │
│  │  LICENSES                                               [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Section Header:**
- Text: 14px, bold, uppercase
- Color: Dark Gray
- Margin: 24px top, 8px bottom

**Settings Card:**
- Border: 2px solid Black
- Padding: 16px
- Background: White

**Radio Group:**
```
○ OPTION ONE
● OPTION TWO (selected)
○ OPTION THREE
```
- Row height: 56px (touch target)
- Radio: 24px circle
- Selected: Filled black dot
- Text: 18px

**Font Size Control:**
```
[ - ]  ████████████████  18px  [ + ]
```
- Decrease/Increase buttons: 56x56px
- Bar: Visual indicator of size
- Current value: Centered text

**Settings Row (Navigation):**
```
┌─────────────────────────────────────────────────────────────────┐
│  LABEL                                                      [>] │
│  Current value                                                  │
└─────────────────────────────────────────────────────────────────┘
```
- Two-line: Label and current value
- Height: 72px

**Settings Row (Value):**
```
┌─────────────────────────────────────────────────────────────────┐
│  LABEL                                                    VALUE │
└─────────────────────────────────────────────────────────────────┘
```
- Label left, value right
- Height: 56px

---

## Edit Profile Screen

```
┌───────────────────────────────────────────────────────────────────┐
│  [←]  EDIT PROFILE                                       [SAVE]  │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│                    ┌─────────────┐                                │
│                    │   [Avatar]  │                                │
│                    │   CHANGE    │                                │
│                    └─────────────┘                                │
│                                                                   │
│  DISPLAY NAME                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  John Doe                                                   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  EMAIL (cannot be changed)                                        │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  john@email.com                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  CHANGE PASSWORD                                        [>] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Figma Generation Instructions

```
CREATE E-INK PROFILE & SETTINGS SCREENS

GLOBAL RULES:
- Background: #FFFFFF
- All borders: 2px solid #000000
- Border radius: 0px
- Touch targets: 56px minimum
- Text uppercase for labels

Frame 1: Profile Page (1072 x 1448)
- Header: "PROFILE", 72px
- Avatar: 120px square, centered, 2px border
- Name: 24px bold uppercase, centered
- Email: 16px, centered
- Edit Profile button: 56px height, bordered
- Menu items: 64px each, uppercase, chevrons
- Logout: Same style, no chevron
- Bottom nav

Frame 2: Settings Page (1072 x 1448)
- Header: Back button, "SETTINGS"
- Sections: Appearance, Reading, Storage, About
- Section headers: 14px bold gray uppercase
- Radio groups: 24px radio, 56px row height
- Font size: Stepper control with - and + buttons
- Navigation rows: Label + value + chevron
- Value rows: Label + value aligned right

Frame 3: Edit Profile (1072 x 1448)
- Header: Back button, "EDIT PROFILE", SAVE button
- Avatar with "CHANGE" label
- Name input: 64px
- Email input: 64px, disabled styling (gray bg)
- Change Password row

STATES:
- Radio selected: Filled dot
- Button pressed: Inverted colors
- Input focused: 4px border
- Disabled input: #F5F5F5 background
```
