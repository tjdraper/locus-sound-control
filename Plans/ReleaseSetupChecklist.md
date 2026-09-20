# Release Setup Checklist

Slice 1 is built except for the credentials and hosting, which only an account holder can set up. Work through this once, then `Scripts/release.sh <version>` handles every release.

Background and commands for each step are in [`Scripts/README.md`](../Scripts/README.md).

## Signing

- [ ] Confirm the **Developer ID Application** certificate is present: `security find-identity -v -p codesigning` lists `Developer ID Application: … (CQZ49H6WAK)`. It is per team, so the one Locus Launcher uses covers this app too.
- [ ] Create a **Developer ID provisioning profile** by archiving once in Xcode: Product → Archive, then Distribute App → Direct Distribution. The app already carries the iCloud key-value storage entitlement slice 7 needs, and a Developer ID build can only carry it with a profile. `xcodebuild` cannot create one from the command line.

## Notarization

- [ ] Create an App Store Connect API key: App Store Connect → Users and Access → Integrations → Team Keys → **+**, role **Developer**. Download the `.p8` (one download only).
- [ ] Note the Key ID and the Issuer ID from that page.
- [ ] Store the credentials in the Keychain under the name the script expects:
      ```
      xcrun notarytool store-credentials "LocusSoundControl" \
        --key ~/Downloads/AuthKey_XXXXXXXX.p8 \
        --key-id XXXXXXXX \
        --issuer <issuer-uuid>
      ```
- [ ] Confirm it works: `xcrun notarytool history --keychain-profile "LocusSoundControl"`.
- [ ] Delete the `.p8` from Downloads.

## Sparkle signing key

This app shares Locus Launcher's key. Sparkle's own guidance is one key per publisher, not per app, and `generate_keys` reuses the existing one anyway unless told to use a different `--account`.

- [ ] Print the public half: `Scripts/sparkle-tools.sh generate_keys -p`.
- [ ] Put it in `LocusSoundControl/SupportingFiles/Info.plist` as `SUPublicEDKey`. **Nothing can update until this is there**, and it has to be in the build before the first release ships.
- [ ] Nothing to back up — the private half is the one already saved during Locus Launcher's setup.

## Hosting

- [ ] Make the repo public at `tjdraper/locus-sound-control`.
- [ ] Enable GitHub Pages: repo Settings → Pages → Source **Deploy from a branch**, branch `main`, folder `/docs`.
- [ ] Commit and push `docs/` so Pages has something to serve. The seeded `appcast.xml` is an empty channel, which is what Sparkle should see before the first release.
- [ ] Confirm `https://tjdraper.github.io/locus-sound-control/appcast.xml` loads. That URL is the `SUFeedURL` baked into every build, so it has to work before the first release ships.
- [ ] Run the app and pick **Check for Updates…**. Against the empty feed it should say you are up to date. An error here means the feed URL is wrong, and it is much cheaper to find out now.

## First release

- [ ] `Scripts/release.sh 2026.0.1`
- [ ] Run the two commands it prints, in the order it prints them.
- [ ] Download the published zip on a Mac that has never run the app, unzip it in Downloads, and open it. You should get no Gatekeeper warning, and the offer to move it to Applications.
- [ ] Ship a throwaway `2026.0.2` and let an installed `2026.0.1` update itself. Sparkle problems only show up on the second release, so do this before anyone else is relying on it.

## Not set up on purpose

- **Release notes** are required. Write `docs/LocusSoundControl-<version>.md` before running the script. That one file becomes the Sparkle update description and the GitHub release body.
- **Publishing** is not automated. The script stops with the artifacts built and prints the `gh release create` and `git` commands, so nothing goes public without you running it.
- **The beta channel** works, but has no UI yet. Opt in with `defaults write com.buzzingpixel.LocusSoundControl ReceiveBetaUpdates -bool YES`; the Settings toggle is slice 8. A build that is itself a beta receives the next beta without opting in.
