# Authentication Flow - Desktop

Self-contained design prompt for Welcome, Login, and Register screens on desktop.

---

## Color Reference (Light Theme)

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#5654A8` | Buttons, active states |
| On Primary | `#FFFFFF` | Text on primary |
| Surface | `#FFFBFF` | Background |
| On Surface | `#1C1B1F` | Primary text |
| On Surface Variant | `#47464F` | Secondary text |
| Outline | `#787680` | Borders |
| Primary Container | `#E2DFFF` | Light purple backgrounds |
| Surface Container | `#E4E1EC` | Card backgrounds |

---

## Screen 1: Welcome Page

### Purpose
First-time user entry point with centered hero layout for desktop.

### Layout (1440 x 900 viewport)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│                                                                                 │
│                                                                                 │
│                           ┌─────────────────────┐                               │
│                           │                     │                               │
│                           │     [Logo PNG]      │                               │  200 x 200px
│                           │                     │                               │
│                           └─────────────────────┘                               │
│                                                                                 │
│                                  Papyrus                                        │  56px, displaySmall
│                                                                                 │
│                       Your ultimate digital library                             │  20px, titleLarge
│                                                                                 │
│                                                                                 │
│                           ┌─────────────────────┐                               │
│                           │     Get started     │                               │  320px wide
│                           └─────────────────────┘                               │
│                                  (16px)                                         │
│                           ┌─────────────────────┐                               │
│                           │       Sign in       │                               │
│                           └─────────────────────┘                               │
│                                  (16px)                                         │
│                              Use offline mode                                   │
│                                                                                 │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Logo:**
- Image: `assets/images/logo.png`
- Size: 200 x 200px
- Position: Centered

**App Title:**
- Text: "Papyrus"
- Style: Display Small
- Size: 56px
- Weight: 400
- Color: On Surface (`#1C1B1F`)
- Margin top: 24px

**Tagline:**
- Text: "Your ultimate digital library"
- Style: Title Large
- Size: 20px
- Color: On Surface Variant (`#47464F`)
- Margin top: 8px

**Button Container:**
- Width: 320px
- Centered horizontally
- Margin top: 48px

**Get Started Button:**
- Width: 320px
- Height: 56px
- Background: Primary (`#5654A8`)
- Text: "Get started", 16px, white
- Border radius: 8px
- Hover: Background `#4A489C`

**Sign In Button:**
- Width: 320px
- Height: 56px
- Background: Surface Container (`#E4E1EC`)
- Text: "Sign in", 16px, On Surface
- Border radius: 8px
- Margin top: 16px

**Offline Link:**
- Text: "Use offline mode"
- Color: Primary
- Size: 16px
- Margin top: 16px

---

## Screen 2: Login Page

### Purpose
Centered card-based login form for desktop experience.

### Layout

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│                                                                                 │
│                    ┌─────────────────────────────────────────┐                  │
│                    │                                         │                  │
│                    │         [Logo]  Papyrus                 │                  │
│                    │                                         │                  │
│                    │              Sign in                    │  Card: 480px wide
│                    │                                         │  Padding: 48px
│                    │  Email                                  │
│                    │  ┌─────────────────────────────────┐    │
│                    │  │                            [@]  │    │
│                    │  └─────────────────────────────────┘    │
│                    │                                         │
│                    │  Password                               │
│                    │  ┌─────────────────────────────────┐    │
│                    │  │                            [👁]  │    │
│                    │  └─────────────────────────────────┘    │
│                    │                                         │
│                    │              Forgot password?           │
│                    │                                         │
│                    │  ┌─────────────────────────────────┐    │
│                    │  │           Continue          [→] │    │
│                    │  └─────────────────────────────────┘    │
│                    │                                         │
│                    │  ──────── Or continue with ────────    │
│                    │                                         │
│                    │  ┌─────────────────────────────────┐    │
│                    │  │  [G]  Sign in with Google       │    │
│                    │  └─────────────────────────────────┘    │
│                    │                                         │
│                    │    Don't have an account? Sign up       │
│                    │                                         │
│                    └─────────────────────────────────────────┘                  │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Component Specifications

**Card Container:**
- Width: 480px
- Background: Surface (`#FFFBFF`)
- Border: 1px Outline Variant (`#C8C5D0`)
- Border radius: 16px
- Padding: 48px
- Shadow: Level 1
- Centered in viewport

**Logo + Title Row:**
- Logo: 48 x 48px
- "Papyrus": 24px, inline with logo
- Gap: 12px
- Centered horizontally

