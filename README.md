
<a href="https://karolis-1.gitbook.io/papyrus-project/"><img src="https://img.shields.io/badge/GitBook-Specification-%232F2F2F.svg?logo=gitbook&logoColor=white&labelColor=%23307f98"/></a>
<a href="https://discord.gg/PHAAZZBS"><img src="https://img.shields.io/badge/Discord-Chat-%232F2F2F.svg?logo=discord&logoColor=white&labelColor=%235865F5"/></a>
<a href="https://trello.com/invite/b/681367b2ba91db4e40b0cfea/ATTI5156837607437467bd3d646f933528054D126F02/papyrus"><img src="https://img.shields.io/badge/Trello-Board-%232F2F2F.svg?logo=trello&logoColor=white&labelColor=%230055CC"/></a>
___

<div align="center">
  <img width="300" src="/public/img/logo-dark.svg#gh-dark-mode-only" alt="papyrus">
  <img width="300" src="/public/img/logo-light.svg#gh-light-mode-only" alt="papyrus">
  <p align="center"> A cross-platform book management system. </p>
</div>

___

## Table of contents
- [Overview](#overview)
  - [Why?](#why)
  - [Key features](#key-features)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Project resources](#project-resources)
- [Contributing](#contributing)
- [Contact](#contact)

## Overview
Papyrus aims to provide a versatile, easy-to-use system that makes reading comfortable and fun. It's designed to be accessible on a wide range of platforms, including Android, iOS, Web, and Desktop, featuring an intuitive, modern UI with various customization options. You can find more information in the specification [here](https://karolis-1.gitbook.io/papyrus-project/).

### Why?
Many solutions offer some reading functionalities but fall short on some essential features or user experience. Papyrus aims to deliver a comprehensive solution that balances functionality with good user experience, covering all your reading needs in one application.

### Key Features
* **Cross-platform**: manage physical and electronic books seamlessly across devices.
 Integrated e-book viewer: customize your reading experience with various look-and-feel options.
* **Flexible management**: organize physical and e-books into shelves, categories, attach tags, create custom filters.
* **Progress tracking**: track reading time and books read, plan and create custom reading goals.
* **Storage**: easily add new books, convert and export books files, choose file storage methods.

## Getting started
### Prerequisites
- **Flutter SDK:** Ensure you have [Flutter installed](https://flutter.dev/docs/get-started/install).  
- **Dart SDK:** This is included when you install Flutter.

### Installation
1. Clone the repository
 ```bash
 git clone git@github.com:Eoic/Papyrus.git
 cd Papyrus
 ```
2. Install dependencies
 ```bash
 flutter pub get
 ```
3. Run the application

   **Mobile (Android / iOS)**
   Connect your device or start an emulator and run:
   ```bash
   flutter run
   ```

   **Web**
   Run the following command to launch Papyrus in Chrome (or another supported browser):
   ```bash
   flutter run -f chrome
   ```

   **Desktop**
   Make sure desktop support is enabled by referring to Flutter desktop setup page. Then run:
   ```bash
   flutter run -d windows  # or -d macos, -d linux
   ```

## Project resources
* **API Specification**: the backend REST API is documented using OpenAPI specification. You can find the current OpenAPI spec in the [design/api](./design/api/) directory.
* **Design Prototype**: the UI/UX design is created in Figma, and you can find it [here](https://www.figma.com/design/nnL41KQvrlVU4ecF8mtB07/Papyrus?node-id=0-1&t=2x3bT0cacWbQsPdy-1).

## Contributing
Follow the steps to submit your contributions:
1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout b feature/<your-feature>
   ```
3. Commit your changes:
   ```bash
   git commit -m "<description of your changes>"
   ```
4. Push to your branch:
   ```bash
   git push origin feature/<your-feature>
   ```
5. Open a pull request.

## Contact
For any questions, feedback, or suggestions, please contact:
- **Project Maintainer:** [Karolis Strazdas](mailto:karolis.strazdas@pm.me)
