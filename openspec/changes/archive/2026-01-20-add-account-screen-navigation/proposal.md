# Change: Add Account Screen Navigation Logic

## Why
The main lobby screen, register/login screen, and account management screen exist as separate .tscn files but lack navigation logic to connect them together. Players need a cohesive flow to access account features from the main lobby based on their login state.

## What Changes
- Create `main_lobby_screen.gd` to handle AccountButton press and user state detection
- Add conditional navigation: AccountButton opens register/login screen if user is not logged in, or account management screen if logged in
- Connect BackButton in register/login and account management screens to return to main lobby
- Connect NewAccountButton in register/login screen to navigate to account registration screen
- Implement navigation using TransitionManager for consistent fade effects
- Add error handling that returns to main lobby and logs errors to console on navigation failures

## Impact
- **Affected specs**: main-lobby-screen (new), register-login-screen (new), account-management-screen (new)
- **Affected code**: 
  - New: `scenes/ui/main_lobby_screen.gd`
  - Modified: `scenes/ui/main_lobby_screen.tscn` (attach script)
  - Modified: `scenes/ui/account_ui/register_login_screen.tscn` (if script attachment needed)
  - Modified: `scenes/ui/account_ui/account_management_screen.tscn` (if script attachment needed)
- **Dependencies**: UserDatabase autoload (existing), TransitionManager autoload (existing)
