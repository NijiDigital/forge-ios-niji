#!/bin/bash

########################################
# Installation des softwares manquants #
########################################

# Installe Homebrew s'il n'est pas déjà installé
if [ ! $(command -v brew) ]; then 
    printf "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Installe Ruby avec rbenv s'il n'est pas déjà installé
if [ $(rbenv versions | grep -v system | wc -l) -lt 1 ]; then
    printf "Installing Ruby with rbenv..."
    echo 'PATH=$(rbenv root)/shims:$PATH' >> ~/.zshrc 
    latestRubyVersion=$(rbenv install -l | grep -v - | tail -1)
    rbenv install $latestRubyVersion
    rbenv local $latestRubyVersion
fi

# Installe Python avec pyenv s'il n'est pas déjà installé
if [ $(pyenv versions | grep -v system | wc -l) -lt 1 ]; then
    printf "Installing Python with pyenv..."
    echo 'PATH=$(pyenv root)/shims:$PATH' >> ~/.zshrc
    latestPythonVersion=$(pyenv install --list | sed 's/^  //' | grep '^\d' | grep -v 'dev\|a\|b' | tail -1)
    pyenv install $latestPythonVersion
    pyenv local $latestPythonVersion
fi

# Installe Towncrier s'il n'est pas déjà installé
if [ ! $(command -v towncrier) ]; then 
    printf "Installing Towncrier..."
    python3 -m pip install towncrier
fi

# Installe Bundler s'il n'est pas déjà installé
if [ ! $(command -v bundler) ]; then 
    printf "Installing Bundler..."
    gem install bundler
fi

#############################
# Set-up de l'environnement #
#############################
printf "Configuring Bundler..."
bundle config set --local path 'vendor/bundle'

printf "Installing project gems..."
bundle install