#!/bin/bash

# ==============================================================================
#
#  Enhanced Setup Script
#
#  This script automates the installation of:
#    1. Custom fonts from a local directory.
#    2. Zsh (Z Shell).
#    3. Oh My Zsh and the Powerlevel10k theme.
#    4. FNM (Fast Node Manager).
#    5. pyenv (Python Version Manager).
#
#  Usage: ./setup.sh
#
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Source directory for the fonts.
readonly FONT_DIR="./fonts"
# System-wide installation directory for custom fonts.
# Using ${HOME} instead of ~ for better script compatibility.
readonly FONT_INSTALL_DIR="${HOME}/.local/share/fonts"

# --- Helper Functions ---

# Print a formatted header message.
print_header() {
    echo ""
    echo "===================================================================="
    echo "  $1"
    echo "===================================================================="
}

# --- Installation Functions ---

# 1. Install custom fonts.
install_fonts() {
    print_header "Installing Custom Fonts"

    if [ ! -d "$FONT_DIR" ]; then
        echo "Error: Source font directory '$FONT_DIR' not found. Skipping font installation."
        return 1
    fi

    # Use 'find' to robustly locate .ttf and .otf files.
    local font_files
    font_files=$(find "$FONT_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \))

    if [ -z "$font_files" ]; then
        echo "No .ttf or .otf files found in '$FONT_DIR'. Nothing to install."
        return 0
    fi

    echo "Found $(echo "$font_files" | wc -l) font(s) to install."

    echo "Creating system font directory: $FONT_INSTALL_DIR"
    mkdir -p "$FONT_INSTALL_DIR"

    echo "Copying fonts..."
    # Use find to pipe files to cp for better handling of filenames.
    find "$FONT_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp -v {} "$FONT_INSTALL_DIR/" \;

    echo "Updating font cache..."
    fc-cache -f -v

    echo "Font installation complete!"
}

# 2. Install Zsh.
install_zsh() {
    print_header "Installing Zsh"

    # Check if Zsh is already installed.
    if command -v zsh &> /dev/null; then
        echo "Zsh is already installed. Version: $(zsh --version)"
        return 0
    fi

    echo "Zsh not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y zsh

    echo "Zsh installation complete."
}

# 3. Install Oh My Zsh and Powerlevel10k theme.
install_oh_my_zsh_p10k() {
    print_header "Installing Oh My Zsh + Powerlevel10k"

    # Oh My Zsh requires git and zsh.
    if ! command -v git &> /dev/null; then
        echo "Git not found. Installing git..."
        sudo apt-get update
        sudo apt-get install -y git
    fi
    install_zsh # Ensure zsh is installed

    local oh_my_zsh_dir="${HOME}/.oh-my-zsh"
    local p10k_dir="${oh_my_zsh_dir}/custom/themes/powerlevel10k"

    # Install Oh My Zsh if not already installed.
    if [ ! -d "$oh_my_zsh_dir" ]; then
        echo "Installing Oh My Zsh..."
        # Use --unattended to prevent the installer from changing the shell and running zsh.
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "Oh My Zsh is already installed."
    fi

    # Install Powerlevel10k theme if not already installed.
    if [ ! -d "$p10k_dir" ]; then
        echo "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        echo "Powerlevel10k theme is already installed."
    fi

    # Set Powerlevel10k as the theme in .zshrc.
    local zshrc_file="${HOME}/.zshrc"
    if grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$zshrc_file"; then
        echo "Powerlevel10k theme is already set in .zshrc."
    else
        echo "Setting Powerlevel10k theme in .zshrc..."
        # Use sed to replace the theme line. This is safer than appending.
        sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc_file"
    fi

    # Change the default shell to Zsh.
    if [ "$(basename "$SHELL")" != "zsh" ]; then
        echo "Changing default shell to Zsh..."
        chsh -s "$(which zsh)"
        echo "Shell changed to Zsh. Please log out and log back in for the change to take effect."
    else
        echo "Default shell is already Zsh."
    fi
    
    echo "Oh My Zsh and Powerlevel10k setup complete!"
    echo "Run 'p10k configure' in your new Zsh terminal to customize your prompt."
}

# 4. Install FNM (Fast Node Manager).
install_fnm() {
    print_header "Installing FNM (Fast Node Manager)"

    # Check if fnm is already in the path
    if command -v fnm &> /dev/null; then
        echo "FNM is already installed and available in your PATH."
        return 0
    fi

    echo "Installing FNM..."
    # The installation script will attempt to update your shell configuration.
    curl -fsSL https://fnm.vercel.app/install | bash

    echo ""
    echo "FNM installation script has completed."
    echo "Please restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc'"
    echo "for the changes to take effect and to start using the 'fnm' command."
}

# 5. Install pyenv
install_pyenv() {
    print_header "Installing pyenv"

    if [ -d "${HOME}/.pyenv" ]; then
        echo "pyenv appears to be already installed in ~/.pyenv. Skipping."
        return 0
    fi

    echo "Installing pyenv dependencies for building Python..."
    # Install dependencies required to build Python versions with pyenv
    sudo apt-get update
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    echo "Running pyenv installer script..."
    curl https://pyenv.run | bash

    echo ""
    echo "pyenv installation script finished."
    echo "Adding pyenv configuration to shell startup files..."

    # The pyenv installer script should add the necessary config to .bashrc.
    # We will ensure it's also in .zshrc for Zsh users.
    local zshrc_file="${HOME}/.zshrc"
    if [ -f "$zshrc_file" ]; then
        if ! grep -q 'PYENV_ROOT' "$zshrc_file"; then
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$zshrc_file"
            echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> "$zshrc_file"
            echo 'eval "$(pyenv init -)"' >> "$zshrc_file"
            echo "Configuration added to .zshrc"
        fi
    fi

    echo "Please restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc'"
    echo "for the changes to take effect."
}


# --- Menu and Main Execution ---

# Display the main menu to the user.
show_menu() {
    clear
    print_header "Interactive Setup Menu"
    echo "Please select an option by entering its number:"
    echo ""
    echo "   [1] Install Custom Fonts"
    echo "   [2] Install Zsh"
    echo "   [3] Install Oh My Zsh + Powerlevel10k"
    echo "   [4] Install FNM (Fast Node Manager)"
    echo "   [5] Install pyenv"
    echo "   [6] Exit Script"
    echo ""
}

# Main function to drive the menu.
main() {
    while true; do
        show_menu
        read -p "Enter your choice [1-6]: " choice

        case $choice in
            1)
                install_fonts
                ;;
            2)
                install_zsh
                ;;
            3)
                install_oh_my_zsh_p10k
                ;;
            4)
                install_fnm
                ;;
            5)
                install_pyenv
                ;;
            6)
                echo "Exiting setup script. Goodbye!"
                break
                ;;
            *)
                echo "Invalid option '$choice'. Please try again."
                sleep 2 # Pause briefly to show the error message.
                continue # Skip the "Press Enter" prompt for invalid options.
                ;;
        esac

        echo ""
        read -p "Press [Enter] to return to the menu..."
    done

    print_header "Setup script finished!"
}

# Run the main function.
main

