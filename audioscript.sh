#!/bin/bash

source ./func.sh

VERSION="1.0"

# sprawdzenie czy SoX jest zainstalowany
if ! command -v sox &> /dev/null; then
    echo "Program SoX nie jest zainstalowany."
    exit 1
fi

# pobranie dodatkowych flag
while getopts ":i:v" OPT; do
    case $OPT in
        i)
            if [ $(isFileGood $OPTARG) -eq 0 ]; then
                echo "Podano złą nazwę/ścieżkę pliku."
                exit 1
            fi
            FILE=$OPTARG
            mainMenu $FILE;;
        v)
            echo "Aktualna wersja: $VERSION"
            exit 0;;
    esac
done

FILE=$(zenity --file-selection)
mainMenu $FILE
