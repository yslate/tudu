# tudu

A tiny todo list for macOS. The window is tinted glass, you pick the color,
how opaque it is and how much the desktop behind it gets blurred.

Needs macOS 26.

## Build

Open `tudu.xcodeproj` in Xcode and hit run. The project is generated from
`project.yml`, so after changing that run `xcodegen`.

From the terminal, without a signing team:

    xcodebuild -scheme tudu -derivedDataPath build CODE_SIGN_IDENTITY=- build
