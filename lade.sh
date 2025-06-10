#!/bin/bash
set -e  # Exit on any error

check_and_install_command() {
    local command_name="$1"
    local package_name="$2"

    if ! command -v "$command_name" &> /dev/null; then
        echo "$command_name is not installed. Attempting to install..."

        # Detect operating system
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        elif [ -f /etc/debian_version ]; then
            OS=debian
        elif [ -f /etc/redhat_release ]; then
            OS=rhel
        elif [ "$(uname)" == "Darwin" ]; then
            OS=macos
        else
            OS=$(uname -s)
        fi

        case "$OS" in
            ubuntu|debian)
                sudo apt update
                if [ "$command_name" == "node" ]; then
                    echo "Installing Node.js and npm via NodeSource PPA..."
                    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                    sudo apt install -y nodejs
                else
                    sudo apt install -y "$package_name"
                fi
                ;;
            centos|fedora|rhel)
                if [ "$command_name" == "node" ]; then
                    echo "Installing Node.js and npm..."
                    sudo dnf install -y nodejs || sudo yum install -y nodejs
                else
                    sudo dnf install -y "$package_name" || sudo yum install -y "$package_name"
                fi
                ;;
            macos)
                if ! command -v brew &> /dev/null; then
                    echo "Homebrew is not installed. Installing Homebrew..."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    case $(uname -m) in
                        arm64) eval "$(/opt/homebrew/bin/brew shellenv)" ;;
                        x86_64) eval "$(/usr/local/bin/brew shellenv)" ;;
                    esac
                fi
                brew install "$package_name"
                ;;
            *)
                echo "Unsupported operating system: $OS. Please install $command_name manually."
                exit 1
                ;;
        esac

        if ! command -v "$command_name" &> /dev/null; then
            echo "Failed to install $command_name. Please install it manually and run the script again."
            exit 1
        else
            echo "$command_name installed successfully."
        fi
    else
        echo "$command_name is already installed."
    fi
}

# --- Main Script Execution ---

echo "--- Checking for essential tools ---"
check_and_install_command "curl" "curl"
check_and_install_command "wget" "wget"
check_and_install_command "git" "git"
check_and_install_command "node" "nodejs"
check_and_install_command "npm" "npm"
echo "--- Essential tools check complete ---"
echo ""

LADE_URL="https://github.com/lade-io/lade/releases/latest/download/lade-linux-amd64.tar.gz"
ARGO="https://raw.githubusercontent.com/HtunNaung/lade/main/main.js"

echo "Downloading and extracting Lade from $LADE_URL..."
curl -L "$LADE_URL" | tar xz

echo "Making 'lade' executable..."
chmod +x lade
echo "Lade setup complete."

echo "Downloading app.js (your VLESS proxy code) from $ARGO..."
wget -O app.js "$ARGO"

echo ""
echo "Creating package.json with necessary dependencies for your VLESS proxy..."
cat << 'EOF_PACKAGE' > package.json
{
  "name": "nodejs-proxy",
  "version": "1.0.0",
  "description": "A VLESS proxy server running on Node.js with WebSocket.",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "ws": "^8.13.0"
  }
}
EOF_PACKAGE
echo "package.json created successfully."

echo ""
echo "Logging in to Lade..."
./lade login

echo ""
RANDOM_APP_NUMBER=$(shuf -i 1-10 -n 1)
LADE_APP_NAME="mrhtunnaung-${RANDOM_APP_NUMBER}"

echo "--- Creating Lade application '${LADE_APP_NAME}' ---"
./lade apps create "${LADE_APP_NAME}"

echo ""
echo "--- Deploying Lade application '${LADE_APP_NAME}' ---"
./lade deploy --app "${LADE_APP_NAME}"

echo ""
echo "--- Showing application details ---"
./lade apps show "${LADE_APP_NAME}"

rm -rf app.js

echo ""
echo "POWERED BY MrHtunNaung"
