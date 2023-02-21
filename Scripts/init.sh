#!/bin/bash

# Permet de sortir du script dans le cas où une install fail
set -e

# Permet de revenir à la racine du projet si le script est lancé depuis le dossier Scripts
currentPath=$(dirname "$0")
if [ $currentPath == "." ]; then
    cd ..
fi

# Méthode d'affichage de message d'erreur à l'utilisateur dans le cas 
# où le nom du projet donné ne serait pas valide.
invalidProjectName () {
    projectHasCorrectName=false
    echo "------------------------------------------------"
    echo "/!\\ Invalid project name /!\\"
    echo >&2 "$@"
    echo "------------------------------------------------"
}

#######################
# Lancement du script #
#######################
printf "\n**************************************************\n* Lancement du script d'initialisation du projet *\n**************************************************\n"
# TODO : echo des jolis messages en couleurs avec des paillettes pour annoncer le lancement du script

########################################
# Installation des softwares manquants #
########################################

sh ./Scripts/project-tools.sh

#####################
# Renomme le projet #
#####################

# Demande un nom de projet à l'utilisateur et vérifie qu'il soit valide
declare projectHasCorrectName=false
while [ "$projectHasCorrectName" = false ] ; do
    read -e -p "Enter your project name: " projectName
    projectHasCorrectName=true
    [[ "${projectName:0:1}" != " " ]] || invalidProjectName "Your project name must not start with a space."
    [[ "${projectName:0:1}" != [0-9] ]] || invalidProjectName "Your project name must not start with a number."
    [[ ! -z "$projectName" ]] || invalidProjectName "You must give a name to your project."
done

# Utilise le nom de projet pour renommer le projet
sh ./Scripts/project-rename.sh "$projectName"

##########################################
# Génére le projet pour la première fois #
##########################################

sh ./Scripts/project-generate.sh

########################
# Petit message de fin #
########################
printf "\n******************************************************************\n* Le script d'initialisation du projet a été exécuté avec succès *\n******************************************************************\n"
# TODO : echo des jolis messages en couleurs avec des paillettes pour annoncer la fin du script
