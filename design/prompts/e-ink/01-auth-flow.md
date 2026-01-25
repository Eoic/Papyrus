# Authentication Flow - E-ink

Self-contained design prompt for Welcome, Login, and Register screens on e-ink devices.

---

## Color Reference (E-ink Only)

| Token | Value | Usage |
|-------|-------|-------|
| Black | `#000000` | Primary text, borders, filled buttons |
| White | `#FFFFFF` | Background, text on black |
| Dark Gray | `#404040` | Secondary text |
| Medium Gray | `#808080` | Disabled states |
| Light Gray | `#C0C0C0` | Subtle borders |
| Container | `#F5F5F5` | Input backgrounds |

**Rules:**
- NO gradients
- NO shadows
- NO transparency
- Minimum 2px borders
- Border radius: 0px (sharp corners)

---

## Screen 1: Welcome Page

### Purpose
Simple, high-contrast entry point optimized for e-ink display.

### Layout (1072 x 1448 viewport - 6" e-reader)

```
┌───────────────────────────────────────────────────────────────────┐
│                                                                   │
│                                                                   │
│                                                                   │
│                                                                   │
│                      ┌─────────────────┐                          │
│                      │                 │                          │
│                      │   [Logo PNG]    │                          │  200 x 200px
│                      │                 │                          │
│                      └─────────────────┘                          │
│                                                                   │
│                           PAPYRUS                                 │  48px, bold
│                                                                   │
│                  Your ultimate digital library                    │  20px
│                                                                   │
│                                                                   │
│                                                                   │
│  Margin: 48px horizontal                                          │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                      GET STARTED                            │  │  64px height
│  └─────────────────────────────────────────────────────────────┘  │  Black fill
│                            (24px)                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                        SIGN IN                              │  │  64px height
│  └─────────────────────────────────────────────────────────────┘  │  2px border
│                            (24px)                                 │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  │
│  │                    USE OFFLINE MODE                         │  │  56px height
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  │  Underlined text
│                                                                   │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Logo:**
- Size: 200 x 200px
- High contrast version (black on white)
- Centered horizontally

**App Title:**
- Text: "PAPYRUS" (uppercase for e-ink clarity)
- Size: 48px
- Weight: 700 (bold)
- Color: Black (`#000000`)
- Margin top: 32px

**Tagline:**
- Text: "Your ultimate digital library"
- Size: 20px
- Weight: 400
- Color: Black (`#000000`)
- Margin top: 16px

**Get Started Button (Primary):**
- Width: Full width minus 96px (48px margins each side)
- Height: 64px
- Background: Black (`#000000`)
- Text: "GET STARTED" (uppercase)
- Text color: White (`#FFFFFF`)
- Text size: 20px
- Weight: 600
- Border: none
- Border radius: 0px

**Sign In Button (Secondary):**
- Width: Full width minus 96px
- Height: 64px
- Background: White (`#FFFFFF`)
- Text: "SIGN IN" (uppercase)
- Text color: Black (`#000000`)
- Text size: 20px
- Weight: 600
- Border: 2px solid Black
- Border radius: 0px
- Margin top: 24px

**Offline Mode Link:**
- Width: Full width minus 96px
- Height: 56px (touch target)
- Text: "USE OFFLINE MODE" (uppercase)
- Text color: Black (`#000000`)
- Text size: 18px
- Decoration: Underline
- Margin top: 24px

---

## Screen 2: Login Page

### Purpose
Simple form-based login optimized for e-ink touch input.

### Layout

```
┌───────────────────────────────────────────────────────────────────┐
│  ┌────┐                                                           │
│  │ ←  │  SIGN IN                                                 │  Header: 72px
│  └────┘                                                           │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Margin: 48px horizontal                                          │
│                                                                   │
│  EMAIL                                                            │  Label: 16px, bold
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │  Input: 64px
│  │  your@email.com                                             │  │  2px border
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            (24px)                                 │
│  PASSWORD                                                         │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  │  ••••••••                                      [SHOW]       │  │  Input: 64px
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            (16px)                                 │
│                                           Forgot password? →      │  Right-aligned
│                            (32px)                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                       CONTINUE                              │  │  64px, black fill
│  └─────────────────────────────────────────────────────────────┘  │
│                            (32px)                                 │
│  ────────────────── OR ──────────────────                        │  Divider
│                            (32px)                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │             SIGN IN WITH GOOGLE                             │  │  64px, bordered
│  └─────────────────────────────────────────────────────────────┘  │
│                            (48px)                                 │
│                Don't have an account? SIGN UP                     │  Centered
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Header:**
- Height: 72px
- Background: White
- Border bottom: 2px solid Black
- Back button: 56x56px touch target, "←" arrow
- Title: "SIGN IN", 24px, bold, left-aligned after back button

**Email Label:**
- Text: "EMAIL"
- Size: 16px
- Weight: 700
- Color: Black
- Margin bottom: 8px

**Email Input:**
- Width: Full width minus 96px
- Height: 64px
- Background: Container (`#F5F5F5`)
- Border: 2px solid Black
- Border radius: 0px
- Text: 20px
- Padding: 16px

