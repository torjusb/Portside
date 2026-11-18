# Portside

Portside is a macOS menu bar app. It lists every URL that [portless](https://portless.sh) currently serves. It reads the portless state directory and applies the same rules as `portless list`.

<img src="docs/screenshot.png" alt="The Portside dropdown listing four URLs grouped by project" width="345">

## Install

Portside needs macOS 15 or later, and [portless](https://portless.sh) with its proxy running.

1. Download `Portside.dmg` from the [latest release](https://github.com/torjusb/Portside/releases/latest).
2. Open the DMG and drag Portside to the Applications folder.
3. Open Portside from the Applications folder. macOS blocks it the first time.
4. Open System Settings, then Privacy & Security. Find the message about Portside and click Open Anyway.

macOS blocks the first launch because the app is not notarized. Notarization requires a paid Apple Developer ID. The app is signed ad hoc instead. You do this step once.

To start Portside when you log in, select Launch at Login in the menu.

## Updates

Portside checks for updates once a day. It uses [Sparkle](https://sparkle-project.org) and the releases on GitHub. To check now, select Check for Updates in the menu. Each update is signed, and Portside installs an update only if its signature matches the key in the app. The menu shows the version you run.

## Build from source

You need Swift 6 (Xcode or the command line tools). The dummy projects also need Node.js.

```sh
cd Portside
scripts/bundle.sh
```

The script builds a universal release binary for Apple silicon and Intel. It writes `Portside/build/Portside.app` with Sparkle embedded, and signs the app ad hoc. You can run it again at any time. Set `VERSION` to stamp a version, for example `VERSION=1.2.3 scripts/bundle.sh`. The default is `0.0.0`.

The app icon is `Portside/Assets/AppIcon.icns`. To render it again, run `swift scripts/make-icon.swift` from the `Portside` folder.

## Run

```sh
open "Portside/build/Portside.app"
```

The menu bar shows a network symbol and the number of active URLs. The menu groups URLs by project. The project is the label before the TLD, so `klavio-forms.comfort.localhost` is in `comfort`. Click a URL to open it in your default browser. Hold Option to copy the URL instead. The menu updates when portless changes its state files. It also checks every 5 seconds for routes whose process stopped.

To print the active URLs and exit, run the binary with `--list`:

```sh
"Portside/build/Portside.app/Contents/MacOS/Portside" --list
```

## Test

```sh
cd Portside
swift test
```

## Releasing

To publish version 1.2.3, tag the commit and push the tag:

```sh
git tag v1.2.3
git push origin v1.2.3
```

The `Release` workflow runs the tests and `Portside/scripts/release.sh`. The script builds the app, `Portside.dmg`, and a signed `appcast.xml`. The workflow then creates the GitHub release with both files. Installed copies find the update through `releases/latest/download/appcast.xml`.

The EdDSA private key that signs updates is in the maintainer's login Keychain, under the account `no.torjusb.portside`. The same key is the repository secret `SPARKLE_PRIVATE_KEY`. To build a release locally, run `VERSION=1.2.3 scripts/release.sh` from the `Portside` folder. The script reads the key from the Keychain. The workflow also runs on pull requests, with version `0.0.0`, and does not publish anything. Pull requests from forks fail at the signing step, because they cannot read the secret.

To test an update without GitHub, set `SU_FEED_URL` to a local appcast URL and `DOWNLOAD_URL_PREFIX` to the folder that serves the DMG, then run `release.sh`.

## Try it with the dummy projects

The `dummy-projects` folder has two small Node servers. `notes-api` returns JSON. `shop-web` returns an HTML page. Each one runs its `dev` script through `portless run`.

```sh
dummy-projects/start.sh
curl -sk https://notes-api.localhost
curl -sk https://shop-web.localhost
"Portside/build/Portside.app/Contents/MacOS/Portside" --list
dummy-projects/stop.sh shop-web
dummy-projects/stop.sh
```

`start.sh` writes process IDs and logs to `dummy-projects/.run/`. `stop.sh` stops only the processes that `start.sh` started. With no arguments it stops both projects. Both scripts are safe to run more than once.
