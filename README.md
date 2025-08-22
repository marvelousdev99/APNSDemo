### APNS (macOS menu bar app)

A minimal macOS background app that registers for APNs, receives remote pushes, and shows system notifications.

### Requirements
- Xcode 15+
- macOS 13+
- Apple Developer account with Push Notifications capability

### Project generation
This repo uses XcodeGen. Install it:

```bash
brew install xcodegen
```

Generate the Xcode project:

```bash
cd APNS
xcodegen generate
open APNS.xcodeproj
```

### Capabilities
Enable in the target's Signing & Capabilities:
- Push Notifications
- App Sandbox (default)
- User Notifications

Ensure `APNS.entitlements` contains:
- `com.apple.developer.aps-environment` set to `development` or `production`

### APNs token
On first launch, the app requests notification permission and APNs registration.
- The device token prints to the Xcode console.
- Use the menu bar "Copy Device Token" to get it later.

### Testing a push
Use `apns-push` or curl-based tools. Example with `node-apn` or `pusher` not shown here. Example HTTP/2 with token-based auth:

- Use your Team ID, Key ID, and `.p8` key file.
- Bundle ID must match `PRODUCT_BUNDLE_IDENTIFIER`.

### Background behavior
The app sets `LSUIElement = true`, so it runs in the menu bar only and does not appear in the Dock.

### Notes
- For production, switch `com.apple.developer.aps-environment` to `production` in `APNS.entitlements` or use separate build configurations.
- APNs payload must include `"aps"` object. Example:

```json
{
  "aps": { "alert": { "title": "Hello", "body": "World" }, "sound": "default" },
  "message": "Optional free-form field"
}
``` 