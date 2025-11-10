#!/bin/bash
# ROS2 개발 환경 + zsh 완전 자동 설치 스크립트

# ==========================================
# 대화형 프롬프트 완전 비활성화
# ==========================================
export DEBIAN_FRONTEND=noninteractive

set -e  # 에러 시 중단

echo "=== ROS2 + zsh 개발 환경 설치 시작 ==="

# 1. needrestart 자동 설정
echo "[0/14] 자동 설치 설정 중..."

# needrestart 패키지가 설치된 경우에만 설정 변경
if dpkg -s needrestart >/dev/null 2>&1; then
    # 설정 파일이 이미 있는 경우: 기존 주석 라인 교체
    if [ -f /etc/needrestart/needrestart.conf ]; then
        sudo sed -i "s/#\?\s*\$nrconf{restart} *= *'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    else
        # 디렉토리 보장 후 새 설정 파일 생성
        sudo mkdir -p /etc/needrestart
        printf "\$nrconf{restart} = 'a';\n" | sudo tee /etc/needrestart/needrestart.conf >/dev/null
    fi
else
    echo "needrestart 패키지가 설치되어 있지 않아 자동 재시작 설정을 건너뜁니다."
fi

# 2. 시스템 업데이트
echo "[1/14] 시스템 업데이트..."
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"

# 3. 기본 도구 설치
echo "[2/14] 기본 개발 도구 설치..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    vim \
    nano \
    htop \
    tree \
    tmux \
    unzip \
    software-properties-common

# 4. zsh 설치
echo "[3/14] zsh 설치..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y zsh

# 5. Oh My Zsh 설치
echo "[4/14] Oh My Zsh 설치..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 6. zsh 플러그인 설치
echo "[5/14] zsh 플러그인 설치..."

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# zsh-completions
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions" ]; then
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
fi

# 7. Powerlevel10k 테마 설치
echo "[6/14] Powerlevel10k 테마 설치..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# 8. Swap 설정
echo "[7/14] Swap 메모리 설정..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    sudo sysctl vm.swappiness=10
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
fi

# 9. X11 관련 패키지
echo "[8/14] X11 패키지 설치..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y xauth x11-apps

# 10. C++ 개발 도구
echo "[9/14] C++ 개발 도구 설치..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    gcc g++ gdb clang clang-format clang-tidy \
    cmake make ninja-build ccache \
    libeigen3-dev libboost-all-dev \
    libopencv-dev python3-opencv \
    libyaml-cpp-dev

# 11. Python 개발 환경
echo "[10/14] Python 개발 환경 설치..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    python3 python3-pip python3-dev python3-venv \
    python3-setuptools python3-wheel

python3 -m pip install --upgrade pip

# Python 패키지
pip3 install \
    numpy scipy matplotlib pandas \
    opencv-python pillow \
    pyyaml requests tqdm \
    ipython jupyter \
    pylint black flake8 mypy pytest

# 12. Node.js & npm
echo "[11/14] Node.js & npm 설치..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo DEBIAN_FRONTEND=noninteractive apt install -y nodejs

# npm 전역 경로 설정
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# 13. ROS2 저장소 추가 및 설치
echo "[12/14] ROS2 Humble 설치..."
sudo add-apt-repository universe -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'
sudo apt update

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ros-humble-desktop \
    ros-dev-tools \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool

# ROS2 추가 패키지
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ros-humble-rqt* \
    ros-humble-rviz2 \
    ros-humble-gazebo-* \
    ros-humble-turtlesim

# 14. rosdep 초기화
echo "[13/14] rosdep 초기화..."
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
fi
rosdep update

# 15. SSH X11 설정
echo "[14/14] SSH X11 설정..."
sudo sed -i 's/#X11Forwarding yes/X11Forwarding yes/' /etc/ssh/sshd_config
sudo sed -i 's/#X11DisplayOffset 10/X11DisplayOffset 10/' /etc/ssh/sshd_config
sudo sed -i 's/#X11UseLocalhost yes/X11UseLocalhost yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo ""
echo "=== .zshrc 생성 중... ==="

# .zshrc 백업
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup
fi

# .zshrc 생성
cat > ~/.zshrc << 'ZSHRC_EOF'
# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    docker
    npm
    pip
    python
    colored-man-pages
    command-not-found
    extract
    history
    sudo
)

source $ZSH/oh-my-zsh.sh

# ============================
# 환경 변수
# ============================

