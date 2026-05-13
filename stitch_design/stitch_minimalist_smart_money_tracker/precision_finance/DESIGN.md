---
name: Precision Finance
colors:
  surface: '#faf9fe'
  surface-dim: '#dad9df'
  surface-bright: '#faf9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f8'
  surface-container: '#eeedf3'
  surface-container-high: '#e9e7ed'
  surface-container-highest: '#e3e2e7'
  on-surface: '#1a1b1f'
  on-surface-variant: '#3e4a3f'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f1f0f5'
  outline: '#6e7a6e'
  outline-variant: '#bdcabc'
  surface-tint: '#006d36'
  primary: '#006a34'
  on-primary: '#ffffff'
  primary-container: '#078644'
  on-primary-container: '#f6fff3'
  inverse-primary: '#72dc90'
  secondary: '#006d37'
  on-secondary: '#ffffff'
  secondary-container: '#6bfe9c'
  on-secondary-container: '#00743a'
  tertiary: '#9f384b'
  on-tertiary: '#ffffff'
  tertiary-container: '#be5063'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8ef9aa'
  primary-fixed-dim: '#72dc90'
  on-primary-fixed: '#00210c'
  on-primary-fixed-variant: '#005227'
  secondary-fixed: '#6bfe9c'
  secondary-fixed-dim: '#4ae183'
  on-secondary-fixed: '#00210c'
  on-secondary-fixed-variant: '#005228'
  tertiary-fixed: '#ffd9dc'
  tertiary-fixed-dim: '#ffb2bb'
  on-tertiary-fixed: '#400011'
  on-tertiary-fixed-variant: '#832237'
  background: '#faf9fe'
  on-background: '#1a1b1f'
  surface-variant: '#e3e2e7'
typography:
  display-financial:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  margin-screen: 16px
  gutter-card: 12px
---

## Brand & Style

The design system is anchored in the concept of "Quiet Confidence." It is designed for an Android audience that values automation, clarity, and reliability in their financial journey. The brand personality is professional yet accessible, avoiding the coldness of traditional banking for a more human-centric, "smart assistant" feel.

The visual style is **Corporate Modern with a Minimalist execution**. It leverages high-quality whitespace to reduce cognitive load during financial decision-making. By combining a "Flat Plus" approach—mostly flat surfaces with extremely subtle elevation—the UI feels grounded and tactile without being distracting. The aesthetic prioritizes data legibility and effortless navigation, ensuring that the "Automatic" brand promise is felt through every interaction.

## Colors

The palette is strategically split between brand identity and functional status signaling. 

- **Primary Green (#1B8F4C):** Used for primary actions, brand moments, and active states to instill a sense of growth and stability.
- **Functional Accents:** Income is represented by a vibrant **#2ECC71**, while Expenses/Alerts use **#FF5A5F**. These are used sparingly to maintain high visual impact.
- **Surface & Background:** A soft **#F7F8FA** background differentiates the canvas from the content, while **#FFFFFF** cards create a clear container system.
- **Typography:** Deep Charcoal (**#1C1C1E**) provides maximum contrast for readability, supported by a mid-tone Grey (**#8E8E93**) for metadata and secondary information.

## Typography

The design system utilizes **Manrope** for headings and financial data to provide a modern, balanced geometric feel that remains professional. **Inter** is utilized for body copy and UI labels due to its exceptional legibility on mobile screens.

Financial data is treated as the "Hero" of the interface. Large balances and transaction amounts use the `display-financial` style with tighter letter spacing to feel solid and significant. Captions and small labels use an uppercase treatment with slight tracking to differentiate them from body text.

## Layout & Spacing

The layout follows a **Fluid Grid** model optimized for Android handheld devices. It utilizes a 4-column structure for mobile, with a standard **16px side margin**. 

Spacing follows a 4px baseline grid to ensure a rhythmic vertical flow. Elements within cards should maintain a consistent **16px (md)** padding, while the vertical gap between cards is typically **12px (sm)** to keep related financial modules grouped but distinct. Whitespace is used aggressively between different functional sections (e.g., between the Header/Balance and the Transaction List) to prevent the UI from feeling cluttered.

## Elevation & Depth

This design system employs **Ambient Shadows** to create a sense of depth without looking "heavy." 

- **Level 0 (Background):** The #F7F8FA base layer.
- **Level 1 (Cards):** White surfaces with a soft, diffused shadow (Y: 4, Blur: 12, Opacity: 4% Black). This creates a subtle lift that distinguishes cards from the background.
- **Level 2 (Active/Floating):** Used for Bottom Sheets and Primary Action Buttons. These use a more pronounced shadow (Y: 8, Blur: 20, Opacity: 8% Black) to indicate they are closer to the user.
- **Tonal Separation:** In place of heavy borders, the system uses the contrast between #F7F8FA and #FFFFFF to define boundaries.

## Shapes

The shape language is defined by **Rounded (Level 2)** containers. Standard cards and input fields utilize a **12px corner radius**, while larger container blocks or prominent banners can scale up to **16px**.

Small UI elements like Chips or Tags should utilize a fully rounded "Pill" shape to distinguish them from interactive buttons. This variety in radius ensures a friendly, modern appearance while maintaining the structured feel required for a financial app.

## Components

### Buttons
- **Primary:** Solid #1B8F4C with white text. 12px rounded corners.
- **Secondary:** Transparent background with #1B8F4C border or light green tint.
- **Floating Action Button (FAB):** Circular, #1B8F4C, containing a single white "+" icon for "Add Transaction."

### Cards
- **Transaction Card:** White background, 12px radius, minimal shadow. Left-aligned icon (category), center-aligned text (description/date), and right-aligned amount (bold).
- **Summary Card:** High-contrast background (Primary Green) used for the main account balance to draw immediate attention.

### Input Fields
- Understated design with a 1px border (#E5E5EA) and 12px radius. On focus, the border thickens to 2px and changes to the Primary Green.

### Chips & Filters
- Used for category selection (e.g., "Food," "Rent"). Pill-shaped with a light grey background, moving to a Primary Green fill when selected.

### Data Visualizations
- Progress bars for budgets should be 8px thick with rounded caps. Use the Accent Red for "Over Budget" and Primary Green for "On Track."