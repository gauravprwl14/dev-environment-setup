# Telegram Media Downloader

A modular browser extension for downloading media from the Telegram Web App.

## Features

- Download videos, images, and audio from Telegram Web
- Works with both web.telegram.org/a/ and web.telegram.org/k/ versions
- Progress bar for tracking download status
- Support for stories and media viewer
- Uses the File System Access API when available for better performance

## Project Structure

The project has been refactored following SOLID principles with a focus on modularity and maintainability:

```
├── src/                  # Source code
│   ├── constants/        # Application constants
│   ├── core/             # Core functionality
│   ├── downloaders/      # Media download implementations
│   ├── ui/               # User interface components
│   ├── utils/            # Utility functions
│   └── index.js          # Entry point with Tampermonkey header
├── dist/                 # Compiled output
├── config/               # Configuration files
└── package.json          # Project dependencies
```

### Key Components

- **constants/** - Configuration values and icons
- **core/** - Media detection and DOM observation
- **downloaders/** - Specialized downloaders for different media types
- **ui/** - UI components like progress bars and buttons
- **utils/** - Common utilities for logging, DOM operations, and file handling

## Development

### Prerequisites

- Node.js (v14 or higher)
- npm (v6 or higher)

### Setup

1. Clone the repository
2. Install dependencies:

```bash
npm install
```

### Build

To build the extension:

```bash
npm run build
```

This will generate a `telegram-media-downloader.user.js` file in the `dist` directory.

### Development Mode

For development with hot reloading:

```bash
npm run dev
```

## Installation

1. Install the [Tampermonkey](https://chromewebstore.google.com/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?hl=en) browser extension
2. Open Tampermonkey dashboard
3. Create a new script
4. Open the `dist/telegram-media-downloader.user.js` file
5. Copy and paste the entire content into the Tampermonkey editor
6. Save the script

Alternatively, you can drag and drop the compiled `.user.js` file into your browser with Tampermonkey installed.

## Usage

1. Navigate to [Telegram Web](https://web.telegram.org/)
2. Open any media in the media viewer or story viewer
3. A download button will appear in the interface
4. Click the button to download the media

## License

GNU GPLv3
