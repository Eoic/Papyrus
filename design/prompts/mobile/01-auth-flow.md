# Authentication Flow - Mobile

Self-contained design prompt for Welcome, Login, and Register screens on mobile.

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

---

## Screen 1: Welcome Page

### Purpose
First-time user entry point presenting brand identity and authentication options.

### User Entry Points
- App launch (first time)
- Logout action
- Session expiration

### Layout (390 x 844 viewport)

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│              (Spacer)                   │
│                                         │
│         ┌─────────────────┐             │
│         │                 │             │
│         │   [Logo PNG]    │             │  150 x 150px
│         │                 │             │
│         └─────────────────┘             │
│                                         │
│              Papyrus                    │  48px, headlineLarge
│                                         │
│     Your ultimate digital library       │  16px, bodyMedium
│                                         │
│              (Spacer)                   │
│                                         │
├─────────────────────────────────────────┤
│  Padding: 26px horizontal, 12px vertical│
│  ┌─────────────────────────────────┐    │
│  │         Get started             │    │  Primary button
│  └─────────────────────────────────┘    │
│           (16px spacing)                │
│  ┌─────────────────────────────────┐    │
│  │           Sign in               │    │  Secondary button
│  └─────────────────────────────────┘    │
│           (16px spacing)                │
│         Use offline mode                │  Text button
│                                         │
├─────────────────────────────────────────┤
│           Safe Area (34px)              │
└─────────────────────────────────────────┘
```

### Component Specifications

**Logo:**
- Image: `assets/images/logo.png`
- Size: 150 x 150px
- Position: Centered horizontally
- Margin bottom: 16px

**App Title:**
- Text: "Papyrus"
- Style: Headline Large
- Size: 48px
- Weight: 400
- Color: On Surface (`#1C1B1F`)
- Alignment: Center

**Tagline:**
- Text: "Your ultimate digital library"
- Style: Body Medium
- Size: 16px
- Weight: 400
- Color: On Surface (`#1C1B1F`)
- Alignment: Center
- Margin top: 8px

**Get Started Button (Primary):**
- Type: Filled Button
- Width: Full width (390 - 52 = 338px)
- Height: 50px
- Background: Primary (`#5654A8`)
- Text: "Get started"
- Text color: On Primary (`#FFFFFF`)
- Text size: 16px (Title Medium)
- Border radius: 8px
- Elevation: Level 1

**Sign In Button (Secondary):**
- Type: Elevated Button
- Width: Full width (338px)
- Height: 50px
- Background: Surface Container High
- Text: "Sign in"
- Text color: On Surface (`#1C1B1F`)
- Text size: 16px
- Border radius: 8px
- Elevation: Level 1

**Offline Mode Link:**
- Type: Text Button
- Text: "Use offline mode"
- Text color: Primary (`#5654A8`)
- Text size: 16px
- Alignment: Center

### States to Design

1. **Default** - As described above
2. **Button Pressed** - "Get started" with darker background (`#4A489C`)

---

## Screen 2: Login Page

### Purpose
Authenticate existing users with email/password or Google OAuth.

### User Entry Points
- "Sign in" button from Welcome
- Deep link to login
- Session timeout redirect

### Layout

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│  [←]                                    │  Back button (48px touch)
├─────────────────────────────────────────┤
│                                         │
│         ┌───────────────┐               │
│         │   [Logo]      │               │  80 x 80px
│         └───────────────┘               │
│              Papyrus                    │  24px, headlineMedium
│                                         │
│             Sign in                     │  28px, headlineMedium
│                                         │  Margin top: 32px
├─────────────────────────────────────────┤
│  Padding: 24px horizontal               │
│                                         │
│  Email                                  │  Label, 12px
│  ┌─────────────────────────────────┐    │
│  │ your@email.com            [@]  │    │  Input, 56px height
│  └─────────────────────────────────┘    │
│           (16px spacing)                │
│  Password                               │
│  ┌─────────────────────────────────┐    │
│  │ ••••••••                  [👁]  │    │  Input, 56px height
│  └─────────────────────────────────┘    │
│                                         │
│         Forgot password?                │  Text button, right-aligned
│           (24px spacing)                │
│  ┌─────────────────────────────────┐    │
│  │         Continue            [→]│    │  Primary button
│  └─────────────────────────────────┘    │
│           (24px spacing)                │
│  ─────────── Or continue with ─────────│  Divider with text
│           (24px spacing)                │
│  ┌─────────────────────────────────┐    │
│  │  [G]  Sign in with Google       │    │  Google button
│  └─────────────────────────────────┘    │
│           (32px spacing)                │
│    Don't have an account? Sign up       │  Text link
│                                         │
└─────────────────────────────────────────┘
```

### Component Specifications

**Header Section:**
- Logo: 80 x 80px, centered
- "Papyrus": 24px, Headline Medium, centered
- "Sign in": 28px, Headline Medium, centered, margin-top 32px

**Email Input:**
- Type: Outlined Text Field
- Height: 56px
- Border: 1px Outline (`#787680`)
- Border radius: 4px
- Label: "Email" (floating)
- Placeholder: "your@email.com"
- Trailing icon: `email` (24px)
- Input text: 16px, Body Large

**Password Input:**
- Type: Outlined Text Field
- Height: 56px
- Border: 1px Outline (`#787680`)
- Border radius: 4px
- Label: "Password"
- Input: Obscured (bullets)
- Trailing icon: `visibility` / `visibility_off` (24px, toggleable)

