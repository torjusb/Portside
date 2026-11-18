# Portside

Portside is a macOS menu bar app written in Swift. It lists every URL that [portless](https://portless.sh) currently serves. It reads the portless state directory and applies the same rules as `portless list`. `README.md` is the user-facing homepage; keep it free of build and release details and put them here.

## Layout

- `Portside/`: the Swift package (`Package.swift`, `Sources/`, `Tests/`). Run package commands from this folder.
- `Portside/scripts/bundle.sh`: builds the `.app`.
- `Portside/scripts/release.sh`: builds the DMG and a signed appcast.
- `Portside/scripts/make-icon.swift`: renders the app icon.
- `Portside/Assets/`: `AppIcon.svg` (source) and `AppIcon.icns` (generated).
- `dummy-projects/`: two Node servers for trying the app against real portless routes.
- `.github/workflows/release.yml`: the `Release` workflow.
- `docs/screenshot.png`: the screenshot in the README.

## Requirements

Swift 6 (Xcode or the command line tools), macOS 15 or later. The dummy projects also need Node.js and portless.

## Build

```sh
cd Portside
scripts/bundle.sh
```

The script builds a universal release binary for Apple silicon and Intel. It writes `Portside/build/Portside.app` with Sparkle embedded, and signs the app ad hoc. It is safe to run again. Set `VERSION` to stamp a version, for example `VERSION=1.2.3 scripts/bundle.sh`. The default is `0.0.0`.

The app is signed ad hoc, not notarized, because notarization needs a paid Apple Developer ID. That is why users must click Open Anyway on first launch.

## Run

```sh
open Portside/build/Portside.app
```

To print the active URLs and exit, run the binary with `--list`. Use this to check behavior without the UI:

```sh
Portside/build/Portside.app/Contents/MacOS/Portside --list
```

Behavior to preserve:

- The menu bar shows a network symbol and the number of active URLs.
- URLs are grouped by project. The project is the label before the TLD, so `klavio-forms.comfort.localhost` is in `comfort`.
- Click opens the URL in the default browser. Option-click copies it.
- The menu updates when portless changes its state files, and also polls every 5 seconds for routes whose process stopped.

## Test

```sh
cd Portside
swift test
```

Run the tests after every code change.

## Try it with the dummy projects

`dummy-projects/` has two small Node servers. `notes-api` returns JSON. `shop-web` returns an HTML page. Each runs its `dev` script through `portless run`.

```sh
dummy-projects/start.sh
curl -sk https://notes-api.localhost
curl -sk https://shop-web.localhost
Portside/build/Portside.app/Contents/MacOS/Portside --list
dummy-projects/stop.sh shop-web
dummy-projects/stop.sh
```

`start.sh` writes process IDs and logs to `dummy-projects/.run/`. `stop.sh` stops only the processes that `start.sh` started; with no arguments it stops both. Both scripts are safe to run more than once.

## App icon

`Portside/Assets/AppIcon.icns` is rendered from `Portside/Assets/AppIcon.svg`. The README also shows the SVG. After you edit the SVG, render the icon again:

```sh
cd Portside
swift scripts/make-icon.swift
```

## Updates (Sparkle)

The app checks for updates once a day with [Sparkle](https://sparkle-project.org), using the GitHub releases. Installed copies find updates through `releases/latest/download/appcast.xml`. Each update is EdDSA-signed, and the app installs an update only if its signature matches the public key in the app.

## Releasing

Releases are cut by the maintainer. Do not push tags unless asked. To publish version 1.2.3:

```sh
git tag v1.2.3
git push origin v1.2.3
```

The `Release` workflow runs the tests and `Portside/scripts/release.sh`. The script builds the app, `Portside.dmg`, and a signed `appcast.xml`. The workflow then creates the GitHub release with both files.

- The EdDSA private key is in the maintainer's login Keychain under the account `no.torjusb.portside`, and in the repository secret `SPARKLE_PRIVATE_KEY`. Never print or commit it.
- To build a release locally, run `VERSION=1.2.3 scripts/release.sh` from `Portside/`. The script reads the key from the Keychain.
- The workflow also runs on pull requests with version `0.0.0` and publishes nothing. Pull requests from forks fail at the signing step because they cannot read the secret; that is expected.
- To test an update without GitHub, set `SU_FEED_URL` to a local appcast URL and `DOWNLOAD_URL_PREFIX` to the folder that serves the DMG, then run `release.sh`.
