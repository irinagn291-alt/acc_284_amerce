<!-- gf-brief source=6d6f9f1114777c27c666cabfed701d0e522e49bfd523f08ad59435668fa20217 written=2026-10-01T15:11:11+03:00 -->
# Amerce

## What it is
Amerce is a light, portrait parlor app for a host and seated guests. The host locks a dare pack, seats name plates on a wheel, spins to pin the next unused dare as a forfeit on whoever lands, and clears forfeits when they are done. Night history keeps a run of lands by name and by night.

## Launch and onboarding
On a cold launch the window may sit briefly blank, then the native parlor appears. The system may also show the standard notifications permission alert at launch.

If onboarding is not finished, a full-screen pamphlet covers the parlor:

1. **"Pin a dare"** — *"A host spins the wheel. The land pins the next unused dare on that name."* Buttons: **"Continue"**, **"Skip"**.
2. **"Clear when done"** — *"That name taps Clear. The forfeit peels. The name stays on the wheel."* Buttons: **"Continue"**, **"Skip"**.
3. **"Stack the night"** — *"A later land on a charged name stacks another forfeit. Lock a new pack when this one is spent."* Buttons: **"Start"**, **"Skip"**.

**"Continue"** advances pages. **"Start"** or **"Skip"** finishes onboarding. If no pack is locked yet, finishing locks **"Wax parlor slips"**. The parlor then shows.

If onboarding is already complete, the main **"Forfeit"** arena opens with saved names, pack, open forfeits, and nights restored.

## Screens

### Forfeit (main arena)
No tab bar. Top chrome: **"History"** (book icon), title **"Amerce"**, **"Settings"** (gear icon). Hero **"Forfeit"**, a localized night heading (e.g. weekday and date), and a status line.

**Empty wheel** (no names seated): **"The wheel is empty."** / **"Seat names so a land can pin a forfeit."** / **"Add names"** → Settings.

**When names are seated:**
- Pack heat strip: fill percent, locked pack title or **"No pack locked"**, unused-dare count and **"Unused dares"** → opens **Locked pack**.
- Wheel with each name plate on a slice; hub shows **"Next"** / next dare / unused count, or **"Pack"** / **"No pack"**, or **"Spent"** / **"Lock a pack"**, or the open forfeit plate, spoken dare, and **"Tap Clear when it is done."**
- Forfeit rail: **"Open forfeits sit here after a land."** when idle; otherwise each open forfeit shows plate, optional stack depth, spoken dare, and **"Clear"**.
- **"Spin"** — spins and pins the next unused dare on the landed name. Disabled while turning or when Spin cannot run.
- **"Lock pack"** appears when the locked pack is spent → **Locked pack**.

Status / note lines include: **"The wheel is turning."**, **"The pack is spent. Lock a new pack to spin."**, **"Spin pins the next unused dare on a name. Tap Spin."**, **"Lock a pack in Settings, then tap Spin."**, and after a land *"{plate} holds a forfeit. Tap Clear when it is done."* or *"{plate} stacked another forfeit. Tap Clear when it is done."*; after Clear *"{plate} is clear."* or *"One forfeit peeled from {plate}."*

Banners if needed: **"The parlor restored a backup copy."** / **"Reload"**; **"The saved parlor could not be read. Starting empty."** / **"Reload"**; **"The parlor did not save. …"** / **"Retry"**.

On wider layout (iPad-style): **"On the wheel"** lists each plate with **"Idle"** or *"{n} landed"*, plus a remaining-pack card (**"No pack locked"** or pack title, leftover dares or **"The pack has no unused dares."**) that opens **Locked pack**.

### History (sheet)
Title **"History"**, close control. **"Lands by name"** with per-name *"{n} landed"*, or **"No names are seated."** Then a run of nights (recent days plus any older nights with lands): night title, *"{n} landed"*, each land’s plate, spoken dare, and clock time, or **"No lands this night."**

Empty: **"The night has no forfeits yet."** / **"Spin on the arena to pin the first dare."** / **"Back to the wheel"**. Save error: **"History did not save."** / **"Retry"**.

### Settings (sheet)
Title **"Settings"**, close control.

Empty (no names and no locked pack): **"No names are seated."** / **"Seat a name, then lock a pack so Spin can pin a forfeit."** Field placeholder **"Name plate"**, **"Seat"** (disabled while blank). Keyboard **"Done"**.

Populated:
- **"Names"** — **"Name plate"** / **"Seat"**; each seated plate with **"Idle"** or stack count; remove control; caption *"{n} seated. Names stay on the wheel after a land."* Remove asks **"Remove {plate} from the wheel?"** with **"Remove name"** / **"Keep"**.
- **"Pack"** — for each of **"Wax parlor slips"**, **"Lamp room"**, **"Glove table"**: unused-dare count, **"Spin pins from this pack."** or **"Lock to pin from this pack."**, **"Locked"** or **"Lock"**.
- **"Haptics"** — **"Landing climax on"** / **"Landing climax off"** with **"On"** / **"Off"**.
- **"Parlor"** — **"Re-run onboarding"** (closes Settings and opens the pamphlet again); **"Contact Amerce"** (opens the support page); **"Reset all data"** → **"Erase names, the locked pack, and every night?"** with **"Reset all data"** / **"Cancel"**.

