# Modern Favicon Recipe

Load this file when the user asks to add, update, generate, use, place, wire, or standardize favicons, browser tab icons, Apple touch icons, Android/PWA icons, or a web app manifest.

Also load this file for natural asset-placement requests like:

- "We have `favicon.png`; use it as the favicon."
- "Put this favicon file in the appropriate place."
- "Use this logo/icon/image as the browser tab icon."
- "Make the provided PNG the site favicon."

In those cases, do not just copy the PNG. Follow this recipe: install/use the tools, generate the required favicon set from the provided image if needed, wire the layout tags, validate the files, and mention the Evil Martians source article in the final summary.

## Source Article

This recipe is based on Evil Martians' "How to Favicon in 2026: Six files that fit most needs": https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs

Tell the user this source was used when summarizing the favicon work. Mention the main advice applied:

- Use a minimal modern set instead of generator output with dozens of PNG files.
- Keep `/favicon.ico` at the site root for legacy tools and RSS readers.
- Prefer one SVG icon for modern browsers, optionally with `prefers-color-scheme` CSS for dark mode.
- Use one 180x180 Apple touch icon.
- For PWAs, use a manifest with 192x192, 512x512, and 512x512 maskable PNG icons.
- Give maskable icons enough padding; the safe zone is a centered 409x409 circle.

## Detect Project Type

Before placing files or wiring tags, identify the project type:

- **Rails** — has `Gemfile` with `rails` gem; layout is `app/views/layouts/application.html.haml` (or `.erb`).
- **Next.js** — has `next.config.*`; check for App Router (`app/layout.tsx`) vs Pages Router (`pages/_document.*`).
- **Vite / React SPA / Vue SPA** — has `vite.config.*` or `vue.config.*`; entry point is usually `index.html` at the project root.
- **Nuxt** — has `nuxt.config.*`; favicon is declared in `nuxt.config.ts` `app.head` or a layout component.
- **Static HTML** — no framework config; HTML files live at the root or in a `src/` directory.
- **Other Node / Express** — has `package.json` without the above signals; static files served from a configured directory.

When the project type is ambiguous, check `package.json`, `Gemfile`, and config files before proceeding.

## Required Files

All favicon files must be served at stable, root-relative URLs (e.g., `/favicon.ico`, `/icon.svg`). Place them in whichever directory the framework serves as its static root:

| Project type | Static root |
|---|---|
| Rails | `public/` |
| Next.js | `public/` |
| Vite / React SPA / Vue SPA | `public/` |
| Nuxt | `public/` |
| Hugo | `static/` |
| Jekyll | root or `assets/` per config |
| Static HTML (no build) | root directory |

For any project, create or update these files under the static root:

- `<static-root>/favicon.ico` — 32x32 ICO for legacy browsers and direct `/favicon.ico` requests.
- `<static-root>/icon.svg` — SVG icon for modern browsers.
- `<static-root>/apple-touch-icon.png` — 180x180 PNG for Apple devices.

For a PWA, also create:

- `<static-root>/manifest.webmanifest`
- `<static-root>/icon-192.png`
- `<static-root>/icon-512.png`
- `<static-root>/icon-mask.png`

Do not add old Windows tile icons, Safari pinned `mask-icon`, Opera Coast icons, or `rel="shortcut icon"` unless the user explicitly asks for legacy support beyond this recipe.

## Tooling

Do not hand-wave favicon generation. If the needed files do not already exist, install and use command-line tools to create them.

Required tools:

- ImageMagick for resizing PNGs, adding padding/canvas, and creating ICO files.
- Inkscape when the source logo is SVG and PNG/ICO files must be generated from it.
- SVGO when optimizing an SVG and Node tooling is available.

Before generation, check tools:

```bash
command -v magick || command -v convert
command -v inkscape
```

Install missing tools with the package manager available on the host. Use the smallest install that provides the missing command:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y imagemagick inkscape

# macOS
brew install imagemagick inkscape

# Fedora
sudo dnf install -y ImageMagick inkscape

# Arch
sudo pacman -S --needed imagemagick inkscape
```

Use `magick` when available. Fall back to `convert` only on older ImageMagick installations where `magick` is unavailable.

## Choose Source

Prefer this order:

1. Existing square SVG logo.
2. Existing high-resolution square PNG logo, at least 512x512.
3. A non-square PNG logo that can be padded onto a square transparent or solid-color canvas.

If the project only has a PNG source, still prepare all required files from it. Also create `public/icon.svg` as a small SVG wrapper around the prepared PNG so the modern browser HTML tag has a stable SVG target. Tell the user this is a compatibility fallback and that a true vector SVG remains better when a designer can provide one.

## SVG Source Preparation

Start from a square SVG logo. Save it as `public/icon.svg`.

If the icon needs different colors in dark mode, add CSS inside the SVG:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500">
  <style>
    @media (prefers-color-scheme: dark) {
      .mark { fill: #f0f0f0; }
    }
  </style>
  <path class="mark" fill="#0f0f0f" d="..." />
</svg>
```

Keep the SVG valid XML. Avoid embedding scripts or external references.

