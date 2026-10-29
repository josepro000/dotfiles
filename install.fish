#!/usr/bin/env fish
# Instalador de dotfiles: alacritty + sway + noctalia
# Uso: ./install.fish [--packages] [--no-backup]

set dotfiles_dir (cd (dirname (status --current-filename)); and pwd)
set config_dir $HOME/.config
if set -q XDG_CONFIG_HOME
    set config_dir $XDG_CONFIG_HOME
end
set backup_dir $HOME/.dotfiles_backup/(date +%Y%m%d_%H%M%S)

# Carpetas dentro de ./config que se enlazan a ~/.config
set apps alacritty sway noctalia

set install_packages false
set do_backup true

for arg in $argv
    switch $arg
        case --packages
            set install_packages true
        case --no-backup
            set do_backup false
        case -h --help
            echo "Uso: $argv[0] [--packages] [--no-backup]"
            echo "  --packages   instala paquetes (Arch/pacman + AUR helper)"
            echo "  --no-backup  no respalda configuraciones existentes"
            exit 0
        case '*'
            echo "Opción desconocida: $arg"
            exit 1
    end
end

function log
    set_color -o blue; echo -n "==> "; set_color normal; echo $argv
end

function warn
    set_color -o yellow; echo -n "!! "; set_color normal; echo $argv
end

function install_pkgs
    if not command -q pacman
        warn "No es Arch/pacman. Instala manualmente: sway alacritty noctalia-shell"
        return
    end
    log "Instalando paquetes oficiales..."
    sudo pacman -S --needed --noconfirm sway alacritty swaybg swayidle swaylock \
        xdg-desktop-portal-wlr ttf-jetbrains-mono-nerd

    set aur ""
    for h in paru yay
        if command -q $h
            set aur $h
            break
        end
    end
    if test -n "$aur"
        log "Instalando noctalia-shell desde AUR con $aur..."
        $aur -S --needed --noconfirm noctalia-shell
    else
        warn "No hay paru/yay. Instala noctalia-shell desde AUR manualmente."
    end
end

function link_app
    set app $argv[1]
    set src $dotfiles_dir/config/$app
    set dest $config_dir/$app

    if not test -e $src
        warn "No existe $src, se omite."
        return
    end

    # Ya está enlazado correctamente
    if test -L $dest; and test (readlink -f $dest) = (readlink -f $src)
        log "$app ya está enlazado."
        return
    end

    # Respaldo
    if test -e $dest; or test -L $dest
        if test $do_backup = true
            mkdir -p $backup_dir
            mv $dest $backup_dir/
            log "Respaldo de $app en $backup_dir"
        else
            rm -rf $dest
        end
    end

    mkdir -p $config_dir
    ln -s $src $dest
    log "Enlazado $dest -> $src"
end

if test $install_packages = true
    install_pkgs
end

for app in $apps
    link_app $app
end

log "Listo. Cierra sesión y entra a Sway, o recarga con: swaymsg reload"
