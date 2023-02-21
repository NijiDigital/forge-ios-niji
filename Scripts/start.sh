#!/bin/bash

# Permet de sortir du script dans le cas où une install fail
set -e

# Permet de revenir à la racine du projet si le script est lancé depuis le dossier Scripts
currentPath=$(dirname "$0")
if [ $currentPath == "." ]; then
    cd ..
fi

#######################
# Lancement du script #
#######################
printf "\n**************************************************\n* Lancement du script de démarrage sur le projet *\n**************************************************\n"
# TODO : echo des jolis messages en couleurs avec des paillettes pour annoncer le lancement du script

########################################
# Installation des softwares manquants #
########################################

sh ./Scripts/project-tools.sh

# Génére le projet pour la première fois
sh ./Scripts/project-generate.sh

########################
# Petit message de fin #
########################
printf "\n******************************************************************\n* Le script de démarrage du projet a été exécuté avec succès *\n******************************************************************\n"
# TODO : echo des jolis messages en couleurs avec des paillettes pour annoncer la fin du script
