# Crawlmates

A pixel dungeon crawler for one or two players: fog of war, telegraphed combat, a skill tree, bosses every third floor and a story that ends on floor 15 (then the depths go on forever).

The whole game is `index.html`. `peerjs.min.js` is only used for online co-op.

## Put it on GitHub Pages

1. Create a new public repository on GitHub (for example `crawlmates`).
2. Upload `index.html`, `peerjs.min.js`, `PEERJS-LICENSE` and this `README.md` to the root of the repository.
3. Open **Settings → Pages**. Under **Build and deployment**, set **Source** to *Deploy from a branch*, pick **main** and **/ (root)**, and save.
4. After a minute the game is live at `https://<your-username>.github.io/<repo-name>/`.

Pages are served over HTTPS, which online play needs.

## Ways to play

| Mode | How |
|---|---|
| Solo | Press Enter. A companion bot fights beside you (turn it off with **B** on the title screen). |
| Couch co-op | Connect two controllers. Player 2 presses **Start**. The screen splits. |
| Online co-op | Both players open the GitHub page. One picks **O → Host a game** and reads out the 5-letter room code; the other picks **O → Join a game** and types it. |

## How online play works

- The host's browser runs the game. The guest sends button presses and draws what the host sends back about 15 times a second (about 4 KB each). The guest moves their own hero locally, so movement feels instant.
- The two browsers find each other through the free public PeerJS matchmaking server, then talk directly (WebRTC). No server of your own is needed.
- Each player keeps their own look, upgrades and journal. Knowledge earned is added to each player's own save.
- If the guest disconnects, a bot takes over their hero and the host keeps playing.

### If players can't connect

Direct connections use public STUN servers, which work on most home networks. Some strict networks (some offices, schools, mobile carriers) block direct connections. If that happens:

- Try a different network (for example a phone hotspot), or
- Add a TURN relay server. In `index.html`, search for `PEER_OPTS` and add your TURN server to `iceServers`, for example:
  ```js
  {urls:'turn:your.turn.server:3478',username:'user',credential:'pass'}
  ```

The room code only works while the host has the online screen or game open.

## Saves

Progress (Knowledge, upgrades, journal, hero look, best floor) is saved in the browser's local storage for the site it's played on. Playing from a different address or browser starts fresh.

## Credits

PeerJS is MIT licensed (see `PEERJS-LICENSE`).
