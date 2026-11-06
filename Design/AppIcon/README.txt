Puff Puff app icon

Official puffed-up artwork from Design/PuffPuff/PuffPuff-Official.af, via the imported PipPaths.swift contours.
Lagoon water background, no lettering.

PuffPuff-App-Icon.png: 1024-pixel opaque iOS/marketing master.
PuffPuff-Icon-Preview.png: 512-pixel Mac-style preview.
App resources: puffpuff/Assets.xcassets/AppIcon.appiconset.

To regenerate from the project directory:
xcrun swiftc -parse-as-library puffpuff/Art/PipPaths.swift scripts/make-app-icon.swift -o /tmp/puffpuff-icon-export
/tmp/puffpuff-icon-export .