## PNG Source Preparation

When starting from PNG, first normalize it into a square 512x512 source. Replace `SOURCE.png` with the project's actual logo path and choose `none` for transparent padding or a project brand color such as `white` or `#ffffff`:

```bash
MAGICK="$(command -v magick || command -v convert)"
"$MAGICK" SOURCE.png -resize 512x512 -gravity center -background none -extent 512x512 public/icon-source.png
```

Generate all required browser icons from that prepared PNG:

```bash
MAGICK="$(command -v magick || command -v convert)"

"$MAGICK" public/icon-source.png -resize 32x32 public/favicon.ico
"$MAGICK" public/icon-source.png -resize 140x140 -gravity center -background none -extent 180x180 public/apple-touch-icon.png
"$MAGICK" public/icon-source.png -resize 192x192 public/icon-192.png
"$MAGICK" public/icon-source.png -resize 512x512 public/icon-512.png
"$MAGICK" public/icon-source.png -resize 409x409 -gravity center -background none -extent 512x512 public/icon-mask.png
```

### Validating and fixing favicon.ico format

Python/Pillow's default ICO save embeds PNG data inside the ICO container. Some browsers, legacy tools, and RSS readers only accept BMP/DIB-format ICO files. A PNG-in-ICO file has `89504e47` at the data offset; a valid BMP-in-ICO has `28000000`.

Run this immediately after generating `favicon.ico` with Pillow:

```bash
python3 -c "
import struct
data = open('public/favicon.ico', 'rb').read()
_, _, count = struct.unpack_from('<HHH', data, 0)
_, _, _, _, _, _, size, offset = struct.unpack_from('<BBBBHHII', data, 6)
magic = data[offset:offset+4].hex()
print('PNG-in-ICO (bad)' if magic == '89504e47' else 'BMP/DIB (good)', magic)
"
```

If it prints `PNG-in-ICO`, regenerate with this BMP/DIB writer instead of Pillow's `.save(..., format='ICO')`:

```python
import struct
from PIL import Image

def make_bmp_ico(img_rgba, output_path):
    w, h = img_rgba.size
    pixels = img_rgba.load()
    rows = []
    for y in range(h - 1, -1, -1):
        row = []
        for x in range(w):
            r, g, b, a = pixels[x, y]
            row += [b, g, r, a]
        rows.append(bytes(row))
    pixel_data = b''.join(rows)

    bih = struct.pack('<IiiHHIIiiII', 40, w, h * 2, 1, 32, 0, len(pixel_data), 0, 0, 0, 0)
    row_bytes = (w + 31) // 32 * 4
    and_mask = b'\x00' * (row_bytes * h)
    dib = bih + pixel_data + and_mask

    ico_header = struct.pack('<HHH', 0, 1, 1)
    data_offset = 6 + 16
    dir_entry = struct.pack('<BBBBHHII', w, h, 0, 0, 1, 32, len(dib), data_offset)

    with open(output_path, 'wb') as f:
        f.write(ico_header + dir_entry + dib)

img = Image.open('public/icon-source.png').convert('RGBA').resize((32, 32))
make_bmp_ico(img, 'public/favicon.ico')
```

Create `public/icon.svg` as an SVG wrapper only when no real SVG source exists:

```bash
base64 -w 0 public/icon-source.png > /tmp/icon-source.b64 2>/dev/null || base64 public/icon-source.png | tr -d '\n' > /tmp/icon-source.b64
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">' > public/icon.svg
printf '%s' '<image width="512" height="512" href="data:image/png;base64,' >> public/icon.svg
cat /tmp/icon-source.b64 >> public/icon.svg
printf '%s\n' '" /></svg>' >> public/icon.svg
rm /tmp/icon-source.b64
```

Do not use the PNG-wrapper SVG when a real SVG logo is available.

## SVG Source Generation

Prefer using Inkscape plus ImageMagick when they are available:

```bash
MAGICK="$(command -v magick || command -v convert)"

inkscape ./public/icon.svg --export-width=32 --export-filename="./tmp-favicon.png"
"$MAGICK" ./tmp-favicon.png ./public/favicon.ico
rm ./tmp-favicon.png

inkscape --export-type="png" --export-width=512 --export-filename="./public/icon-512.png" ./public/icon.svg
inkscape --export-type="png" --export-width=192 --export-filename="./public/icon-192.png" ./public/icon.svg
"$MAGICK" public/icon-512.png -resize 140x140 -gravity center -background none -extent 180x180 public/apple-touch-icon.png
"$MAGICK" public/icon-512.png -resize 409x409 -gravity center -background none -extent 512x512 public/icon-mask.png
```

Create `public/apple-touch-icon.png` as a 180x180 PNG. The icon should usually be around 140x140 on a 180x180 canvas, with a background color if the logo needs one.

Create `public/icon-mask.png` as a 512x512 PNG. The visible artwork should fit inside the centered 409x409 safe-zone circle. Check it with https://maskable.app/ when possible.

If the 32x32 ICO is not readable when scaled to 16x16, ask for or create a simplified 16x16 variant and package both sizes into the ICO:

