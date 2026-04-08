# Stirling PDF — Flatpak Package

Flatpak packaging for [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF). 

Currently testing / incomplete. 

Note: all this does is take the official .deb that Stirling releases and repackages it as a flatpak.
It is an unofficial build not associated with the Stirling project.

## Local Build Instructions

### Prerequisites

- [Flatpak](https://flatpak.org/setup/) installed
- `flatpak-builder` installed
- GNOME 48 SDK and runtime:

```bash
flatpak install flathub org.gnome.Platform//48 org.gnome.Sdk//48
flatpak install flathub org.freedesktop.Sdk.Extension.openjdk21//24.08
```

### Build and Install

```bash
flatpak-builder --force-clean build-dir com.stirlingpdf.StirlingPDF.yml
```

To install locally and run:

```bash
flatpak-builder --user --install --force-clean build-dir com.stirlingpdf.StirlingPDF.yml
flatpak run com.stirlingpdf.StirlingPDF
```

### Build a Bundle

To create a `.flatpak` bundle file for distribution:

```bash
flatpak-builder --repo=repo --force-clean build-dir com.stirlingpdf.StirlingPDF.yml
flatpak build-bundle repo stirling-pdf.flatpak com.stirlingpdf.StirlingPDF
```

