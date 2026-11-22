# Crawlmates

A pixel dungeon crawler for up to four players: fog of war, telegraphed combat, a skill tree, bosses every third floor and a story that ends on floor 15 (then the depths go on forever).

The whole game is `index.html`. `peerjs.min.js` is only used for online co-op.

## Put it on GitHub Pages

1. Create a new public repository on GitHub (for example `crawlmates`).
2. Upload everything in this folder to the root of the repository, including the `scripts` folder. The hidden `.github` folder is easy to miss when uploading in a browser: if it doesn't show up in the repo, see **Patreon button and credits page** below for how to add it by hand.
3. Open **Settings → Pages**. Under **Build and deployment**, set **Source** to *Deploy from a branch*, pick **main** and **/ (root)**, and save.
4. After a minute the game is live at `https://<your-username>.github.io/<repo-name>/`.

Pages are served over HTTPS, which online play needs.

## Ways to play

| Mode | How |
|---|---|
| Solo | Pick **Play**. A companion bot fights beside you (switch it off under **Companion bot** on the title screen or in **Options**). |
| Couch co-op | Connect two controllers. Player 2 presses **Start**. The screen splits. |
| Online co-op (2–4 players) | Everyone opens the GitHub page and picks **Online co-op**. One player picks **Host a lobby**. Friends either pick that lobby from the **Public lobbies** list or choose **Join with code** and type the 5-letter room code. When everyone is in, the host picks **Start run**. |

Every menu works with the mouse, touch, the keyboard (arrows + Enter, Esc to go back) and a controller (D-pad/stick + A, B to go back).

### Pause menu

Press **Esc** / **P** (or **Start** on a controller) during a run for Resume, Skill tree, Journal, Options (volume, screen shake, fullscreen, companion bot, controls) and Quit. Quitting keeps the Knowledge you've earned. In an online game the menu doesn't stop the game for everyone else: your hero just stands still while it's open. The host also gets **Back to lobby**, which brings the whole party back to the lobby.

### Taking the stairs

Everyone who is still standing has to be in the stairs room before anyone can go down. Knocked-down heroes don't count and are revived on the next floor. Bots are brought along automatically. Arrows at the screen edge point to your teammates and, once someone is waiting, to the stairs.

## How online play works

- The host's browser runs the game. Each guest sends button presses and draws what the host sends back about 15 times a second (about 4–5 KB each with a full party). Guests move their own hero locally, so movement feels instant.
- Browsers find each other through the free public PeerJS matchmaking server, then talk directly (WebRTC). No server of your own is needed.
- **Public lobby list:** a public lobby also claims one of 16 well-known IDs on the matchmaking server, and the lobby browser asks each of them who is there. Set a lobby to **Private** to hide it; friends can still join with the code. If all 16 spots are taken, the lobby isn't listed, but the code still works.
- Each player keeps their own look, upgrades and journal. Knowledge earned is added to each player's own save.
- Friends can join a run that has already started (drop-in) while there's room. If someone disconnects, a bot takes over their hero, and when anyone joins again they take over that hero, keeping its level and gear.

### If players can't connect

Direct connections use public STUN servers, which work on most home networks. Some strict networks (some offices, schools, mobile carriers) block direct connections. If that happens:

- Try a different network (for example a phone hotspot), or
- Add a TURN relay server. In `index.html`, search for `PEER_OPTS` and add your TURN server to `iceServers`, for example:
  ```js
  {urls:'turn:your.turn.server:3478',username:'user',credential:'pass'}
  ```

The room code only works while the host's lobby or run is open.

## Saves

Progress (Knowledge, upgrades, journal, hero look, best floor) is saved in the browser's local storage for the site it's played on. Playing from a different address or browser starts fresh.

## Playing on a phone

The game works in any phone browser, but it's best installed to your home screen:

- **iPhone / iPad:** open the GitHub page in **Safari**, tap **Share**, then **Add to Home Screen**. Opening Crawlmates from the home-screen icon runs it fullscreen with no search bar. The game keeps clear of the notch and the home bar. (In portrait, iOS still shows the clock and battery at the top.)
- **Android:** in Chrome, open the menu and pick **Add to Home screen** or **Install app**. It opens fullscreen.

Touch controls: drag anywhere on the left to move. The buttons on the right are attack (hold to charge), dash, parry, bomb and spell. Tap **E** at stairs and weapons, **Skills** under the HUD, the **minimap** for the big map, and the **pause button** next to the minimap for the menu. With voice chat on, a **mic button** appears under pause: hold it to talk in push-to-talk mode, or tap it to mute and unmute. Phones play best sideways.

