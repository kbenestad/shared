#!/usr/bin/env bash
#
# Pocket Desktop setup — tune a Debian/XFCE container for a phone screen.
# Companion to https://kbenestad.github.io/shared/desk/
#
# Run this INSIDE the Debian container, from a terminal INSIDE the running
# XFCE desktop. The appearance settings talk to the running session, so a
# plain `proot-distro login` shell cannot apply them.
#
# Everything here is re-runnable. Nothing is deleted; files this script
# replaces are backed up alongside the original with a .bak suffix.

set -u

# ---------------------------------------------------------------- helpers ---

if [ -t 1 ]; then
    B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; Z=$'\033[0m'
else
    B=''; G=''; Y=''; R=''; Z=''
fi

say()  { printf '%s\n' "$*"; }
head2() { printf '\n%s== %s ==%s\n' "$B" "$*" "$Z"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$Z" "$*"; }
err()  { printf '  %s✗%s %s\n' "$R" "$Z" "$*"; }

ask() {
    # ask "question" [default y|n] -> returns 0 for yes
    local q="$1" def="${2:-y}" prompt reply
    case "$def" in y) prompt="[Y/n]";; *) prompt="[y/N]";; esac
    printf '%s %s ' "$q" "$prompt"
    read -r reply || return 1
    reply="${reply:-$def}"
    case "$reply" in [Yy]*) return 0;; *) return 1;; esac
}

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        err "Not running as root and sudo is not installed."
        err "Re-run this as root inside the container."
        exit 1
    fi
fi

APT_UPDATED=0
apt_install() {
    if [ "$APT_UPDATED" -eq 0 ]; then
        say "  updating package lists..."
        $SUDO apt-get update -qq || { err "apt-get update failed"; return 1; }
        APT_UPDATED=1
    fi
    say "  installing: $*"
    $SUDO apt-get install -y -qq "$@" || { err "install failed: $*"; return 1; }
}

# Can we reach the running XFCE session's settings daemon?
have_session() {
    command -v xfconf-query >/dev/null 2>&1 &&
    xfconf-query -c xfwm4 -l >/dev/null 2>&1
}

require_session() {
    if have_session; then
        return 0
    fi
    err "Cannot reach the XFCE settings daemon."
    err "Run this from a terminal INSIDE the running desktop, not from"
    err "a plain container login shell. Skipping this section."
    return 1
}

# xfconf 4.20 still needs -n to create a property that does not exist yet.
setq() {
    local channel="$1" prop="$2" type="$3" value="$4"
    if xfconf-query -c "$channel" -p "$prop" -n -t "$type" -s "$value" 2>/dev/null; then
        ok "$channel $prop = $value"
    else
        warn "could not set $channel $prop (continuing)"
    fi
}

backup_if_exists() {
    [ -e "$1" ] || return 0
    cp -p "$1" "$1.bak" 2>/dev/null && warn "existing $1 backed up to $1.bak"
}

ARCH="$(dpkg --print-architecture 2>/dev/null || echo arm64)"

# ---------------------------------------------------------------- sections ---

sec_maximise() {
    head2 "Windows open maximised"
    apt_install devilspie2 || return 1

    mkdir -p "$HOME/.config/devilspie2"
    local lua="$HOME/.config/devilspie2/maximise.lua"
    backup_if_exists "$lua"
    cat > "$lua" <<'LUA'
if (get_window_type() == "WINDOW_TYPE_NORMAL") then
   maximize()
end
LUA
    ok "rule written to $lua"

    mkdir -p "$HOME/.config/autostart"
    local desktop="$HOME/.config/autostart/devilspie2.desktop"
    backup_if_exists "$desktop"
    cat > "$desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=devilspie2
Exec=devilspie2
X-GNOME-Autostart-enabled=true
DESKTOP
    ok "will start with the desktop"

    if [ -n "${DISPLAY:-}" ] && ! pgrep -x devilspie2 >/dev/null 2>&1; then
        devilspie2 >/dev/null 2>&1 &
        ok "started now (open something to test)"
    fi
}

sec_space() {
    head2 "Reclaim screen space"
    require_session || return 1
    setq xfwm4 /general/titleless_maximize bool true
    setq xfwm4 /general/borderless_maximize bool true
    setq xfwm4 /general/use_compositing bool false
    setq xfce4-panel /panels/panel-1/autohide-behavior int 1
    say ""
    warn "In TERMUX itself (not the container): Volume Up + Q hides the"
    warn "extra keys row. That space is Termux's, not the desktop's."
}

