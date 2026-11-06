# puffpuff saves and purchase restoration

## Available now

- [x] Save the current Bloom pattern, tap budget, used taps, legacy history, and extra taps.
- [x] Keep completed Bloom levels and best recorded move counts.
- [x] Save Glow, shots, cleared obstacles, treasure discoveries, and Pip's position in each cove.
- [x] Resume the selected Bloom or trail screen and the open cove.
- [x] Import earlier prototype saves without deleting their original data.
- [x] Keep the Mac preview sandboxed with the same bundle ID as Xcode builds; the Mac build script verifies the sandbox entitlement to prevent a second save location.
- [x] Use an atomic local save and a previous valid backup; preserve unreadable files for recovery.
- [x] Show local save status in Your saved reef, opened from the puffpuff wordmark.
- [x] Record new free tap refills as prototype rewards, distinct from verified purchases.
- [x] Prepare a StoreKit 2 restore path for permanent purchases. The product catalog is empty, so real purchase restoration is not active yet.

Local saves survive normal app relaunches and updates. They do not currently sync between the Mac preview and iPhone simulator, and deleting the app can remove them.

## iCloud progress sync

- [ ] Configure the intended Apple developer team, bundle identifier, private CloudKit container, and required entitlements with the user's approval.
- [ ] Keep local saves available offline. Use CKSyncEngine for private-database synchronization and persist its synchronization state.
- [ ] Handle sign-in, account changes, connection failures, and unavailable iCloud storage without mixing different players' reefs.
- [ ] Merge completed level and treasure sets. Resolve competing in-progress boards explicitly; never combine two different boards or silently select by the largest level number.
- [ ] Use identified reward and spending events for Glow, shots, and inventory. Do not merge balances by adding them or choosing the larger number; that can duplicate rewards or resurrect spent currency.
- [ ] Exercise conflicts, offline play, reinstall recovery, and simultaneous device use before calling sync ready.

CloudKit requires Apple developer configuration and an iCloud account on the device. [Apple setup requirements](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app) and [CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine-4b4w9).

## Real purchases

- [ ] Define products in App Store Connect and populate the app's product catalog.
- [ ] Restore permanent unlocks from verified StoreKit entitlements; process refunds and revocations. Local cached flags are not proof of purchase.
- [ ] For consumables such as tap packs, durably record each verified transaction ID and grant the inventory exactly once before finishing the transaction.
- [ ] Save unused purchased inventory and consumption events. A restore must not re-grant spent packs; cross-device delivery needs coordinated deduplication before paid consumables go live.
- [ ] Handle pending, cancelled, unverified, interrupted, and refunded transactions.
- [ ] Keep the current purchase/ad buttons free until real commerce and rewarded ads are deliberately enabled.

Apple's current-entitlements sequence excludes consumables. Explicit purchase restoration may ask for App Store authentication, so it belongs behind a user action. [Current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements) and [Restore with AppStore.sync](https://developer.apple.com/documentation/storekit/appstore/sync()).
