# Google Sign-In Setup

Players can register or sign in with a Google account on Android using the [GodotGoogleSignIn](https://github.com/NiqueWrld/GodotGoogleSignIn) plugin (Credential Manager). The plugin returns a Google ID token, which `UserDatabase.register_with_google` exchanges for a Firebase Auth session (`accounts:signInWithIdp`, provider `google.com`). New accounts get a generated username derived from the Google display name (5-15 characters, letters/digits/underscore, a random number is appended on collisions).

Google Sign-In is only available on Android exports that include the plugin. In the editor, on desktop and on iOS the Google button is disabled.

## Project configuration

- `project.godot` → `[google_sign_in] web_client_id`: the **Web application** OAuth client ID (public, ends in `.apps.googleusercontent.com`). Never store the client secret, keystores or private keys in the repository.
- `GoogleSignInService` (`autoload/google_sign_in_service.gd`) reads it and initializes the plugin on the first sign-in.
- The Firebase addon was patched: `login_with_google_id_token` in `addons/godot-firebase/auth/auth.gd` (the stock `login_with_oauth` only sends an access token). Re-apply it after updating the addon.

## Manual setup checklist (consoles and signing)

1. Choose a final Android package name and set it in **Project → Export → Android → Package → Unique Name**. It must match everywhere below.
2. Create a release keystore (kept outside the repo, backed up) and use the debug keystore for testing. Print fingerprints with `keytool -list -v -keystore <file> -alias <alias>`.
3. Firebase Console: add the Android app with the package name and the SHA-1/SHA-256 fingerprints (debug now, release later; add the Play App Signing key too if you use it). `google-services.json` is not needed.
4. Firebase Console → Authentication → Sign-in method: enable **Google**.
5. Google Cloud Console (same project as Firebase): configure the OAuth consent screen / Google Auth Platform and add test users while in testing mode.
6. Credentials: make sure an Android OAuth client exists for each signing key (package name + SHA-1) and a Web application client exists. Use the Web client's ID as `web_client_id`.
7. Authentication → Settings: check the "one account per email" setting.
8. Godot: install the Android build template, enable Gradle build and the GodotGoogleSignIn plugin in the export preset.
9. Test on a real Android device with a Google account and up-to-date Play Services.

Troubleshooting: sign-in cancelled immediately usually means the package name or SHA-1 does not match the Android OAuth client; "no credentials available" means no Google account on the device.

## Emulator testing

The Auth emulator accepts unsigned fake ID tokens, so the Firebase and profile logic can be tested without Google credentials:

```sh
npm run test:google-sign-in
```

The plugin itself (account picker) only runs on a device. Registering against the production Firebase project requires `firebase/runtime_mode="production"` in a release build.
