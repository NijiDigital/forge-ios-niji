#!/bin/bash

#############
# Variables #
#############

declare oldProjectName="Socle"
declare currentPath=$(pwd)


#################
# Vérifications #
#################

# Méthode pour kill le script avec un exit code 1 et un message informatif en paramètre.
die () {
    echo >&2 "$@"
    exit 1
}

# Vérifie que le script soit bien lancé à la racine du projet
[ -d "${currentPath}/Configurations" -a -d "${currentPath}/Environment" ] || die "Veuillez lancer le script à la racine du projet"
declare projectPath="$currentPath"

# Vérifie qu'il y ait bien un paramètre passé au script.
[ "$#" -ne 0 ] || die "Veuillez renseigner le nouveau nom du projet, aucun paramètre renseigné"
# Vérifie qu'il n'y ait bien qu'un seul paramètre passé au script.
[ "$#" -eq 1 ] || die "Veuillez renseigner le nouveau nom du projet entre guillemets. Vous avez renseigné $# paramètres mais un seul est autorisé"


#######################
# Lancement du script #
#######################

printf "\n***************************************************\n* Le script de renommage est en cours d'exécution *\n***************************************************\n"
# TODO : echo des jolis messages en couleurs avec des paillettes pour annoncer le lancement du script

# Enlève les espaces du nouveau nom de projet
shopt -s extglob
declare newProjectName="${1//+( )/}"


##########################
# Renommage des fichiers #
##########################

printf "\n***********************************\n* Renommage des fichiers en cours *\n***********************************\n"

# Comme on change le nom des routes en même temps qu'on les parcours, il arrive que l'on en saute
# Cette boucle while permet de s'assurer que l'on ait bien tout traité
while [[ $(find * | grep "$oldProjectName") ]]; do
    # Permet de gérer les cas de caractères spéciaux (comme l'espace) dans le nom des fichiers
    find * -print0 |
    while IFS= read -r -d '' file; do
        if [[ $file == *"$oldProjectName"* ]]; then
            newName="$(echo "$file" | sed "s/$oldProjectName/$newProjectName/g")"
            mv -v "$file" "$newName" 2>/dev/null
        fi
    done
done


########################################
# Remplacement du contenu des fichiers #
########################################

printf "\n*************************************************\n* Remplacement du contenu des fichiers en cours *\n*************************************************\n"

# Gestion des cas où les noms commencent par une majuscule ou une minuscule (ex: getOldProjectName() ou oldProjectName.doSomething())
oldProjectNameL=$(echo $oldProjectName | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }');
oldProjectNameU=$(echo $oldProjectName | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }');
newProjectNameL=$(echo $newProjectName | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }');
newProjectNameU=$(echo $newProjectName | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }');

echo "Remplacement de $oldProjectNameL en $newProjectNameL et de $oldProjectNameU en $newProjectNameU"
# Permet de gérer les cas de caractères spéciaux (comme l'espace) dans le nom des fichiers
find * -type f -print0 |
while IFS= read -r -d '' file; do
    # Exclue un certain nombre de fichiers que l'on ne veut pas (ou qu'il n'est pas nécessaire de) modifier
    if [[ $file != "Build/"* && $file != "Reports/"* && $file != "vendor/"* && $file != *"CHANGELOG"* && $file != *"DS_Store"* && $file != *".bak" ]]; then
        # Compte le nombre de changements qui seront opérés
        declare changes=$(grep -o -E "$oldProjectNameL|$oldProjectNameU" "$file" | wc -l)
        if [[ "$changes" -gt 0 ]]; then
            echo -e "\n${changes} occurences trouvées dans le fichier ${file}\":"
            # Montre les endroits dans le fichier où les changements seront opérés puis les effectue
            grep -n --color=always -E "$oldProjectNameL|$oldProjectNameU" "$file"
            sed -i "" "s/$oldProjectNameL/$newProjectNameL/g;s/$oldProjectNameU/$newProjectNameU/g" "$file";
        fi
    fi
done

########################
# Petit message de fin #
########################

printf "\n****************************************************\n* Le script de renommage a été exécuté avec succès *\n****************************************************\n"
printf "\nNouveau nom du projet : $newProjectName\n\n"
# TODO : echo des jolis messages en couleurs avec des paillettes pour annoncer la fin du script
