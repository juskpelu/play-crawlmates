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

Progress (Knowledge, upgrades, journal, hero look, saved skins, best floor) is saved in the browser's local storage for the site it's played on. Playing from a different address or browser starts fresh.

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

## Shops and gold

Every enemy drops **gold coins** (tougher monsters drop more), chests hold 5 to 8, and bosses scatter a pile. Coins fly to whoever is closest. The party shares one purse, shown under the floor number.

**Shopkeepers** set up on random floors from floor 2 on, never on boss floors or in the tutorial. The chance of a shop grows with every floor since the last one, and after 4 floors without one the next floor that can have a shop always does. A shop is a lantern-lit room with no monsters in it, a shopkeeper behind a counter, and 2 to 4 wares on pedestals. Walk up to a ware to see what it is and its price, then press **E** (tap **E** on a phone, **Y** on a controller) to buy it.

| Ware | What it does | Price on floor 2 |
| --- | --- | --- |
| Health potion | heals 2 hearts | 10 |
| Mana elixir | refills mana | 8 |
| Floor map | charts the whole floor | 9 |
| Bomb satchel | +3 bombs | 14 |
| Mystery blade | a random new sword (your old one drops) | 28 |
| Spell tome | a spell you don't know yet | 36 |
| Heart container | +1 max heart | 42 |
| Ancient teachings | +1 skill point | 48 |
| Phoenix feather | rise again once when you fall | 55 |

Prices go up 12% per floor after the second. Every shop sells a health potion. The shopkeeper won't take your coin for something you can't use right now, like a potion at full health or a tome when you know every spell. In online co-op anyone can buy from the shared purse, and whoever buys gets the item.

**Shopkeepers wear skins from the marketplace.** When a run starts, the game fetches up to 80 of the most worn and newest skins, and each shopkeeper picks one at random. The name of the skin and its creator show under the shopkeeper's name. Skins you've reported are never used. If the marketplace isn't connected, shopkeepers wear marketplace skins you've saved, or a classic trader outfit. In online co-op the host picks the outfit, and every player sees the same one.

## Custom skins: sprite editor and marketplace

Open **Customize Hero**. The new **OUTFIT** row switches between the classic armour and any skins you've saved. Below the gear rows are two new buttons:

