<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

## Golden (snapshot) tests

Golden tests rasterize differently on macOS vs the Linux CI runner, so goldens
are generated and verified inside a pinned Linux Flutter image
(`ghcr.io/adrianjagielak/flutter:3.44.2`, matching [flutter-version.txt](flutter-version.txt)).
CI runs inside that same image, and locally you use the same image via Docker
(forced to `linux/amd64`) so the pixels match byte-for-byte.

Requires Docker (Docker Desktop or Colima). From the repo root:

```bash
# Verify goldens the same way CI does
scripts/containerised_test.sh

# Regenerate goldens after an intentional visual change, then commit them
scripts/containerised_test.sh --update-goldens
```

On failure, CI uploads the diff images (`*_masterImage.png`, `*_testImage.png`,
`*_isolatedDiff.png`, `*_maskedDiff.png`) as a `golden-failures` artifact on the
workflow run.
