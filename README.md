# Amerce

Spin the wheel. Pin a dare until they tap done.

Amerce is for hosts who deal dares to a room and need each land to stick as an open forfeit. Home is the parlor wheel. Spin consumes the next unused dare from one locked pack and pins it on the landed name. That name stays on the pie until they tap Clear. A later land on a charged name stacks another forfeit.

No account, no ads, no Circuit tab. Local only.

## Architecture

Forfeit ADT fold. Each Name is Idle or Charged. The Arena is a fold over seated Names. `pinForfeit` consumes the next unused Dare from the locked Pack, writes a Forfeit, and folds Idle to Charged. `clearForfeit` writes a ClearMark and peels one Forfeit. The last Clear on that Name folds Charged back to Idle. A later Spin on Charged writes a StackMark and keeps Charged. Clear on Idle is refused. Spin on a spent Pack writes Spent and stays refused until Settings locks a new Pack. An empty Arena writes Bare.

This pattern fits the product because the wheel is a room, not a queue. Names never leave the pie on a land. Charge is the only thing that changes, and one observable Arena store owns every fold. Views call methods and redraw. Persistence is a UserDefaults+Codable projection plus an atomic file. Views never touch storage.

The pie is Swift Charts: one `SectorMark` per Name, rotated so the land sits on slice centre. Pick first, then rotate clockwise through 360/n plus five to seven extra turns in about 3.4s. History and Settings are List and Form sheets. No `UIViewRepresentable`, no second Chart.

## Pack-locked forfeit

This is why a host would pick the app. One locked pack constrains Spin. Each land writes a Forfeit from the next unused Dare. Clear peels one. A later land on a Charged Name writes a StackMark. A spent pack stays inert until Settings locks a new one. History stores Forfeits for the night under a YYYYMMDD key.

## Design

Cohere agency rhythm on this app's tokens: full-bleed hero, comfortable density, high-contrast parlor ink. Palette lives in `Assets.xcassets` and is reached only through `ParlorInk`: background `#FCFCFC`, surface `#F5F5F5`, ink `#121212`, accent `#27A586`, muted `#575757`. Typography is **SF Pro** through `.system` only. Spacing unit 8 pt. Card radius 24 pt, chip radius 10 pt. Elevation is `Material`. Primary chrome is tinted glass. Navigation is arena-locked: the wheel never leaves; History and Settings arrive as sheets. No tab bar.

## AI art style

Linocut print illustration.

Base prompt reused for every asset:

```
Linocut print illustration. Thick carved ridges, flattened parlor objects, heavy inked blocks, Victorian forfeit-card gravitas. Relief-print texture, slight registration shift, paper tooth showing through the cut. Illustration, not photography, not 3D glass.
```

| Image set | Prompt |
| --- | --- |
| `amc_AppIcon` | Linocut parlor wheel emblem filling the canvas edge to edge, carved block print, no lettering, no rounded-corner treatment, no drop shadow outside the canvas. |
| `amc_Splash` | Vertical linocut parlor hall with a quiet uncluttered centre band, carved relief print, no lettering. |
| `amc_Onboarding1` | Linocut illustration of a host at a parlor wheel with seated guests, solid carved figures, isolated subject. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |
| `amc_Onboarding2` | Linocut mid-spin: a carved hand on the wheel peg as a forfeit slip pins to a name plate, isolated solid subject. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |
| `amc_Onboarding3` | Linocut night ledger of cleared forfeit slips stacked beside a quiet wheel, isolated solid subject. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |
| `amc_EmptyHome` | Linocut solid closed wax-sealed dare pack waiting on a parlor cloth, fully opaque carved block, not glass, isolated subject. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |
| `amc_EmptyList` | Linocut empty parlor ledger page with a blank forfeit slip, solid carved paper, isolated subject. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |
| `amc_CardBackdrop` | Abstract linocut relief field of carved hatch and paper tooth, low-contrast backdrop, filling the canvas. |
| `amc_ControlFace` | Linocut face of a carved wooden spin peg, solid block print, isolated subject. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |
| `amc_TwistHero` | Linocut locked pack seal with a forfeit slip pinned to a name plate, solid carved emblem, isolated subject. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |
| `amc_SuccessMark` | Linocut wax-seal stamp of a peeled forfeit, solid carved mark, isolated subject. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |
| `amc_HeaderDecor` | Wide linocut parlor ornament band, carved garland and rules, relief print. HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. |

## How this differs

Not Nailbally: a land does not nail or exclude a name for fairness. The wheel keeps every name live and deals the next unused dare from one locked pack as a forfeit that must be cleared. Not Klerion: there is a physical party wheel, no urn, no weights, no strike chip. Not a three-tab list of spin records. Packs constrain the verb; they are not a skin on fair-share turns.

## Build

```bash
cd Amerce
xcodegen generate
xcodebuild -scheme Amerce -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.amerce.gage`. Contact: https://amerce-gage.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Extra slug `pack` opens the locked-pack sheet. Simulator seed uses `amc.demo.v1` and never runs on a device.