- **SPRITE EDITOR** lets you draw your own hero. Start from the **blank template** (an empty grid with a faint hero outline to trace), copy your current classic hero, or import a PNG.
  - A skin has **2 frames** (standing and mid-step, which alternate as you walk) and up to **15 colours**.
  - **Sizes:** each frame can be **12 x 14** (the built-in heroes' size), 24 x 28, 36 x 42, 48 x 56, 60 x 70, 72 x 84, 96 x 112 or **120 x 140** (a 240 x 140 sheet for both frames). Pick it with NEW SKIN SIZE before starting, or change it any time with the size button in the editor. Going smaller merges detail, and undo brings it back.
  - **Tools:** pen and eraser with **brush sizes** 1, 2, 3, 4, 6, 8, 12 and 16 (round from 4 up; bigger brushes unlock at bigger canvas sizes). There's also fill, a colour picker, and mirror (paints both halves at once). Rounding it out: flip, undo/redo, onion skin (shows the other frame faintly), and a copy button that puts one frame onto the other.
  - **Zoom and move** around big canvases:
    - mouse wheel zooms where you point;
    - Space+drag or the middle button moves the view;
    - Shift+wheel scrolls sideways;
    - on a phone or tablet, pinch to zoom and drag with two fingers;
    - the - / + buttons work everywhere.
  - **Colours:** pick a palette slot, then pick it again (or press COLOUR) to change it from 75 presets or any colour with MORE COLOURS. Recolouring a slot recolours every pixel that uses it.
  - **Buttons:** SAVE keeps it in My Skins, WEAR puts it on, UPLOAD shares it, and EXPORT downloads it as a PNG. Unsaved work is kept, so closing the tab doesn't lose it.
  - **Controls:**
    - **Mouse:** right-click erases.
    - **Touch:** one finger paints, two fingers zoom and move.
    - **Keyboard:** arrows + Space paint, [ and ] change brush, + and - zoom, F fill, Q/E colour, Tab frame, Ctrl+Z undo, Ctrl+S save.
    - **Controller:** A paint, X erase, Y fill, LB/RB colour, RT frame, LT undo, L3 brush, B exit.
  - **How sharp it looks in the dungeon:** heroes are drawn at the same size whatever the skin's size, about 30 to 80 screen pixels tall depending on the screen. A 120 x 140 skin shows in full in the editor and the marketplace previews; in the dungeon the game draws it as sharp as the screen allows. While a detailed skin is on screen, the game draws at the screen's full resolution instead of its usual chunky pixels, and the rest of the game looks the same.
  - **Detail limit:** detailed skins are stored compressed. The editor shows how much of the limit a skin uses (DATA %). Large patches of one colour take very little space, and pixel-by-pixel noise takes the most. If a skin is over 100% it can't be saved until it's simplified or made smaller.
- **MARKETPLACE** shows skins other players uploaded, in **NEW**, **POPULAR** (most worn) and **MY SKINS** (everything saved on this device), with a search. Pick one to **wear it**, **save it**, or **report it**. In My Skins you can wear, edit, rename, delete, upload, or take your own upload back down.

Skins work everywhere heroes appear: the title screen, solo runs, the companion bot (customize Player 2), and online co-op, where everyone sees what everyone else is wearing. Detailed skins are sent to each player once when they join, so they don't slow the game down.

**Drawing in another app.** `skin-template.png` (also downloadable from the sprite editor) is a 240 x 140 sheet with frame 1 on the left and frame 2 on the right.
- Paint each 10 x 10 square for a classic 12 x 14 skin, or use every pixel for full 120 x 140 detail.
- The game reads any image shaped like 24 x 14 (or 12 x 14 for a single frame), at any whole-number size up.
- It picks the smallest skin size that keeps all your detail. Put the size in the file name, as in `knight-36x42.png`, to choose it yourself. The editor's EXPORT names files that way, so they come back at the same size.
- The grid lines and grey outline in the template are see-through enough to be ignored on import.

### Switching on the marketplace (Supabase, free)

The editor and My Skins work straight away. Sharing skins between players needs a small database, and the free Supabase plan is plenty.

1. Make a free account at https://supabase.com and create a **new project** (any name, the region nearest your players, any database password).
2. In the project, open **SQL Editor**, choose **New query**, paste in all of `supabase-setup.sql` and press **Run**. It should finish with "Success. No rows returned". If you set the marketplace up with an older version of this file, run the new one once more. It adds accounts and reviews and keeps your existing skins; any skins reported before go on the review list.
3. Find the project's **URL** (it looks like `https://abcdefghijkl.supabase.co`) and its **publishable key** (starts with `sb_publishable_`). Both are under the project's **API Keys** settings or the **Connect** button. An older `anon` key also works. Never use the `secret` or `service_role` key, because that one bypasses every rule.
4. In the GitHub repo, edit `config.js` and paste both values between the quotes. Also fill in `siteUrl` with your GitHub Pages address; the desktop app reads the patron list from it. Commit, and a minute later the marketplace is live.
5. Set the password for your HOLDEN account (see **Accounts** below).

The publishable key is meant to be public. The database rules in `supabase-setup.sql` only let players read visible skins, and every upload, report, wear count or removal goes through checks:
- names are letters and numbers only, with no blocked words;
- skin data must be valid, and both frames must have something drawn;
- each device can upload 5 skins an hour, each network 10 an hour;
- exact copies of an existing skin are refused;
- only the device that uploaded a skin can take it down.

**Free projects go to sleep** after a week with too little activity. `.github/workflows/marketplace-keepalive.yml` reads one skin every two days to prevent that. It uses the values in `config.js`, so it needs no setup. If the project ever does pause, open it in the Supabase dashboard and press **Resume project**.

### Accounts

Uploading a skin needs an account. Open **ACCOUNT** on the title screen to sign in or create one: a name of 3 to 12 letters, numbers or `_`, and a password of 6 or more characters. Typing happens in a real text box, so phone keyboards and password managers work.
- **Where your account name shows:** on every skin you upload, and next to your hero in online lobbies.
- **Name tags:** players with an account show their name (`@ALICE`) in the lobby. The creator account shows a gold **★ CREATOR** tag, and a gold star over its hero during runs.
- **Faking it is blocked:** tags are checked against the server with a short-lived ticket, so nobody can claim to be you.
- **Security:** passwords are stored only as bcrypt hashes. After 8 wrong passwords from one connection, sign-in from it is locked for 15 minutes.
- **IP addresses:** each account is linked to every internet address it's used from, and each address can create at most 3 accounts a day.

**Your account, HOLDEN.** `supabase-setup.sql` creates the account **HOLDEN** with the creator role, so nobody else can take the name. It has no password yet: you set it privately, so it never sits in your public repository.
1. In Supabase's **SQL Editor**, choose **New query** and run this, with your own password:

   ```sql
   select public.acct_set_password('HOLDEN', 'your password here');
   ```

2. Don't save that query.
3. Sign in from the game's **ACCOUNT** screen.

Running the same line again changes the password and signs you out everywhere. It works for any account, if a player forgets theirs. To give someone else a tag, run `update accounts set role = 'admin' where name = 'THEIRNAME';`. Admins get a blue MOD tag, and like the creator, reports never pause them.

### Moderation

Skins appear in the marketplace as soon as they're uploaded. Any player can report one, and the reporter stops seeing it immediately.

- **The first report** puts the skin **under review**, and **pauses its uploader**: they can't publish new skins until you've looked at it. Their account screen tells them why.
- **Shopkeepers** never wear a skin that has been reported, even once, until you approve it. A skin with no reports can be picked straight away.
- **Three reports** from different players also take it out of the marketplace until you review it.
- **While a skin is under review**, its uploader can't delete it to dodge the review.

**Reviewing.** The `skins_to_review` view in the Table Editor lists everything waiting, with the reasons given (offensive, stolen art or spam). Look at a skin in the game's marketplace, or paste its `data` into the editor via a saved skin. Then in the **SQL Editor** run one of:

```sql
select approve_skin('the skin id');
select reject_skin('the skin id');
```

You can also change the skin's `review` column to `approved` or `rejected` in the Table Editor; it does the same thing.

- **Approved:** the skin is protected. It's back in the marketplace, shops may use it, later reports can't hide it, and the uploader can publish again once none of their other skins are waiting.
- **Rejected:** the skin is hidden for good.
  - **The uploader is banned from publishing**, and so is every internet address their account has used. Any account on those addresses can't publish either, including new ones.
  - **Every player who wore the skin in a public lobby gets a pop-up** the next time they're on a menu screen. It tells them the skin was banned and removes it from their wardrobe. The game records who wore which marketplace skin when they're in a public lobby; private lobbies and solo play aren't recorded.

To lift a ban, run `select unban_account('NAME');`, which also clears the address bans. Banned players can still play, make skins for themselves and wear other people's skins.

- **Address bans:** shared connections, like a school's, can be caught by an address ban. Use `unban_account` if that happens.
- **Fake reports:** a fake report only pauses someone until you review it, and only the creator and admins are immune.

Other tables: `blocked_words` (words that can't appear in skin or account names; add your own rows), `accounts` and `account_ips` (who's who), `skin_reports`, `skin_uses`, `skin_ip_bans`. To change how many reports take a skin out of the marketplace, edit `report_limit` in `supabase-setup.sql` and run the file again.

## Desktop app (Windows)

`Crawlmates-1.0.0-portable.exe` is the whole game as a Windows program: double-click it, no install needed. It's the same game as the website, built with Electron.
- **Window:** F11 switches fullscreen, and Patreon and other links open in your normal browser.
- **Voice chat:** uses the microphone after Windows asks once.
- **Saves:** kept in the app's own data folder, separate from the browser's.

Online co-op works between the app, the website and phones, since they all use the same lobbies.

**Building it yourself.** The `desktop` folder is the Electron project. The easy way is GitHub:
1. Open the **Actions** tab, pick **Build the Windows app**, and press **Run workflow**.
2. A few minutes later, the run's page has `Crawlmates-Windows` to download, with both a portable `.exe` and an installer.

That build uses your repo's `config.js`, so it connects to your marketplace. To publish a download page, push a tag like `v1.0.1`, and the same workflow creates a GitHub Release with both files.

To build on your own computer, install Node.js 20, then in the `desktop` folder run `npm ci` and `npm run build:win`. The files land in `desktop/dist`. `npm start` runs the app without building.

The exe in this download was built before your `config.js` had values, so its marketplace and accounts aren't connected. Rebuild it with the workflow after filling in `config.js`.

Windows may show "Windows protected your PC" the first time, because the exe isn't code-signed: choose **More info → Run anyway**. Signing needs a paid certificate. If you get one, see electron-builder's docs on `win.certificateFile`.

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
