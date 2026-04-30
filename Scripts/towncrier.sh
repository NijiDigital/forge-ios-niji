#!/bin/bash

####################### /!\ INFOS /!\ #######################
# Ce script est destiné à être lancé par une lane fastlane. #
#############################################################
# Paramètres :                                              #
# $1 La categorie (added, changed, deprecated, removed,     #
#                   fixed, security, doc, trivial)          #
# $2 Le nom de l'issue                                      #
#                                                           #
# Exemple d'utilisation : towncrier.sh added NIJISOCLE-3016 #
#############################################################

#############
# Variables #
#############
declare relativeTowncrierPath="./towncrier"
declare category=""
declare issueName=""
declare fileName=""


#######################
# Lancement du script #
#######################

# Récupère la categorie
if [ "$1" = "added" -o "$1" = "add" -o "$1" = "a" ]; then
    category="added"

elif [ "$1" = "changed" -o "$1" = "change" -o "$1" = "c" ]; then
    category="changed"

elif [ "$1" = "deprecated" -o "$1" = "depr" -o "$1" = "d" ]; then
    category="deprecated"

elif [ "$1" = "removed" -o "$1" = "remove" -o "$1" = "rem" -o "$1" = "r" ]; then
    category="removed"
    
elif [ "$1" = "fixed" -o "$1" = "fix" -o "$1" = "f" ]; then
    category="fixed"
    
elif [ "$1" = "security" -o "$1" = "sec" -o "$1" = "s" ]; then
    category="security"
    
elif [ "$1" = "doc" -o "$1" = "documentation" ]; then
    category="doc"
    
elif [ "$1" = "trivial" -o "$1" = "triv" -o "$1" = "t" ]; then
    category="trivial"

else
    echo >&2 "Mauvais nom de catégorie."
    exit 1
fi

# Récupère le nom d'issue
issueName="$2"

# Crée le newsfragment et l'ouvre dans une nouvelle instance de TextEdit
fileName="$issueName.$category"
towncrier create "$fileName"
open -a TextEdit "$relativeTowncrierPath/$fileName.md"
