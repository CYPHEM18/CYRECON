# CYRECON

Automated reconnaissance framework for subdomain enumeration, live host checking, and URL discovery — built as a single Bash pipeline.

CYRECON chains together industry-standard recon tools (Subfinder, AssetFinder, crt.sh, httpx, waybackurls) so a full recon sweep of a domain — subdomains, live hosts, and historical URLs — runs from one script instead of five separate commands.

## Features

- **Subdomain enumeration** — merges results from Subfinder, AssetFinder, and crt.sh, deduplicated
- **Live host checking** — probes a target with httpx and reports status code, title, content length, and redirects
- **URL discovery** — pulls historical URLs via waybackurls and filters for live ones
- **Run All Recon** — runs the full pipeline end-to-end and writes organized output to a per-target folder
- **Automatic dependency installation** — checks for required tools on startup and installs anything missing (works on both Debian/Kali via `apt` and Termux via `pkg`)

## Requirements

CYRECON installs its own dependencies automatically on first run. If you'd rather install them yourself first:

| Tool | Purpose |
|---|---|
| [subfinder](https://github.com/projectdiscovery/subfinder) | Passive subdomain enumeration |
| [assetfinder](https://github.com/tomnomnom/assetfinder) | Additional subdomain enumeration |
| [httpx](https://github.com/projectdiscovery/httpx) | Live host probing |
| [waybackurls](https://github.com/tomnomnom/waybackurls) | Historical URL discovery |
| `jq` | JSON parsing (crt.sh output) |
| `curl` | HTTP requests |
| Go (1.20+) | Required to install the tools above |

## Installation

```bash
git clone https://github.com/CYPHEM18/cyrecon.git
cd cyrecon
chmod +x cyrecon.sh
./cyrecon.sh
```

On first run, CYRECON checks for Go, `jq`, `curl`, and the four recon tools above. Anything missing is installed automatically — via `apt` on Debian/Kali or `pkg` on Termux — and Go's bin directory is added to your shell's PATH if it isn't already there.

## Usage

Run the script and choose an option from the menu:

```
[1] Subdomain Enumeration
[2] Live Host Check
[3] URL Checking
[4] Run All Recon
[5] Re-check / Install Required Tools
[0] Exit
```

**Run All Recon** (option 4) is the main workflow — give it a domain and it creates a `recon_<domain>/` folder containing:

```
recon_<domain>/
├── subs.txt      # deduplicated subdomains
├── live.txt      # live hosts with status/title/length
├── url.txt       # historical URLs from waybackurls
└── liveUrl.txt   # URLs that returned 200/302/403
```

## Example

```bash
./cyrecon.sh
# choose [4], enter: example.com
```

## Disclaimer

CYRECON is intended for authorized security testing and bug bounty programs only. Only run it against targets you own or have explicit written permission to test. The author is not responsible for misuse.

## Author

**Odejide Femisola Francis (Cyphem)**
Junior Penetration Tester — Web & API Security, Bug Bounty Hunter

- GitHub: [@CYPHEM18](https://github.com/CYPHEM18)
- LinkedIn: [femisola-odejide](https://www.linkedin.com/in/femisola-odejide-a3ab1135b)

## License

MIT — free to use, modify, and distribute. See `LICENSE` for details.