**Form Title:**
- Text: "Sign in"
- Size: 32px, Headline Large
- Margin top: 32px
- Margin bottom: 32px

**Email Input:**
- Width: 100% (384px)
- Height: 56px
- Label: "Email"
- Trailing icon: `email`
- Border: 1px Outline
- Focus border: 2px Primary

**Password Input:**
- Width: 100%
- Height: 56px
- Label: "Password"
- Trailing icon: `visibility`
- Margin top: 16px

**Forgot Password:**
- Alignment: Right
- Color: Primary
- Size: 14px
- Margin top: 8px

**Continue Button:**
- Width: 100%
- Height: 56px
- Background: Primary
- Text: "Continue"
- Trailing icon: `arrow_forward`
- Margin top: 24px

**Divider:**
- Full width
- Text: "Or continue with"
- Margin: 24px vertical

**Google Button:**
- Width: 100%
- Height: 56px
- Background: white
- Border: 1px Outline
- Border radius: 28px
- Google logo + "Sign in with Google"

**Sign Up Link:**
- Centered
- "Don't have an account? Sign up"
- "Sign up" in Primary color
- Margin top: 24px

### Hover States

- Buttons: Darken background 10%
- Links: Underline
- Inputs: Border color change to Primary

---

## Screen 3: Register Page

### Layout

Same card layout as Login with:

```
┌─────────────────────────────────────────┐
│                                         │
│         [Logo]  Papyrus                 │
│                                         │
│           Create account                │
│                                         │
│  Email                                  │
│  ┌─────────────────────────────────┐    │
│  │                            [@]  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Password                               │
│  ┌─────────────────────────────────┐    │
│  │                            [👁]  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Confirm password                       │
│  ┌─────────────────────────────────┐    │
│  │                            [👁]  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │           Continue          [→] │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ──────── Or continue with ────────    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  [G]  Sign up with Google       │    │
│  └─────────────────────────────────┘    │
│                                         │
│   Already have an account? Sign in      │
│                                         │
└─────────────────────────────────────────┘
```

### Differences from Login

- Title: "Create account"
- Additional field: "Confirm password"
- Google text: "Sign up with Google"
- Bottom link: "Already have an account? Sign in"

---

## States to Design

### Welcome Page
1. Default
2. Button hover states
3. Button pressed states

### Login Page
1. Empty form
2. Focused input (email)
3. Filled form
4. Invalid email (error state)
5. Invalid password (error state)
6. Loading (Google sign-in)

### Register Page
1. Empty form
2. Password requirements hint
3. Password mismatch error
4. All valid
5. Loading

---

## Figma Generation Instructions

```
CREATE DESKTOP AUTH FLOW SCREENS

Frame 1: Welcome Page (1440 x 900)
- Background: #FFFBFF
- Center all content vertically and horizontally
- Logo: 200x200px placeholder, centered
- "Papyrus": 56px, Display Small, #1C1B1F, centered, 24px below logo
- Tagline: 20px, #47464F, centered, 8px below title
- Button container: 320px wide, 48px below tagline
- Primary button: 320x56px, #5654A8, 8px radius, "Get started" white text
- Secondary button: 320x56px, #E4E1EC, 8px radius, "Sign in" dark text, 16px gap
- Text link: "Use offline mode", #5654A8, 16px gap

Frame 2: Login Page (1440 x 900)
- Background: #FFFBFF
- Card: 480px wide, centered, #FFFBFF fill, 1px #C8C5D0 border, 16px radius, 48px padding
- Logo row: 48px logo + "Papyrus" 24px, centered
- "Sign in": 32px, centered, 32px margin top
- Email input: Full width, 56px, outlined style with email icon
- Password input: Full width, 56px, 16px gap, visibility toggle
- "Forgot password?": Right-aligned, #5654A8, 8px margin top
- Continue button: Full width, 56px, #5654A8, arrow icon, 24px margin top
- Divider with "Or continue with": 24px margins
- Google button: Full width, 56px, white, 1px border, 28px radius, Google logo
- Sign up link: centered, 24px margin top

Frame 3: Register Page (1440 x 900)
- Same card layout as Login
- Title: "Create account"
- Add "Confirm password" field
- Adjust bottom link text

INTERACTION STATES:
- All buttons: Create hover (darker) and pressed variants
- All inputs: Create default, focused (2px #5654A8 border), error (2px #BA1A1A) variants
- Google button: Create loading variant with spinner
```
