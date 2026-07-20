# matrix.sh — 黑客帝國 (The Matrix) visual effects
#   sbx matrix          full Matrix experience
#   sbx matrix rain     digital rain only
#   sbx matrix logo     ASCII banner only

# ── Matrix Digital Rain ─────────────────────────────────────
matrix_rain() {
    local timeout=${1:-60}
    local chars="ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍ0123456789"
    local cols=$(tput cols 2>/dev/null || echo 80)
    local lines=$(tput lines 2>/dev/null || echo 24)
    local drops=()
    local i x y

    # Initialize drop positions
    for ((i=0; i<cols; i+=2)); do
        drops[$i]=$((RANDOM % lines))
    done

    tput civis 2>/dev/null
    stty -echo 2>/dev/null

    local start=$(date +%s)
    while true; do
        # Check timeout
        local now=$(date +%s)
        [[ $((now - start)) -ge $timeout ]] && break

        for ((x=0; x<cols; x+=2)); do
            y=${drops[$x]}
            # Draw head (bright)
            tput cup $y $x 2>/dev/null
            echo -ne "${c_bright}${chars:$((RANDOM % ${#chars})):1}${c_none}"
            # Draw trail (dim)
            tput cup $((y - 1)) $x 2>/dev/null 2>/dev/null
            echo -ne "${c_green}${chars:$((RANDOM % ${#chars})):1}${c_none}"
            # Fade older trail
            tput cup $((y - 3)) $x 2>/dev/null
            echo -ne "${c_dim}${chars:$((RANDOM % ${#chars})):1}${c_none}"
            # Clear behind
            tput cup $((y - 6)) $x 2>/dev/null
            echo -ne " "
            # Advance drop
            drops[$x]=$((y + 1))
            [[ ${drops[$x]} -gt $lines ]] && drops[$x]=$((RANDOM % (lines / 2)))
        done
    done

    tput cvvis 2>/dev/null
    stty echo 2>/dev/null
    clear
}

# ── Typewriter Effect ───────────────────────────────────────
_type() {
    local text="$1"
    local delay=${2:-0.02}
    local i
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${c_bright}${text:$i:1}${c_none}"
        sleep "$delay"
    done
    echo
}

# ── Glitch Reveal ───────────────────────────────────────────
_glitch() {
    local text="$1"
    local glitch_chars="▓▒░█▌▐▀▄■□◆◇○●◎◉◈◌◍◐◑◒◓◔◕"
    local glitch_len=${#glitch_chars}
    local i j

    # First pass: random glitch characters
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${c_dim}${glitch_chars:$((RANDOM % glitch_len)):1}"
    done
    echo -ne "\r"

    # Second pass: reveal text character by character
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${c_bright}${text:$i:1}${c_none}"
        sleep 0.01
    done
    echo
}

# ── Matrix ASCII Banner ─────────────────────────────────────
matrix_logo() {
    clear
    echo
    sleep 0.1
    echo -e "${c_bright}     s    b    x${c_none}"
    sleep 0.08
    echo -e "${c_dim}    ─────────────${c_none}"
    sleep 0.08
    echo
    sleep 0.06
    echo -e "  ${c_bright}sbx ${is_sh_ver}${c_none}"
    sleep 0.06
    echo -e "  ${c_dim}Next Generation sing-box Manager${c_none}"
    sleep 0.06
    echo -e "  ${c_accent}By: WAHSUN${c_none}"
    sleep 0.1
    echo
    sleep 0.2
}

# ── Matrix Pulse Line ───────────────────────────────────────
matrix_pulse() {
    local cols=$(tput cols 2>/dev/null || echo 80)
    local i c
    for ((i=0; i<cols; i++)); do
        c="${c_bright}█"
        [[ $((i % 8)) -eq 0 ]] && c="${c_dim}▓"
        [[ $((i % 16)) -eq 0 ]] && c="${c_green}░"
        echo -ne "$c"
        sleep 0.001
    done
    echo -e "${c_none}"
}

# ── Full Matrix Intro Sequence ──────────────────────────────
matrix_intro() {
    # Optional: brief rain (2 seconds)
    matrix_rain 2

    # Logo
    matrix_logo

    # Status line with typewriter
    echo -ne " ${c_dim}▐▌${c_none} "
    _type "connection established // $(date +%T)" 0.01

    # Core version with glitch
    echo -ne " ${c_dim}▐▌${c_none} "
    _glitch "sbx ${is_sh_ver} / sing-box ${is_core_ver} >> ${is_core_status}"

    # Pulse line
    matrix_pulse
    echo
}

# ── Main Entry Point ────────────────────────────────────────
matrix_set() {
    case ${1,,} in
    rain)
        matrix_rain 8
        ;;
    logo)
        matrix_logo
        ;;
    *)
        matrix_intro
        ;;
    esac
}