Voice chat works in the home-screen app too. Allow the microphone when asked. On iPhone, other players' voices play at full volume (use the phone's volume buttons), and the per-player sliders work as on/off.

Files for the home-screen app: `manifest.webmanifest`, `sw.js` (lets the game open even without internet; it always fetches the newest version when it can) and the `icon-*.png` / `apple-touch-icon.png` icons. Keep them next to `index.html`.

## Boss skins

Bosses come in different looks each time you meet them:

- **The Slime King:** eight colours (azure, crimson, violet, amber, rose, frost, shadow, or the classic green).
- **The Bone Colossus:** sometimes in knight's armour, sometimes gilded armour, or cursed (green) or charred bones.
- **The Hollow Mage:** robes in crimson, azure, emerald or void.
- **The Ash Commander:** armour in gilded, obsidian or verdigris.

The skin appears in the boss's name, like THE AZURE SLIME KING. Everyone in an online game sees the same skin.

## Tutorial

New players can pick **Tutorial** on the title screen. It's a short solo run of 3 floors:

1. **Floor 1:** moving, attacking, dashing, fighting slimes, the charged spin attack, opening a chest and finding the stairs.
2. **Floor 2:** parrying, bombs, spells, spending a skill point and the big map.
3. **Floor 3:** an easy boss, a weakened Slime King that moves slower.

A panel on the left shows each step and adapts to keyboard, controller or touch. You can't lose: if you fall, you're put back at the start of the floor at full health. Steps can be skipped from the pause menu, and the tutorial gives no Knowledge.

## Accessibility

**Options → Accessibility** has:

| Setting | What it does |
|---|---|
| Text font | *Pixel* (default), *Hyperlegible* (Atkinson Hyperlegible, designed by the Braille Institute for low vision) or *OpenDyslexic*. The clear fonts are drawn sharply at your screen's full resolution. |
| Text size | Normal or Large (clear fonts only). |
| Text background | A dark box behind all text, for contrast. |
| Color filter | Corrections for red-blind (protan), green-blind (deutan) and blue-blind (tritan) vision, or a high-contrast mode. |
| Reduce flashing | Softens the red damage flash and stops the low-health pulse. |
| Game speed | 100%, 85%, 70% or 55%. In online games the host's setting applies to everyone. |
| Zoom | Makes everything on screen bigger. |

Settings are saved in your browser. Screen shake is under **Options**.

## Voice chat

Online games have built-in voice chat. It's **off until you turn it on**, and your microphone is only used during online games (or while you test it in the settings).

- Turn it on from **Options → Voice chat**, from the **Voice chat** row in the lobby, or from the pause menu during an online game. Left/right switches voice on or off; Enter opens the voice settings.
- The browser asks for microphone permission the first time. If you say no, you can still hear everyone else.
- **Talk modes:** *Open mic*, *Voice activated* (adjust *Mic sensitivity* using the level meter; the orange line is where your mic opens) or *Push to talk* (hold **G**).
- **H** mutes or unmutes your mic at any time.
- Settings: microphone choice, mic volume, voice volume, noise suppression, and **Player volumes**, which sets each player from muted up to 200%.
- A speaker icon shows who is talking, next to names above heroes, in the party list and on the lobby cards. Your own mic status is shown under the HUD on the left.
- Audio goes straight between players' browsers (peer to peer), like the game itself. Like online play, it needs the GitHub (HTTPS) page; strict networks may need the TURN server described above.
- Controllers have no spare button for push to talk, so controller players should use *Open mic* or *Voice activated*.

## Spirit skills

The **SPIRIT** branch of the skill tree (top to bottom) unlocks support magic:

| Skill | Cost | What it does |
|---|---|---|
| Meditation | 1 point | New spell, **Meditate** (free): you can't move, attack or dodge for 5 seconds while your mana fills completely. |
| Soul Bond | 1 point | You revive teammates twice as fast, and they come back with an extra heart. |
| Necromancy | 2 points | New spell (50 mana): instantly raises every downed teammate, anywhere on the floor, at half health. |
| Sacrifice | 2 points | New spell (20 mana): you fall, fully heal every teammate and revive any who are down. You can't be revived (not even by Necromancy) until the party reaches the next floor. It only works if another player (not a bot) is left standing to carry on. |

Knocked-down and sacrificed heroes don't need to be in the stairs room, so the party can always move on.

## Mastery orbs

A Mastery orb maxes out one whole branch of the skill tree. They now drop from 1 in 400 enemies (it was 1 in 100).

## Enemy modifiers

