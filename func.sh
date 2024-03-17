#!/bin/bash

EXTENSION=""
TEMPFILE=$(mktemp)

isExtensionGood() {
    local EXTENSION="${1##*.}" # pobieranie rozszerzenia pliku

    # sprawdzenie poprawności rozszerzenia pliku
    if [[ "$EXTENSION" != "wav"  && "$EXTENSION" != "mp3" && "$EXTENSION" != "flac" && "$EXTENSION" != "aiff" ]]; then
        echo 0;
    fi
    
    echo 1;
}

isFileGood() {
    FILE=$1
    
    if [ $(isExtensionGood $FILE) -eq 0 ]; then
        echo 0;
    fi

    # sprawdzanie czy plik istnieje
    if [ ! -f "${FILE}" ]; then
        echo 0;
    fi

    echo 1;
}

outputFileDialog() {
    local ANS=`zenity --entry --title "Wybierz nazwę pliku wyjściowego" --text "Nazwa pliku wyjściowego"`
    echo $ANS;
}

formatConversion() {
    local EXT="${1##*.}"
    local menu=("wav" "mp3" "flac" "aiff")
    local ANS=`zenity --list --column=Menu "${menu[@]}" --height 250`

    # sprawdzanie czy nie wybrano tego samego formatu pliku
    if [ ${EXT} == ${ANS} ]; then
        return;
    fi

    sox $1 "${TEMPFILE}.${ANS}"
    rm $1
    echo ${ANS}
}

cutFile() {
    local FILELENGHT=$(sox --info -D $1)
    local FILELENGHT="${FILELENGHT%%.*}"
    local CUTFROM=`zenity --scale --title "Przytnij od" --text "Przytnij od" --min-value 0 --max-value ${FILELENGHT} --value 0`
    local CUTTO=`zenity --scale --title "Tnij do (sekundy)" --text "Przytnij do" --min-value ${CUTFROM} --max-value ${FILELENGHT} --value ${CUTFROM}`
    local NEWTEMP=$(mktemp).${2}

    sox $1 $NEWTEMP trim $CUTFROM $((CUTTO - CUTFROM))
    sox $NEWTEMP $1;
    rm $NEWTEMP
}

combineFiles() {
    local ANS=`zenity --file-selection`
    
    if [ $(isExtensionGood $ANS) -eq 0 ]; then
        zenity --error --text "Nieobsługiwane rozszerzenie pliku."
        return;
    fi
    local NEWTEMP=$(mktemp).${2}
        
    sox $1 $ANS $NEWTEMP
    sox $NEWTEMP $1
    rm $NEWTEMP   
}

changeTempo() {
    local ANS=`zenity --scale --text "Zmień prędkość od 1.0 do 5.0" --title "Zmień prędkość" --min-value 1 --max-value 50 --value 10`
    local TEMPO=$(bc <<< "scale=1; $ANS/10")
    local NEWTEMP=$(mktemp).${2}

    sox $1 $NEWTEMP tempo $TEMPO
    sox $NEWTEMP $1
    rm $NEWTEMP
}

changeVolume() {
    local ANS=`zenity --scale --text "Zmień głośność od 0.1 do 5.0" --title "Zmień głośność" --min-value 1 --max-value 50 --value 10`
    local TEMPO=$(bc <<< "scale=1; $ANS/10")
    local NEWTEMP=$(mktemp).${2}

    sox $1 $NEWTEMP vol $TEMPO
    sox $NEWTEMP $1
    rm $NEWTEMP
}

mainMenu() {
    local FILE=$1
    EXTENSION="${FILE##*.}"
    
    sox ${FILE} ${TEMPFILE}.${EXTENSION}

    local menu=("Konwersja formatu" "Przycinanie pliku" "Łączenie plików" "Przyspiesz/Spowolnij" "Zmień głośność"  "Zapisz" "Wyjdź")
    local ANS=`zenity --list --title "Opcje" --text "Wybierz operację którą chcesz wykonać na pliku
$FILE" --column=Menu "${menu[@]}" --height 250`
    
    while [ 1 -eq 1 ]; do
        case $ANS in
            ${menu[0]})
                EXTENSION=$(formatConversion ${TEMPFILE}.${EXTENSION});;

            ${menu[1]})
                cutFile ${TEMPFILE}.${EXTENSION} ${EXTENSION};;

            ${menu[2]})
                combineFiles ${TEMPFILE}.${EXTENSION} ${EXTENSION};;

            ${menu[3]})
                changeTempo ${TEMPFILE}.${EXTENSION} ${EXTENSION};;

            ${menu[4]})
                changeVolume ${TEMPFILE}.${EXTENSION} ${EXTENSION};;

            "Zapisz")
                local OUTPUTFILE=$(outputFileDialog)
                sox ${TEMPFILE}.${EXTENSION} ${OUTPUTFILE}.${EXTENSION}
                rm ${TEMPFILE}.${EXTENSION}
                exit 1;;

            "Wyjdź")
                rm ${TEMPFILE}.${EXTENSION}
                exit 1;;    
        esac

        ANS=`zenity --list --title "Opcje" --text "Wybierz operację którą chcesz wykonać na pliku
$FILE" --column=Menu "${menu[@]}" --height 250`
    done
}