**Password Label:**
- Text: "PASSWORD"
- Size: 16px
- Weight: 700
- Margin top: 24px

**Password Input:**
- Same as email
- Show/Hide toggle: Text button "SHOW"/"HIDE" inside input, right-aligned

**Forgot Password:**
- Text: "Forgot password? →"
- Size: 16px
- Color: Black
- Decoration: Underline
- Alignment: Right
- Margin top: 16px

**Continue Button:**
- Width: Full width minus 96px
- Height: 64px
- Background: Black
- Text: "CONTINUE", 20px, bold, white
- Margin top: 32px

**Divider:**
- Line: 2px solid Light Gray (`#C0C0C0`)
- Text: "OR"
- Text size: 16px
- Background: White (behind text)
- Margin: 32px vertical

**Google Button:**
- Width: Full width minus 96px
- Height: 64px
- Background: White
- Border: 2px solid Black
- Text: "SIGN IN WITH GOOGLE"
- Text size: 20px
- No Google logo (simplify for e-ink)

**Sign Up Link:**
- Text: "Don't have an account? SIGN UP"
- "SIGN UP" underlined
- Size: 16px
- Centered
- Margin top: 48px

---

## Screen 3: Register Page

### Layout

```
┌───────────────────────────────────────────────────────────────────┐
│  ┌────┐                                                           │
│  │ ←  │  CREATE ACCOUNT                                          │
│  └────┘                                                           │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  EMAIL                                                            │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            (24px)                                 │
│  PASSWORD                                                         │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  Minimum 8 characters                                             │  Helper text
│                            (24px)                                 │
│  CONFIRM PASSWORD                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            (32px)                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                       CONTINUE                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            (32px)                                 │
│  ────────────────── OR ──────────────────                        │
│                            (32px)                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │            SIGN UP WITH GOOGLE                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            (48px)                                 │
│               Already have an account? SIGN IN                    │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Additional Specifications

**Password Helper:**
- Text: "Minimum 8 characters"
- Size: 14px
- Color: Dark Gray (`#404040`)
- Margin top: 8px

**Error States:**
- Border: 4px solid Black (instead of color)
- Error message below field
- Text: 14px, Black
- Prefix with "Error: " for clarity

---

## States to Design

### All Screens
1. **Default** - Empty/initial state
2. **Focused** - Input with 4px border (instead of 2px)
3. **Filled** - With content
4. **Error** - 4px border + error message
5. **Disabled** - Gray text and borders

### Loading State
- Replace button text with "LOADING..."
- No spinner (e-ink can't animate)

---

## Figma Generation Instructions

```
CREATE E-INK AUTH FLOW SCREENS

GLOBAL RULES:
- All backgrounds: #FFFFFF
- All primary elements: #000000
- No gradients, shadows, or transparency
- All border radius: 0px
- Minimum border width: 2px
- Minimum font size: 14px
- Touch targets: Minimum 56x56px

Frame 1: Welcome Page (1072 x 1448)
- Background: #FFFFFF
- Logo: 200x200px, centered, high contrast
- "PAPYRUS": 48px, bold, #000000, centered
- Tagline: 20px, #000000, centered
- Primary button: Full width - 96px margins, 64px height, #000000 fill, "GET STARTED" white text
- Secondary button: Same size, #FFFFFF fill, 2px #000000 border, "SIGN IN" black text
- Text link: "USE OFFLINE MODE", underlined, centered

Frame 2: Login Page (1072 x 1448)
- Header: 72px height, 2px bottom border
- Back arrow: 56x56px touch area
- Title: "SIGN IN", 24px bold
- Labels: 16px bold, above inputs
- Inputs: 64px height, #F5F5F5 fill, 2px #000000 border
- Continue button: 64px, #000000 fill, white text
- Divider: 2px #C0C0C0 line with "OR" text
- Google button: 64px, white fill, 2px border

Frame 3: Register Page (1072 x 1448)
- Same layout as Login
- Title: "CREATE ACCOUNT"
- Add "CONFIRM PASSWORD" field
- Add helper text under password

STATE VARIANTS:
- Input focused: 4px border instead of 2px
- Input error: 4px border + error text below
- Button pressed: Invert colors (white on black becomes black on white)
- Disabled: Use #808080 for borders and text
```