**Forgot Password Link:**
- Text: "Forgot password?"
- Color: Primary (`#5654A8`)
- Size: 14px
- Alignment: Right
- Touch target: 44px height

**Continue Button:**
- Width: Full width (342px)
- Height: 50px
- Background: Primary (`#5654A8`)
- Text: "Continue"
- Trailing icon: `arrow_forward` (20px)
- Border radius: 8px

**Divider:**
- Line: 1px, Outline Variant (`#C8C5D0`)
- Text: "Or continue with"
- Text size: 14px, Title Small
- Text color: On Surface Variant

**Google Sign-In Button:**
- Width: Full width
- Height: 50px
- Background: Surface (`#FFFBFF`)
- Border: 1px, Outline (`#787680`)
- Border radius: 40px (pill)
- Leading icon: Google logo (24px)
- Text: "Sign in with Google"
- Text color: On Surface

**Sign Up Link:**
- Text: "Don't have an account? "
- Link text: "Sign up"
- Link color: Primary (`#5654A8`)
- Alignment: Center

### States to Design

1. **Empty** - All fields empty, Continue disabled
2. **Filled** - Fields populated, Continue enabled
3. **Error** - Invalid email format, red border + error message
4. **Loading** - Google button shows spinner

---

## Screen 3: Register Page

### Purpose
Create new user accounts with email/password or Google OAuth.

### Layout

```
┌─────────────────────────────────────────┐
│           Status Bar (47px)             │
├─────────────────────────────────────────┤
│  [←]                                    │
├─────────────────────────────────────────┤
│                                         │
│         ┌───────────────┐               │
│         │   [Logo]      │               │  80 x 80px
│         └───────────────┘               │
│              Papyrus                    │
│                                         │
│            Create account               │  28px, headlineMedium
│                                         │
├─────────────────────────────────────────┤
│  Padding: 24px horizontal               │
│                                         │
│  Email                                  │
│  ┌─────────────────────────────────┐    │
│  │                            [@]  │    │
│  └─────────────────────────────────┘    │
│           (16px spacing)                │
│  Password                               │
│  ┌─────────────────────────────────┐    │
│  │                            [👁]  │    │
│  └─────────────────────────────────┘    │
│           (16px spacing)                │
│  Confirm password                       │
│  ┌─────────────────────────────────┐    │
│  │                            [👁]  │    │
│  └─────────────────────────────────┘    │
│           (24px spacing)                │
│  ┌─────────────────────────────────┐    │
│  │         Continue            [→]│    │
│  └─────────────────────────────────┘    │
│           (24px spacing)                │
│  ─────────── Or continue with ─────────│
│           (24px spacing)                │
│  ┌─────────────────────────────────┐    │
│  │  [G]  Sign up with Google       │    │
│  └─────────────────────────────────┘    │
│           (32px spacing)                │
│    Already have an account? Sign in     │
│                                         │
└─────────────────────────────────────────┘
```

### Component Specifications

Same as Login with these differences:

**Title:** "Create account" instead of "Sign in"

**Additional Field - Confirm Password:**
- Same styling as Password field
- Label: "Confirm password"

**Validation:**
- Email: Valid email format required
- Password: Minimum 8 characters
- Confirm: Must match password

**Google Button Text:** "Sign up with Google"

**Bottom Link:** "Already have an account? Sign in"

### States to Design

1. **Empty** - All fields empty
2. **Filling** - Some fields populated
3. **Password Mismatch** - Error on confirm field
4. **Valid** - All fields valid, button enabled
5. **Loading** - Submitting registration

---

## Figma Generation Instructions

```
CREATE MOBILE AUTH FLOW SCREENS

Frame 1: Welcome Page
- Frame: 390 x 844px, background #FFFBFF
- SafeArea: 47px top, 34px bottom
- Content: Centered column layout
- Logo placeholder: 150x150px rounded rectangle
- Title "Papyrus": 48px, #1C1B1F, centered
- Subtitle: 16px, #1C1B1F, centered
- Button container: 26px horizontal padding, 12px vertical padding
- Primary button: Full width, 50px height, #5654A8 fill, 8px radius, "Get started" in white
- Secondary button: Full width, 50px height, #E4E1EC fill, 8px radius, "Sign in" in #1C1B1F
- Text button: "Use offline mode" in #5654A8

Frame 2: Login Page
- Frame: 390 x 844px, background #FFFBFF
- Back arrow: Top left, 48x48px touch target
- Logo: 80x80px, centered
- "Papyrus": 24px centered
- "Sign in": 28px centered, 32px margin top
- Form container: 24px horizontal padding
- Email input: 56px height, 1px #787680 border, 4px radius, email icon trailing
- Password input: 56px height, 1px #787680 border, 4px radius, visibility icon trailing
- "Forgot password?": Right-aligned, #5654A8
- Continue button: Full width, 50px, #5654A8, arrow icon trailing
- Divider: Line with "Or continue with" text
- Google button: Full width, 50px, white fill, 1px #787680 border, 40px radius, Google logo + text
- Sign up link: Centered, "Sign up" in #5654A8

Frame 3: Register Page
- Same as Login with:
- Title: "Create account"
- Third input field: "Confirm password"
- Google button text: "Sign up with Google"
- Bottom link: "Already have an account? Sign in"

VARIANTS:
- Create hover/pressed states for all buttons
- Create error states for inputs (2px #BA1A1A border)
- Create loading state for Google button (spinner replacing text)
```
