# Dungeon Android wrapper

Package/application ID: `ltseverydayyou.dungeon`

The app is a WebView wrapper around `https://ltseverydayyou.github.io/`. Because it loads the live GitHub Pages site, changes to the root `index.html` appear in the app without requiring users to reinstall the APK.

The GitHub Actions workflow also rebuilds and publishes an APK whenever `index.html`, the Android project, or the workflow itself changes.

## Durable release signing

For Android to accept future native APK builds as updates, configure these repository Actions secrets:

- `DUNGEON_KEYSTORE_B64` — base64 of the release `.jks`/`.keystore`
- `DUNGEON_KEYSTORE_PASSWORD`
- `DUNGEON_KEY_ALIAS`
- `DUNGEON_KEY_PASSWORD`

When all four are present, CI publishes a release-signed APK. Until then, CI uses a cached debug signing key so the APK is installable. The cached key is suitable for testing/personal distribution but is not a durable production signing strategy.


## Android settings

The APK settings button now includes the same navigation and update actions as the Windows hub, plus mobile-friendly controls for sharing the current page, clearing the WebView cache, viewing app/build information, and switching between the available launcher icons.
