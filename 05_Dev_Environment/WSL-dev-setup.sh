#!/bin/bash
# WSL Ubuntu Development Environment Setup
# Autor: Auto-generated Dev Environment
# Wersja: 1.0

set -e  # Zatrzymaj przy błędach

# Kolory dla output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funkcje pomocnicze
print_header() {
    echo -e "${MAGENTA}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Sprawdź czy skrypt jest uruchamiany w WSL
check_wsl() {
    if ! grep -qi microsoft /proc/version; then
        print_error "Ten skrypt musi być uruchomiony w WSL!"
        exit 1
    fi
    print_success "WSL Environment detected"
}

# Aktualizacja systemu
update_system() {
    print_header "Aktualizacja systemu Ubuntu"
    
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove -y
    sudo apt autoclean
    
    print_success "System zaktualizowany"
}

# Instalacja podstawowych narzędzi
install_basic_tools() {
    print_header "Instalacja podstawowych narzędzi"
    
    # Lista podstawowych pakietów
    local packages=(
        "build-essential"
        "git"
        "curl"
        "wget"
        "vim"
        "nano"
        "htop"
        "tree"
        "zip"
        "unzip"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "jq"
        "tmux"
        "screen"
        "neofetch"
        "bat"
        "exa"
        "fd-find"
        "ripgrep"
    )
    
    print_info "Instalacja pakietów: ${packages[*]}"
    sudo apt install -y "${packages[@]}"
    
    print_success "Podstawowe narzędzia zainstalowane"
}

# Instalacja Python
install_python() {
    print_header "Instalacja Python 3.11+"
    
    # Dodaj repository Python
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt update
    
    # Instalacja Python i pip
    sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
    
    # Ustawienie domyślnej wersji Python
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
    
    # Aktualizacja pip
    python -m pip install --upgrade pip
    
    # Instalacja popularnych bibliotek Python
    print_info "Instalacja bibliotek Python..."
    pip install --user \
        virtualenv \
        virtualenvwrapper \
        requests \
        flask \
        django \
        fastapi \
        numpy \
        pandas \
        matplotlib \
        seaborn \
        pytest \
        black \
        flake8 \
        autopep8 \
        jupyter \
        ipython \
        beautifulsoup4 \
        selenium \
        pillow \
        openpyxl \
        python-dotenv \
        rich \
        typer \
        pydantic
    
    print_success "Python i biblioteki zainstalowane"
}

# Instalacja Node.js
install_nodejs() {
    print_header "Instalacja Node.js"
    
    # Instalacja Node.js LTS
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    
    # Globalne pakiety npm
    npm install -g \
        yarn \
        pnpm \
        http-server \
        live-server \
        nodemon \
        pm2 \
        create-react-app \
        @vue/cli \
        @angular/cli \
        typescript \
        ts-node \
        eslint \
        prettier
    
    print_success "Node.js i pakiety zainstalowane"
}

# Instalacja GitHub CLI
install_gh_cli() {
    print_header "Instalacja GitHub CLI"
    
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
    
    print_success "GitHub CLI zainstalowane"
}

# Konfiguracja Git
configure_git() {
    print_header "Konfiguracja Git"
    
    # Sprawdź czy Git jest już skonfigurowany
    if git config --global user.email &>/dev/null; then
        print_info "Git jest już skonfigurowany"
        git config --global --list | grep user
    else
        print_info "Konfiguracja użytkownika Git"
        read -p "Podaj swój email Git: " git_email
        read -p "Podaj swoją nazwę Git: " git_name
        
        git config --global user.email "$git_email"
        git config --global user.name "$git_name"
    fi
    
    # Podstawowa konfiguracja Git
    git config --global init.defaultBranch main
    git config --global core.editor "vim"
    git config --global pull.rebase false
    git config --global color.ui auto
    git config --global core.autocrlf input
    
    # Aliasy Git
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    
    print_success "Git skonfigurowany"
}

# Skrypt testowy
create_test_script() {
    print_header "Tworzenie skryptu testowego"
    
    cat > "$HOME/scripts/test-environment.sh" << 'TEST_EOF'
#!/bin/bash
# Test Developer Environment

echo "=== Testing Developer Environment ==="

echo -n "Python: "
python --version 2>&1 || echo "NOT INSTALLED"

echo -n "pip: "
pip --version 2>&1 || echo "NOT INSTALLED"

echo -n "Node.js: "
node --version 2>&1 || echo "NOT INSTALLED"

echo -n "npm: "
npm --version 2>&1 || echo "NOT INSTALLED"

echo -n "Git: "
git --version 2>&1 || echo "NOT INSTALLED"

echo -n "Docker: "
docker --version 2>&1 || echo "NOT INSTALLED"

echo -n "docker-compose: "
docker-compose --version 2>&1 || echo "NOT INSTALLED"

echo -n "curl: "
curl --version | head -n1 2>&1 || echo "NOT INSTALLED"

echo -n "wget: "
wget --version | head -n1 2>&1 || echo "NOT INSTALLED"

echo -n "vim: "
vim --version | head -n1 2>&1 || echo "NOT INSTALLED"

echo -n "gh: "
gh --version 2>&1 || echo "NOT INSTALLED"

echo ""
echo "=== Git Configuration ==="
git config --global --list | grep user || echo "Git not configured"

echo ""
echo "=== SSH Keys ==="
ls -la ~/.ssh/ | grep -E "id_rsa|id_ed25519" || echo "No SSH keys found"

echo ""
echo "=== Environment Test Complete ==="
TEST_EOF
    
    chmod +x "$HOME/scripts/test-environment.sh"
    print_success "Skrypt testowy utworzony: ~/scripts/test-environment.sh"
}

# Funkcja główna
main() {
    clear
    
    print_header "WSL Ubuntu Development Environment Setup"
    
    check_wsl
    
    # Instalacja
    update_system
    install_basic_tools
    install_python
    install_nodejs
    install_gh_cli
    configure_git
    create_test_script
    
    print_success "Instalacja zakończona!"
    print_info "Przeładuj terminal: source ~/.bashrc"
}

# Uruchomienie
main "$@"