Regular enemies can roll modifiers, more often on deeper floors. From floor 4 an enemy can have two. The name of each modifier floats above the enemy.

| Modifier | Effect |
|---|---|
| Toxic | Leaves a toxic puddle for 5 s when defeated. It deals 1 damage per second to anyone standing in it. |
| Quick | Attack cooldown is cut by about 55%. |
| Stressed | Blows up in a small explosion shortly after it dies. |
| Buff | Has +50% health and is drawn larger. |
| Neutral | Ignores you until it is hit, then its tag changes to PROVOKED. Bots leave it alone. |
| Leader | Has +80% health. Summons two weaker copies (35% health, smaller) after a purple warning circle, with up to 3 copies alive at once. |
| Wise | Has a yellow outline and gives triple XP. |
| Lucky | Drops a small chest with random chest loot. |

Bosses and summoned minions never get modifiers.

## Patreon button and credits page

The home screen has a **♥ PATREON** button that opens https://www.patreon.com/cw/Crawlmates, next to a **CREDITS** button. The credits page rolls by slowly (scroll it with the arrow keys, mouse wheel, a drag on a phone or the d-pad). It shows:

- **Created by Holden Slaughter**
- **Patrons**: everyone who is an active patron at **$5 or more a month**, in alphabetical order
- the fonts and libraries the game uses

The patron names come from `credits.json`. The game loads it each time the credits open, so the list updates without changing `index.html`. If the file is missing or empty, the page says "Be the first name here!". The pixel font only has plain letters and numbers, so accents are dropped (Zoë becomes ZOE) and characters it can't draw are left out.

### Keeping the list up to date automatically

`.github/workflows/patreon-credits.yml` runs `scripts/update_credits.py` once a day. It asks Patreon for your members, keeps active patrons whose tier (or custom pledge) is $5 or more, and commits a new `credits.json` only when the list has changed. Pages then republishes the site by itself. Patron names are never written to the Actions log.

One-time setup:

1. Sign in to Patreon as the Crawlmates creator and open https://www.patreon.com/portal/registration/register-clients. Choose **Create client**; give it a name like *Crawlmates credits*. Any redirect URL works (for example your Pages address), since it isn't used.
2. Open the new client. Copy the **Creator's Access Token**, **Creator's Refresh Token**, **Client ID** and **Client Secret**.
3. In the GitHub repo, open **Settings → Secrets and variables → Actions → New repository secret** and add:
   - `PATREON_ACCESS_TOKEN`: the Creator's Access Token (the only one that's required)
   - `PATREON_REFRESH_TOKEN`, `PATREON_CLIENT_ID`, `PATREON_CLIENT_SECRET`: let the script get a new access token when the old one expires
4. Open the **Actions** tab, pick **Update Patreon credits**, and press **Run workflow** to fill the list straight away.

If the `.github` folder didn't upload: in the repo choose **Add file → Create new file**, type `.github/workflows/patreon-credits.yml` as the name, and paste in the contents of that file from this folder.

**Expiring tokens.** Patreon's creator tokens stop working after a while. With the refresh token and client details saved, the script gets a new access token by itself. To store the new one for the next run, also add a `SECRETS_PAT` secret: a GitHub fine-grained personal access token for this repository with **Secrets: Read and write** permission. Without it, the run still works but shows a warning, and when the refresh token itself stops working you paste fresh tokens from the Patreon portal into the secrets.

**Choosing how names appear.** Edit `credits-overrides.json`:

```json
{
  "name_style": "full",
  "hide": ["Name Of Someone Who Opted Out"],
  "rename": {"Their Patreon Name": "How They Want To Be Shown"},
  "extra": ["Someone Thanked By Hand"]
}
```

`name_style` can be `full` (the name on their Patreon account), `first` (first name only) or `first_initial` (like *Ava T.*). Patreon names are often real names and the repo is public, so tell patrons on your tier description that $5+ patrons are listed in the game's credits, and offer to hide or rename anyone who asks.

To edit the list by hand instead, change `credits.json` directly; the daily run will overwrite it, so use the overrides file for anything permanent.

## Credits

The game is made by **Holden Slaughter**.

The title uses the **ChickenScratch** font (© FontPanda.com, 2014). The accessibility fonts are **Atkinson Hyperlegible** (© 2020 Braille Institute of America) and **OpenDyslexic** (© Abbie Gonzalez), both under the SIL Open Font License 1.1 (see `FONTS-LICENSE.txt`). All fonts are embedded in `index.html`. PeerJS is MIT licensed (see `PEERJS-LICENSE`).
