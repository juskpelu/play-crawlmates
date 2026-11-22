#!/usr/bin/env python3
"""Rebuild credits.json from Patreon: every active patron at $5 (500 cents) or more.

Run by .github/workflows/patreon-credits.yml. Needs only the Python standard library.

Environment:
  PATREON_ACCESS_TOKEN   Creator's Access Token (required)
  PATREON_REFRESH_TOKEN  Creator's Refresh Token  } optional: used to get a new access
  PATREON_CLIENT_ID      Client ID               } token when the old one has expired
  PATREON_CLIENT_SECRET  Client Secret           }
  MIN_CENTS              Minimum pledge in cents (default 500 = $5)

Patron names are never printed, because GitHub Actions logs can be public.
"""
import json, os, sys, urllib.error, urllib.parse, urllib.request
from datetime import date

API = "https://www.patreon.com/api/oauth2/v2"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "credits.json")
OVERRIDES = os.path.join(ROOT, "credits-overrides.json")
NEW_TOKENS = os.path.join(ROOT, ".new-patreon-tokens.json")  # picked up by the workflow, never committed
MIN_CENTS = int(os.environ.get("MIN_CENTS", "500"))
token = os.environ.get("PATREON_ACCESS_TOKEN", "").strip()


def refresh():
    """Swap the refresh token for a new access token. Returns True on success."""
    global token
    rt, cid, cs = (os.environ.get(k, "").strip() for k in ("PATREON_REFRESH_TOKEN", "PATREON_CLIENT_ID", "PATREON_CLIENT_SECRET"))
    if not (rt and cid and cs):
        return False
    body = urllib.parse.urlencode({"grant_type": "refresh_token", "refresh_token": rt, "client_id": cid, "client_secret": cs}).encode()
    req = urllib.request.Request("https://www.patreon.com/api/oauth2/token", data=body, headers={"User-Agent": "Crawlmates-Credits"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            j = json.load(r)
    except urllib.error.HTTPError as e:
        print(f"Token refresh failed: HTTP {e.code}", file=sys.stderr)
        return False
    token = j["access_token"]
    with open(NEW_TOKENS, "w") as f:  # Patreon may rotate the refresh token too, so keep both
        json.dump({"access_token": j["access_token"], "refresh_token": j.get("refresh_token", rt)}, f)
    print("Got a fresh access token from the refresh token.")
    return True


def get(url, retried=False):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}", "User-Agent": "Crawlmates-Credits"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        if e.code == 401 and not retried and refresh():
            return get(url, True)
        detail = e.read().decode(errors="replace")[:300]
        sys.exit(f"Patreon API error {e.code} for {url.split('?')[0]}: {detail}")


def main():
    if not token and not refresh():
        sys.exit("Set the PATREON_ACCESS_TOKEN secret (see README, 'Patreon credits').")

    campaigns = get(f"{API}/campaigns").get("data", [])
    if not campaigns:
        sys.exit("No campaign found for this token. Make sure it is the creator token for Crawlmates.")
    cid = campaigns[0]["id"]

    q = urllib.parse.urlencode({
        "include": "currently_entitled_tiers",
        "fields[member]": "full_name,patron_status,currently_entitled_amount_cents",
        "fields[tier]": "amount_cents,title",
        "page[count]": "500",
    })
    url, members, tiers = f"{API}/campaigns/{cid}/members?{q}", [], {}
    while url:
        page = get(url)
        members += page.get("data", [])
        for inc in page.get("included", []):
            if inc.get("type") == "tier":
                tiers[inc["id"]] = inc.get("attributes", {}).get("amount_cents") or 0
        url = page.get("links", {}).get("next")

    ov = {}
    if os.path.exists(OVERRIDES):
        with open(OVERRIDES) as f:
            ov = json.load(f)
    hide = {n.strip().lower() for n in ov.get("hide", [])}
    rename = {k.strip().lower(): v for k, v in ov.get("rename", {}).items()}
    style = ov.get("name_style", "full")  # "full", "first" or "first_initial"

    names = []
    for m in members:
        a = m.get("attributes", {})
        if a.get("patron_status") != "active_patron":
            continue
        # Tier prices are in the campaign's currency; the pledge amount is in the patron's own currency,
        # so go by the tier when there is one and fall back to the pledge for custom amounts.
        tids = [t["id"] for t in m.get("relationships", {}).get("currently_entitled_tiers", {}).get("data", [])]
        cents = max([tiers.get(t, 0) for t in tids], default=0) or (a.get("currently_entitled_amount_cents") or 0)
        if cents < MIN_CENTS:
            continue
        full = " ".join((a.get("full_name") or "").split())
        if not full or full.lower() in hide:
            continue
        if full.lower() in rename:
            names.append(rename[full.lower()])
            continue
        parts = full.split(" ")
        if style == "first":
            full = parts[0]
        elif style == "first_initial" and len(parts) > 1:
            full = f"{parts[0]} {parts[-1][0]}."
        names.append(full)

    names += ov.get("extra", [])
    names = sorted({n.strip()[:40] for n in names if n and n.strip()}, key=str.lower)

    old = []
    if os.path.exists(OUT):
        try:
            with open(OUT) as f:
                old = json.load(f).get("patrons", [])
        except (ValueError, OSError):
            pass
    print(f"{len(members)} members checked, {len(names)} on the credits list.")
    if names == old:
        print("No change to credits.json.")
        return
    with open(OUT, "w") as f:
        json.dump({"updated": date.today().isoformat(), "patrons": names}, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("credits.json updated.")


if __name__ == "__main__":
    main()