Save error: **"Settings could not save."** / **"Retry"**.

### Locked pack (sheet)
Title **"Locked pack"**, close control. **"Pack-locked forfeit"** and *"Spin writes the next unused dare onto the landed name. Clear peels one forfeit. A later land on a charged name stacks another."*

Empty: **"No pack is locked."** / **"Lock a dare pack so Spin has a forfeit to pin."** / **"Lock a pack"** (locks **"Wax parlor slips"**).

Otherwise current pack card (title, fill percent, **"Spent. Lock a new pack to spin."** or **"Next unused dare pins on the next land."**, **"Unused {n} of {m}"**) and the three packs with dare counts and **"Lock"** / **"Locked"**. Save error: **"The pack could not save."** / **"Retry"**.

Built-in packs and dare lines (as spoken on screen; trailing **" until Clear"** is dropped from display):
- **Wax parlor slips** (5): Recite one couplet standing; Bow to the nearest lamp; Surrender a glove; Hum eight bars of a waltz; Stand still until the next land.
- **Lamp room** (6): Offer the next guest a seat; Speak only in questions; Trade places with the host; Hold a lamp pose for one land; Name three objects without pointing; Walk the room once, then sit.
- **Glove table** (4): Lay a glove on the nearest table; Toast the landed name without a glass; Keep both heels together; Introduce two guests by plate.

## Features
- Seat and remove guest **name plates** on the wheel
- Lock one of three **dare packs**; Spin consumes **unused dares** in order
- **Spin** the wheel to **pin** a **forfeit** on the landed name
- **Clear** peels one open forfeit; names stay seated
- **Stack** further forfeits on a name that already holds one
- Pack **fill** / unused-dare strip on the arena
- **History**: lands by name and by night
- **Haptics** for landing climax (on/off)
- Re-run the three-page onboarding pamphlet
- **Contact Amerce** for support
- **Reset all data** to erase the parlor
- Light appearance only

## Behaviours that can look like bugs
- **"Spin"** stays disabled until at least one name is seated and a non-spent pack is locked; seat names in Settings and lock a pack (or finish onboarding, which locks **"Wax parlor slips"**).
- While the wheel is turning, **"Spin"** and **"Clear"** stay disabled; status **"The wheel is turning."** Wait for the land.
- When the pack is spent, **"Spin"** will not pin; status **"The pack is spent. Lock a new pack to spin."** Use **"Lock pack"** or Settings/Locked pack to lock again (locking resets unused dares for that pack).
- **"Seat"** is disabled on a blank **"Name plate"**; enter a non-empty plate.
- Forfeit rail shows **"Open forfeits sit here after a land."** until the first land; Spin once.
- History empty until the first land: **"The night has no forfeits yet."** — **"Back to the wheel"** then Spin.
- Settings empty until a name is seated (and shows the seat field only until then); seat a name to reach pack/haptics/parlor actions.
- **"Re-run onboarding"** deliberately returns to the pamphlet; finish with **"Start"** or **"Skip"** to return to the parlor.
- Night list grows as lands happen; **"Reset all data"** clears names, pack, and nights on purpose.
- Notes like **"The wheel is empty. Seat names first."**, **"That name has no forfeit to clear."**, **"A name plate cannot be blank."** refuse the action until the condition is fixed.

## Starter content and resume
Finishing onboarding with no pack locked seats **"Wax parlor slips"** (five wax dares). On a physical device there are no sample name plates. Unfinished parlor state resumes across launches: seated names, locked pack and how many dares remain, open stacked forfeits, haptics preference, onboarding flag, and night history.

## Permissions
- **Notifications** — asked at cold launch via the system alert (no custom usage-description string in the app’s build settings).
- Build settings also include camera usage text **"This app does not use the camera."**; the native parlor never presents a camera permission prompt.

## Absent
Login or accounts; in-app purchase; ads; App Tracking Transparency prompt; account deletion flow (only local **"Reset all data"**); user-generated content shared with others (name plates stay on this device only). Analytics / push infrastructure is present behind the scenes and is not listed as absent.

## Data and support
Parlor names, packs, forfeits, and nights stay on this device. **"Contact Amerce"** in Settings opens the support page.

## Scanning and health
None.

## Platform
Portrait only on iPhone and iPad; requires full screen; light interface. Numbers and night/date headings follow the device locale/calendar. Minimum iOS 17.0.

## Category
Lifestyle
