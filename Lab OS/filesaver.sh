echo $#

case "$#" in
1)
	if ! test -d $1
		then
			echo "L'unico parametro deve essere una directory"
		else
			# deve copiare tutti i file della directory corrente nella subdirectory in [-d]
			cdir=$PWD							#	scopro il pathname assoluto della directory corrente
			d=${cdir:1} 						#	lo privo del primo carattere (ovvero '/')
			dfin=${d//\//-}						#	sostituisco i '/' con '-'
			dataora=$(date "+%Y%m%d-%H%M%S")	#   creo data e ora nel formato YYYYMMDD-HHMMSS
			nomesubdir=$dfin"_"$dataora			#	creo il nome della subdirectory da creare
			cd $1								#	mi sposto nella destinazione specificata in [-d]
			mkdir $nomesubdir					#	creo la subdirectory
			cd $cdir							#	torno nella directory iniziale
			destsub=$1"/"$nomesubdir			#	creo il path della subdirectory di destinazione della copia files
			cp *.* $destsub						#	copio tutti i files
	fi
	;;
2)
	if ! test -d $2		# caso in cui $2 è l'estensione dei file
		then
			# deve copiare i file della directory corrente con estensione [-e]
			cdir=$PWD							#	trovo il pathname assoluto della directory corrente
			d=${cdir:1}							#	lo privo del primo carattere (ovvero '/')
			dfin=${d//\//-}						#	sostituisco i '/' con '-'
			dataora=$(date "+%Y%m%d-%H%M%S")	#   creo data e ora nel formato YYYYMMDD-HHMMSS
			nomesubdir=$dfin"_"$dataora			#	creo il nome della subdirectory da creare
			cd $1								#	mi sposto nella destinazione specificata in [-d]
			mkdir $nomesubdir					#	creo la subdirectory
			cd $cdir							#	torno nella directory iniziale
			destsub=$1"/"$nomesubdir			#	creo il path della subdirectory di destinazione della copia files
			cp *.$2 $destsub					#	copio tutti i files con estensione [-e]
		else
			# deve copiare tutti i file da [-s] alla subdirectory in [-d]
			cdir=$2								#	trovo il pathname assoluto della directory sorgente specificata
			d=${cdir:1}							#	lo privo del primo carattere (ovvero '/')
			dfin=${d//\//-}						#	sostituisco i '/' con '-'
			dataora=$(date "+%Y%m%d-%H%M%S")	#   creo data e ora nel formato YYYYMMDD-HHMMSS
			nomesubdir=$dfin"_"$dataora			#	creo il nome della subdirectory da creare
			cd $1								#	mi sposto nella destinazione specificata in [-d]
			mkdir $nomesubdir					#	creo la subdirectory
			cd $cdir							#	torno nella directory iniziale
			destsub=$1"/"$nomesubdir			#	creo il path della subdirectory di destinazione della copia files
			cp *.* $destsub						#	copio tutti i files
	fi
	;;
3)
	if ! test -d $1 -a -d $2
		then
			echo "I primi due parametri devono essere directory"
		else
			# è tutto ok: copia i file con estensione [-e] presenti in [-s] nella subdirectory in [-d]
			cdir=$2								#	trovo il pathname assoluto della directory corrente
			d=${cdir:1}							#	lo privo del primo carattere (ovvero '/')
			dfin=${d//\//-}						#	sostituisco i '/' con '-'
			dataora=$(date "+%Y%m%d-%H%M%S")	#   creo data e ora nel formato YYYYMMDD-HHMMSS
			nomesubdir=$dfin"_"$dataora			#	creo il nome della subdirectory da creare
			cd $1								#	mi sposto nella destinazione specificata in [-d]
			mkdir $nomesubdir					#	creo la subdirectory
			cd $cdir							#	torno nella directory iniziale
			destsub=$1"/"$nomesubdir			#	creo il path della subdirectory di destinazione della copia files
			cp *.$3 $destsub					#	copio tutti i files con estensione [-e]
	fi
	;;
*)
	echo "Uso dello script: filesaver -d [-s] [-e]"
	;;
esac
exit 0