sec_size() {
    head2 "Size controls for fingers"
    require_session || return 1
    say "  Not touching display scaling: XFCE only does 1x or 2x, and 2x"
    say "  wastes the screen. Enlarging chrome only works far better."
    setq xsettings /Gtk/FontName string "Sans 13"
    setq xsettings /Gtk/CursorThemeSize int 32
    setq xsettings /Net/DndDragThreshold int 24
    setq xsettings /Net/DoubleClickTime int 500
    setq xfce4-panel /panels/panel-1/size int 96
    setq xfwm4 /general/title_font string "Sans Bold 15"
    setq xfwm4 /general/button_layout string "|MC"
    setq thunar /misc-single-click bool true
    say ""
    warn "Set Pointer -> Direct Touch in the Termux:X11 notification too."
}

sec_epiphany() {
    head2 "Epiphany (GNOME Web)"
    apt_install epiphany-browser && ok "installed — the browser that fits this screen"
}

sec_vivaldi() {
    head2 "Vivaldi"
    apt_install wget gnupg || return 1
    local key=/usr/share/keyrings/vivaldi.gpg
    if [ ! -s "$key" ]; then
        wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub \
            | $SUDO gpg --dearmor -o "$key" || { err "could not fetch signing key"; return 1; }
        ok "signing key installed"
    else
        ok "signing key already present"
    fi
    printf 'deb [signed-by=%s arch=%s] https://repo.vivaldi.com/archive/deb/ stable main\n' \
        "$key" "$ARCH" | $SUDO tee /etc/apt/sources.list.d/vivaldi.list >/dev/null
    ok "repository configured for $ARCH"
    APT_UPDATED=0
    apt_install vivaldi-stable && ok "installed (about 450 MB)"
}

sec_onlyoffice() {
    head2 "OnlyOffice"
    if command -v desktopeditors >/dev/null 2>&1; then
        ok "already installed"
        return 0
    fi
    say "  This downloads about 350 MB and uses roughly 1.3 GB installed."
    ask "  Continue?" y || { warn "skipped"; return 0; }
    apt_install wget || return 1
    local url="https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_${ARCH}.deb"
    local tmp="/tmp/onlyoffice-${ARCH}.deb"
    say "  downloading..."
    wget -q --show-progress -O "$tmp" "$url" || { err "download failed"; return 1; }
    $SUDO apt-get install -y "$tmp" || { err "install failed"; rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    ok "installed"
}

sec_gnome() {
    head2 "GNOME apps for small screens"
    say "  These use libadwaita, which reflows to a single column when narrow."
    apt_install gnome-console nautilus gnome-calculator gnome-weather \
        gnome-maps gnome-clocks gnome-text-editor gnome-contacts gnome-calendar \
        && ok "installed"
    warn "No location service here — set your city by hand in Weather and Maps."
}

sec_gtk4() {
    head2 "GTK4 software renderer"
    say "  GTK4 draws through OpenGL by default. With no GPU that path is"
    say "  emulated and feels awful; the cairo renderer is much faster here."
    local line='export GSK_RENDERER=cairo'
    if grep -qxF "$line" "$HOME/.profile" 2>/dev/null; then
        ok "already set in ~/.profile"
    else
        printf '%s\n' "$line" >> "$HOME/.profile"
        ok "added to ~/.profile"
    fi
    if [ "${GSK_RENDERER:-}" = "cairo" ]; then
        ok "active in this shell"
    else
        warn "Not active yet. Restart the desktop, then run: echo \$GSK_RENDERER"
        warn "If it stays empty, your session does not read ~/.profile — launch"
        warn "apps as: GSK_RENDERER=cairo nautilus"
    fi
}

# -------------------------------------------------------------------- menu ---

run_all() {
    sec_maximise; sec_space; sec_size
    sec_epiphany; sec_vivaldi; sec_onlyoffice; sec_gnome; sec_gtk4
}

menu() {
    cat <<'MENU'

  Pocket Desktop setup
  --------------------
   1  Windows open maximised        (devilspie2)
   2  Reclaim screen space          (title bars, borders, panel)
   3  Size controls for fingers     (fonts, panel, tap behaviour)
   4  Epiphany — lightweight browser
   5  Vivaldi — full browser
   6  OnlyOffice
   7  GNOME apps for small screens
   8  GTK4 software renderer
   a  Everything above
   q  Quit
MENU
}

say "${B}Pocket Desktop setup${Z}"
say "Debian container, XFCE, tuned for a phone screen."
if have_session; then
    ok "XFCE session reachable — appearance settings will apply"
else
    warn "No XFCE session detected. Package installs will still work;"
    warn "sections 2 and 3 need a terminal inside the running desktop."
fi

while true; do
    menu
    printf '\n  choose: '
    read -r choice || break
    case "$choice" in
        1) sec_maximise ;;
        2) sec_space ;;
        3) sec_size ;;
        4) sec_epiphany ;;
        5) sec_vivaldi ;;
        6) sec_onlyoffice ;;
        7) sec_gnome ;;
        8) sec_gtk4 ;;
        a|A) run_all ;;
        q|Q|"") say ""; say "Done. Restart the desktop for everything to take effect."; break ;;
        *) err "no such option: $choice" ;;
    esac
done
