#!/bin/bash

#===============================================================================
# si progetti e implementi uno script della shell Bash, chiamato cambia_copia,
# che riceva obbligatoriamente in ingresso l'opzione -o est_orig piu' almeno una
# delle seguenti opzioni: -d est_dest e -r orig@dest
#
# Lo script deve considerare tutti i file con estensione est_orig e copiarli in
# file con estensione est_dest (se presente l'opzione -d) e rimpiazzare le
# occorenze di orig con dest nei file (se presente l'opzione -r). Se entrambe le
# opzioni sono presenti la sostituzione deve avvenire nei file copiati.
#
# Di default lo script deve essere eseguito solo nella cartella corrente, ma
# deve essere possibile anche specificare l'opzione -D dir per impostare una
# directory di partenza e l'opzione -R per richiedere l'esecuzione ricorsiva
# nelle sottodirectory.
#
# esempio: cambia_copia -R -D /home/utente -o java -d cs -r import@using deve
# copiare ricorsivamente da /home/utente tutti i file con estensione java in
# omonimi file con estensione cs sostituendo in questi ultimi ogni occorrenza di
# import con using.
#===============================================================================

# DICHIARAZIONE DI FUNZIONI

# utilizzo
function usage () {
	echo "Utilizzo:";
	echo "`basename $0` -o <original_extension>"
	echo "              -d <destination_extension>"
	echo "              oppure"
	echo "              -r <original_string@destination_string>"
	echo "              [-R]"
	echo "              [-D <directory>]"
	echo
	echo "-R                           Modo ricorsivo"
	echo "-D <directory>               Inserire la directory nella quale operare"
	echo "									  se diversa dalla attuale"
	echo "-o <original_extension>      Estensione da modificare"
	echo "-d <destination_extension>   Estensione modificata"
	echo "-r <original_string>         Stringa da modificare nel file"
	echo "   @"
	echo "   <destination_string>      Stringa modificata nel file"
	exit
}

# rinomina i file con la nuova estensione nella cartella di lavoro
function rename_extensions () {
	if [[ $RECUR == 0 ]] # verifica se e' stata richiesta la ricorsione nelle cartelle
	then # nessuna ricorsione
		for nomefile in *.$est_orig
		do 
			cp "$nomefile" "${nomefile%.$est_orig}.$est_dest"
		done
	else # effettua ricorsione
		find . -name "*.$est_orig" -print0 | while read -r -d $'\0' nomefile; do
			cp "$nomefile" "${nomefile%.$est_orig}.$est_dest"
		done
	fi
}

# usa sed per modificare i file di testo utilizzando un file temporaneo in cui
# redirezionare l'output di sed
function replace_string () {
	nomefile="$1"
	t_file="temp$PID"
	touch "$t_file" # creo il file temporaneo
	#sostituisce la stringa $orig con la stringa $dest
	sed "s/$orig/$dest/g" "$nomefile" > "$t_file" # salvo output di sed in un file temporaneo
	cat "$t_file" > "$nomefile" # sovrascrivo il file originale con il file temporaneo
	rm "$t_file"
}

# trova i file da modificare
function find_file() {
	ext="$1"
	if [[ $RECUR == 0 ]]  # verifica se e' stata richiesta la ricorsione nelle cartelle
	then # nessuna ricorsione
		for nomefile in *.$ext
		do
			replace_string $nomefile
		done
	else # effettua ricorsione
		find . -name "*.$ext" -print0 | while read -r -d $'\0' nomefile; do
			replace_string $nomefile
		done
	fi
}


# CORPO PRINCIPALE

# inizializzazione di alcune varibili
CWD=`pwd`		# directory di lavoro (di default quella attuale)
ARG=4				# numero di argomenti minimo richiesto
est_orig=""		# estensione dei file di partenza
est_dest=""		# estensione in cui eventualmente rinominare i file
orig=""			# stringa da sostituire nei file
dest=""			# stringa con cui sostituire nei file
ORIGI=0			# e' stato inserito il parametro -o ?
DESTI=0			# e' stato inserito il parametro -d ?
REPLA=0			# e' stata richiesta la sostituzione delle stringhe?
RECUR=0			# e' stata richiesta la ricorsione nelle directory?
temp_arg=""		# contenitore dell'argomento da analizzare

# se il numero di parametri e' inferiore a quello richiesto, stampa l'"usage"
if [[ $# -lt "$ARG" ]] 
then usage fi

# analisi dei parametri
# i "case" controllano che parametro si sta inserendo
# lo "shift" fa spostare i parametri a sinistra di una posizione ($2 diventa $1)
temp_arg=""
while (( "$#" > 0 ))
do
	case "$1" in
		-R)
			if [ ${#temp_arg} -le 0 ]
			then RECUR=1
			else usage
			fi
		;;
		-o)
			if [ ${#temp_arg} -le 0 ]
			then
				temp_arg="est_orig"
				ORIGI=1
			else usage
			fi
		;;
		-d) if [ ${#temp_arg} -le 0 ]
			then
				temp_arg="est_dest"
				DESTI=1
			else usage
			fi
		;;
		-D) if [ ${#temp_arg} -le 0 ]
			then temp_arg="CWD"
			else usage
			fi
		;;
		-r) if [ ${#temp_arg} -le 0 ]
			then
				temp_arg="stringa"
				REPLA=1
			else usage
			fi
		;;
		*) # salvo il valore al posto giusto
			case "$temp_arg" in
				est_orig) # inserisce l'estensione di partenza
					est_orig="$1"
					temp_arg=""
				;;
				est_dest) # imposta l'estensione di destinazione
					est_dest="$1"
					temp_arg=""
				;;
				CWD) # imposta la directory di lavoro
					CWD="$1"
					temp_arg=""
				;;
				stringa) # imposta le stringhe da sostituire
					stringa="$1"
					pos_guardia=`expr index "$stringa" @` # indice del separatore
					orig=${stringa:0:((pos_guardia-1))} # estrae la parola da sostituire
					dest=${stringa:((pos_guardia))} # estrae la parola con cui sosituire
					temp_arg=""
				;;
				*) usage # ogni altro valore e' errato
				;; 
			esac
		;;
	esac 
	shift
done

# entro nella directory richiesta e lancio le funzioni corrette a seconda dei parametri inseriti
cd "$CWD"
case $ORIGI in
	0) usage # non e' stato impostato il parametro fondamentale "estensione di partenza"
	;; 
	1) case $DESTI in # e' stato impostato il parametro fondamentale "estensione di partenza"
		0) case $REPLA in # non si modifica l'estensione
			0) usage # non si fa quindi proprio niente...
			;; 
			1) find_file $est_orig # si sostituiscono stringhe
			;;
			*) usage
			;;
			esac
		;;
		1) case $REPLA in # si modifica l'estensione
			0) rename_extensions # non si sostituiscono stringhe
			;;
			1) # prima rinomino, poi sostituisco
				rename_extensions
				find_file $est_dest
			;;
			*) usage
			;;
			esac
		;;
		*) usage
		;;
		esac
	;;
	*) usage
	;;
esac

