# GoldDesk

GoldDesk is a focused XAUUSD chart-review workspace for macOS and the web. It
puts an OANDA XAUUSD 15-minute TradingView chart beside quick access to ChatGPT
while keeping all trading actions manual.

GoldDesk does not connect to a broker, place orders, close positions, or modify
live or demo trades. It is a workspace utility, not financial advice.

## What is included

- A responsive web app and installable iPhone home-screen experience
- A native SwiftUI macOS launcher for the official ChatGPT/Codex and TradingView apps
- Automatic side-by-side window arrangement on macOS after Accessibility permission is granted
- A reusable safety-focused starter prompt for chart-marking requests
- A small rendered-page test suite

## Web app

Requirements: Node.js 22.13 or newer.

```bash
npm install
npm run dev
```

Open the local address printed by the development server. To verify a production
build, run:

```bash
npm test
```

The checked-in `.openai/hosting.json` contains a placeholder project ID. Replace
it with your own Sites project ID only when deploying your own copy.

## macOS app

Requirements: macOS 13 or newer, Swift 5.9 or newer, the official ChatGPT/Codex
desktop app, and TradingView Desktop.

```bash
cd MacApp
swift build -c release
```

See [MacApp/README.md](MacApp/README.md) for first-launch instructions.

## Privacy and permissions

GoldDesk does not collect account credentials. The native app opens the official
desktop applications and relies on their existing sessions. macOS Accessibility
permission is used only to resize and position their windows.

The web version embeds TradingView's public chart widget and links to external
services. Those services apply their own privacy policies and terms.

## Contributing

Bug reports and focused improvements are welcome. Please keep broker execution
and automatic trade placement outside this project.

## License

GoldDesk's original source code is available under the [MIT License](LICENSE).
Third-party packages, services, names, and assets remain subject to their own
licenses and terms.

GoldDesk is an independent project and is not affiliated with or endorsed by
OpenAI, ChatGPT, Codex, TradingView, OANDA, or their respective owners.
