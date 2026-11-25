# Sample Theme Tokens

These values are illustrative fixture data for the bundled theme showcase. They are not a promise that every Registry screen uses these exact values.

| Token | Value | Intended use |
| --- | --- | --- |
| `--sample-primary` | `#7C3AED` | Primary actions and selected navigation |
| `--sample-cyan` | `#06B6D4` | Secondary emphasis and data visualization |
| `--sample-surface` | `#111827` | Dark page surface |
| `--sample-card` | `#1F2937` | Raised content surface |
| `--sample-text` | `#F3F4F6` | Main text on dark surfaces |
| `--sample-muted` | `#9CA3AF` | Supporting text on dark surfaces |
| `--sample-warning` | `#F59E0B` | Caution state, paired with a text label |

## Spacing scale

Use a consistent 4 px base: `4`, `8`, `12`, `16`, `24`, and `32` px. Dense data rows may use the lower values; section boundaries should use the higher values.

## Embedded preview font

The showcase PDF embeds its preview font as a data URI:

```css
@font-face {
  font-family: 'ShowcasePreview';
  src: url(data:font/woff2;base64,d09GMgABAAAAAEZ8ABIAAAAAqHwAAEYYAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGmQbmRocgQAGYD9TVEFURAgwCZptEQgKgbdsgaBMC4NyAAE2AiQDh2AEIAWFAgeQNAwHG56VB5hnHYV0BwCk+P/dcmNMuokQ2oYamW+XkQw00mQXisys///PTiZj9gdk+1CTRELU9aRqE7cKRZWhQx0hFhE7Q3R37e6JnDhxd08cZ08cZ2VgZGZgYmRmZGJkZmQ=) format('woff2');
}
```