# npm 전역 경로
export PATH=~/.npm-global/bin:$PATH

# 로컬 bin
export PATH=$HOME/.local/bin:$PATH

# ROS2 환경
source /opt/ros/humble/setup.zsh
source /usr/share/colcon_cd/function/colcon_cd.sh
export _colcon_cd_root=~/ros2_ws
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh

# 작업 공간이 빌드되어 있으면 자동 소싱
if [ -f ~/ros2_ws/install/setup.zsh ]; then
    source ~/ros2_ws/install/setup.zsh
fi

# Editor
export EDITOR='vim'
export VISUAL='vim'

# History 설정
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ============================
# ROS2 Aliases
# ============================

# 빌드 관련
alias cb='colcon build --symlink-install'
alias cbt='colcon test'
alias cbp='colcon build --symlink-install --packages-select'
alias cbu='colcon build --symlink-install --packages-up-to'
alias cbc='rm -rf build install log'
alias cs='source install/setup.zsh'

# 실행 관련
alias killros='killall -9 ros2 && killall -9 rviz2'
alias killgazebo='killall -9 gazebo gzserver gzclient'

# 빠른 이동
alias ws='cd ~/ros2_ws'
alias src='cd ~/ros2_ws/src'

# ============================
# Git Aliases
# ============================

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# ============================
# 시스템 Aliases
# ============================

alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias ports='sudo netstat -tulanp'
alias disk='df -h'
alias mem='free -h'

# ls 개선
alias ll='ls -lh'
alias la='ls -lah'

# ============================
# ROS2 함수
# ============================

# 새 ROS2 패키지 생성
ros2_create_pkg() {
    if [ -z "$1" ]; then
        echo "Usage: ros2_create_pkg <package_name> [cpp|py]"
        return 1
    fi
    
    local pkg_name=$1
    local pkg_type=${2:-cpp}
    
    cd ~/ros2_ws/src
    
    if [ "$pkg_type" = "cpp" ]; then
        ros2 pkg create --build-type ament_cmake $pkg_name
        echo "Created C++ package: $pkg_name"
    elif [ "$pkg_type" = "py" ]; then
        ros2 pkg create --build-type ament_python $pkg_name
        echo "Created Python package: $pkg_name"
    else
        echo "Invalid type. Use 'cpp' or 'py'"
        return 1
    fi
    
    cd ~/ros2_ws
}

# 빠른 빌드 및 소싱
cbs() {
    cd ~/ros2_ws
    colcon build --symlink-install "$@"
    local result=$?
    if [ $result -eq 0 ]; then
        source install/setup.zsh
        echo "✅ Build successful and sourced!"
    else
        echo "❌ Build failed!"
    fi
    return $result
}

# 특정 패키지만 빌드 및 소싱
cbps() {
    if [ -z "$1" ]; then
        echo "Usage: cbps <package_name>"
        return 1
    fi
    
    cd ~/ros2_ws
    colcon build --symlink-install --packages-select "$@"
    local result=$?
    if [ $result -eq 0 ]; then
        source install/setup.zsh
        echo "✅ Build successful and sourced!"
    else
        echo "❌ Build failed!"
    fi
    return $result
}

# ROS2 노드 정보
ros2_info() {
    echo "=== Running Nodes ==="
    ros2 node list
    echo ""
    echo "=== Active Topics ==="
    ros2 topic list
    echo ""
    echo "=== Active Services ==="
    ros2 service list
}

# ============================
# 유용한 설정
# ============================

# 자동완성 개선
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# 디렉토리 스택
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# 오타 수정
setopt CORRECT
setopt CORRECT_ALL

ZSHRC_EOF

# Git 설정
git config --global init.defaultBranch main
git config --global core.editor vim

echo ""
echo "=== 설치 완료! ==="
echo ""
echo "다음 명령어로 zsh를 기본 쉘로 설정하세요:"
echo "  chsh -s \$(which zsh)"
echo ""
echo "그 후 재접속하면 zsh가 활성화됩니다."
echo ""
echo "설치된 버전:"
echo "- GCC: $(gcc --version | head -n1)"
echo "- Python: $(python3 --version)"
echo "- Node.js: $(node --version)"
echo "- zsh: $(zsh --version)"
echo "- ROS2: Humble"
echo ""
echo "💡 커널 업데이트 알림이 나왔다면 설치 완료 후 재부팅하세요:"
echo "  sudo reboot"
echo ""