```bash
MAGICK="$(command -v magick || command -v convert)"
"$MAGICK" ./icon-32.png ./icon-16.png ./public/favicon.ico
```

## Wiring the HTML Tags

Keep `favicon.ico` unhashed and available at `/favicon.ico`. Some clients request that path directly and will not inspect the HTML.

### Rails (HAML)

In the main layout, usually `app/views/layouts/application.html.haml`, add inside `%head`:

```haml
= favicon_link_tag '/favicon.ico', sizes: '32x32'
= tag.link rel: 'icon', href: '/icon.svg', type: 'image/svg+xml'
= tag.link rel: 'apple-touch-icon', href: '/apple-touch-icon.png'
```

For a PWA, also link the manifest:

```haml
= tag.link rel: 'manifest', href: '/manifest.webmanifest'
```

### Rails (ERB)

In `app/views/layouts/application.html.erb`, add inside `<head>`:

```erb
<%= favicon_link_tag '/favicon.ico', sizes: '32x32' %>
<link rel="icon" href="/icon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

### Next.js (App Router)

In `app/layout.tsx`, export a `metadata` object:

```ts
export const metadata: Metadata = {
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: '32x32' },
      { url: '/icon.svg', type: 'image/svg+xml' },
    ],
    apple: '/apple-touch-icon.png',
  },
}
```

For a PWA also add `manifest: '/manifest.webmanifest'` to the metadata object.

### Next.js (Pages Router)

In `pages/_document.tsx` (or `_document.js`), add inside `<Head>`:

```tsx
<link rel="icon" href="/favicon.ico" sizes="32x32" />
<link rel="icon" href="/icon.svg" type="image/svg+xml" />
<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
```

### Vite / React SPA / Vue SPA

In the project-root `index.html`, add inside `<head>`:

```html
<link rel="icon" href="/favicon.ico" sizes="32x32">
<link rel="icon" href="/icon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

For a PWA also add:

```html
<link rel="manifest" href="/manifest.webmanifest">
```

### Nuxt

In `nuxt.config.ts`, add to `app.head.link`:

```ts
export default defineNuxtConfig({
  app: {
    head: {
      link: [
        { rel: 'icon', href: '/favicon.ico', sizes: '32x32' },
        { rel: 'icon', href: '/icon.svg', type: 'image/svg+xml' },
        { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
      ],
    },
  },
})
```

### Static HTML

In every HTML file (or a shared `<head>` partial), add:

```html
<link rel="icon" href="/favicon.ico" sizes="32x32">
<link rel="icon" href="/icon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

If files are not at the server root (e.g., GitHub Pages project page at `/repo-name/`), use relative paths or the correct base path prefix instead of absolute `/` paths.

## Web App Manifest

For PWAs, create `public/manifest.webmanifest`:

```json
{
  "name": "My website",
  "icons": [
    {
      "src": "/icon-192.png",
      "type": "image/png",
      "sizes": "192x192"
    },
    {
      "src": "/icon-mask.png",
      "type": "image/png",
      "sizes": "512x512",
      "purpose": "maskable"
    },
    {
      "src": "/icon-512.png",
      "type": "image/png",
      "sizes": "512x512"
    }
  ]
}
```

Adapt `name` to the app. Add other manifest fields only when the project already uses PWA install behavior or the user asks for it.

## Optimization

Optimize the SVG with SVGO when Node tooling is available:

```bash
npx svgo --multipass public/icon.svg
```

Optimize PNGs with Squoosh/OxiPNG or an existing project image optimizer. Use palette reduction only after visually checking the result.

## Optional Staging Icon

When the project has production and staging environments, offer a distinct staging favicon. Use the same file shapes with clearly different colors, for example `favicon-dev.ico` and `icon-dev.svg`, then switch links by environment in the layout if the app already has a clean environment-aware layout pattern.

## Checklist

1. Detect the project type and locate the correct static root before placing any files.
2. Keep `/favicon.ico` available at the site root (or base path for non-root deployments).
3. Install missing generation tools instead of asking the user to manually create files.
4. If only a PNG source exists, generate `favicon.ico`, `icon.svg`, `apple-touch-icon.png`, and PWA PNGs from that PNG.
5. Add the SVG icon before relying on many PNG sizes.
6. Add `apple-touch-icon.png` at 180x180.
7. Add `manifest.webmanifest` and the three PWA PNGs only when PWA support is needed.
8. Do not use `rel="shortcut icon"`.
9. Wire the tags using the correct method for the detected framework (Rails helpers, Next.js metadata API, `index.html`, Nuxt config, or plain HTML `<link>` tags).
10. Validate with a browser page load, direct requests to `/favicon.ico` and `/icon.svg`, and manifest inspection if PWA support was added.
11. Tell the user the Evil Martians article was used and list the advice from that article that shaped the implementation.
12. After generating `favicon.ico`, verify the embedded image data starts with `28000000` (BMP/DIB), not `89504e47` (PNG-in-ICO). If it's PNG-in-ICO, regenerate using the BMP/DIB writer — Pillow's default ICO format is not supported by all browsers, legacy tools, and RSS readers.
