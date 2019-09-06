#!/bin/bash
#Modified from Stanford Reproducible Neuroscience website
#1st Modification- Angel Wong
#modified for VM_TMS on local machine by Casey Jayne 8/2/2019

set -e  #to automatically exit out if the script command exits with a "non-zero" status

####Defining pathways
toplvl=/Users/casey/Desktop/working_folder/bids_structure_practice/VMTMS  #set this directory to the top level folder you want to move things into
dcmdir=${toplvl}/sourcedata/BDD
niidir=${toplvl}/BIDsniix/BDD
softwaredir=/usr/local/Cellar
subject=10001
#session=

###Create dataset_description.json
jo -p Name="BDD TMS Visual Modulation Datasets" BIDSVersion="1.0.2" >> ${niidir}/dataset_description.json
#adds a json file using the jo package and command from the file set in a separate folder "dataset_description"


for subj in $subject; do  #change this to the folder you want it to be
	echo "Processing subject $subj"

	####Anatomical Organization####
	###Create structure
	mkdir -p ${niidir}/sub-${subj}/anat #the -p function makes so that intermediate directories are created if needed or skipped if exist
	#automatically sets permissions as 0777 (want to change to 770 * later)
	###Convert dcm to nii
	#Only convert the Dicom folder anat
	cd ${dcmdir}/TMS_VM_${subj}/dicom
	for direcs in *MPRAGE*; do
		dcm2niix -b y -z y -o ${niidir}/sub-${subj} -f ${subj}_%p_%s ${dcmdir}/TMS_VM_${subj}/dicom/${direcs}
		#explanations for above
		#general format :: dcm2niix [options] <in_folder>
		#${dcm2niidir}#go to the dcm directory folder where dcm2niix function is
		#/dcm2niix -o # set the output directory as follows: ${niidir}/sub-${subj} #nifti folder created for the subject
		# -f #name the file as filename:: ${subj}_%p#protocolused_%s#seriesused
		#${dcmdir}/${subj}/${direcs} #files within within the dicom subject folder, in the MPRAGE directories
	done


	#Changing directory into the subject folder
	cd ${niidir}/sub-${subj}

	###Change filenames
	##Rename anat files
	#Example filename: 5015_t1_mprage_sag_p3_iso_8
	#BIDS filename: sub-5015_T1w
	#Capture the number of anat files to change
	anatfiles=$(ls -1 *MPRAGE* | wc -l) #count the number of files with MPRAGE #this is a numerical variable
	for ((i=1;i<=${anatfiles};i++)); do #every time loop through the function, add 1 to the i (second run through, i=2, etc; then only cont if 2 or more MPRAGE)
		Anat=$(ls *MPRAGE*) #save the filenames in the Anat variables and refresh the variable
		tempanat=$(ls -1 $Anat | sed '1q;d') #grab the first filename within Anat variables
		tempanatext="${tempanat##*.}" #grab the filename after the last . sign (extension)
		tempanatfile="${tempanat%.*}" #grab the filename before the last . sign (without the extension)
		mv -n ${tempanatfile}.${tempanatext} sub-${subj}_T1w.${tempanatext}
		echo "${tempanat} changed to sub-${subj}_T1w.${tempanatext}" #echo what the script did
	done

	###Organize files into folders
	for files in $(ls sub*); do
		Orgfile="${files%.*}"
		Orgext="${files##*.}"
		Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
		#reversethe order of characters in the file
		#remove the delimiter separated by underscore (the -f1 says the remove the first field of the delimeter??? Is this in regards to the reverse order?)
		#reverse the order again
		if [ $Modality == "T1w" ]; then
			mv ${Orgfile}.${Orgext} anat #if already .nii.gz, then Orgfile.Orgext doesn't exist (looks for .gz only)
		fi
	done

	#Rename all *.gz to *.nii.gz
	#this has to be done after organizing into folders using Orgfile or breaks (see above)
	cd ${niidir}/sub-${subj}/anat
	for i in *.gz; do
		mv $i "${i%.*}.nii.gz"
	done

	####Functional Organization####
	#Create subject folder
	mkdir -p ${niidir}/sub-${subj}/func

	###Convert dcm to nii
	cd ${dcmdir}/TMS_VM_${subj}/dicom
	for direcs in VIS_MOD_1_* VIS_MOD_2_* VIS_MOD_3_* FAST* REST*; do
		#grab the directories within each functional task folders
		dcm2niix -b y -z y -o ${niidir}/sub-${subj} -f ${subj}_%p_%s ${dcmdir}/TMS_VM_${subj}/dicom/${direcs}
	done

	#Changing directory into the subject folder
	cd ${niidir}/sub-${subj}

	##Rename func files
	#Break the func down into each task
	#VIS_MOD task
	#FAST task
	#Example filename: 5015_VIS_MOD_1_Nat_tilt-12_5
	#BIDS filename: sub-5015_task-VISMOD1Nat_bold
	#Capture the number of files to change
	vismodfiles=$(ls -1 *VIS_MOD* | wc -l)
	#caputure the number of total vismod functional task files
	for ((i=1;i<=${vismodfiles}/2;i++)); do
		vismodnii=$(ls *VIS_MOD*nii*)
		tempvismodnii=$(ls -1 $vismodnii | sed '1q;d')
		tp=`fslnvols $tempvismodnii`
		for ((j=1;j<=2;j++)); do
			vismod=$(ls *VIS_MOD*) #This is to refresh the vismod variable, same as the Anat case
			tempvismod=$(ls -1 $vismod | sed '1q;d') #Capture new file to change
			tempvismodext="${tempvismod##*.}"
			tempvismodfile="${tempvismod%.*}"
			taskname=$(echo $tempvismodfile | awk -F'[_]' '{print $5}')
			if [[ $taskname1 == "VM" ]]; then
				taskname=attentionmod
			else
				taskname=naturalview
			fi
			procorder=$(echo $tempvismodfile | awk -F'[_]' '{print $4}')
		#natural viewing is always first but the second task is counterbalanced
		#awk -F'[_]' '{print $2$3$4$5}'   #separate out by the underscores into 7 different fields
		#only grab the 2-5 fields as the task names
		#if [ $procorder == 1 ] && [[ $taskname = "Nat" ]];
  			#then mv -n ${tempvismod2} sub-${subj}_task-${procorder}${taskname}_run-1_bold.${tempvismodext};
   			#echo "${tempvismod2} sub-${subj}_task-${procorder}${taskname}_run-1_bold.${tempvismodext}";
   		#elif [ $procorder != 1 ] && [[ $taskname = "Nat" ]];
   			#then mv -n ${tempvismod2} sub-${subj}_task-${procorder}${taskname}_run-2_bold.${tempvismodext};
   			#echo "${tempvismod2} sub-${subj}_task-${procorder}${taskname}_run-2_bold.${tempvismodext}";
   		#elif [[ "$taskname" = "VM" ]] ;
   			#then mv -n ${tempvismod2} sub-${subj}_task-${procorder}${taskname}_bold.${tempvismodext};
   			#echo "${tempvismod2} sub-${subj}_task-${procorder}${taskname}_bold.${tempvismodext}";
		 #fi
		mv -n ${tempvismod} sub-${subj}_task-${taskname}_acq-order${procorder}_bold.${tempvismodext}
		#always backup so that you don't rewrite the filenames
		#this makes a ~1~ if there are more than one
		echo "${tempvismod} changed to sub-${subj}_task-${taskname}_acq-order${procorder}_bold.${tempvismodext}"
		done
	done

# modified from Stanford website, more concise than below
	for order in 1 3; do
		for Nat in $(ls *acq-order${order}* | awk '$0!~/run/{print $0}'); do
			natfile=$Nat
			procorder=$(echo $natfile | sed 's/[^0-9]//g' | awk -F''$subj'' '{print $2}')
			if [ $procorder == 1 ]; then
				runnumber=1
			else
				runnumber=2
			fi
			mv -n $natfile ${natfile/Nat/Nat_run-$runnumber}
			echo "$natfile changed to  ${natfile/Nat/Nat_run-$runnumber}"
		done
	done


	#shopt -s extglob
	#ls !(*run*)
	#add run number for natural viewing
	#naturalfiles=$(ls -1 *Nat_* | awk '$0!~/run/{print $0}'| wc -l)
	#list all files containing Nat_ in individual lines
	#from that list ($0) print any items not containing (!~) the string "run" (/run/) print the list now
	#wc -l : count the line items [this integer is saved as the variable "naturalfiles"
		#for ((i=1;i<=${naturalfiles}/2;i++)); do
			#natural=$(ls *Nat_*)
			#tempnatural=$(ls -1 $natural | sed '1q;d')
			#echo "file is $tempnatural"
			#procorder=$(echo $tempnatural | sed 's/[^0-9]//g' | awk -F''$subj'' '{print $2}')
			#echo "order is $procorder"
			#if [ $procorder = 1 ]
			#	then mv -n $tempnatural ${tempnatural/Nat/Nat_run-1}
			#	echo "$tempnatural changed to ${tempnatural/1Nat_/1Nat_run-1}"
			#elif [ $procorder != 1 ]
			#	then mv -n $tempnatural ${tempnatural/Nat/Nat_run-2}
			#	echo "$tempnatural ${tempnatural/1Nat_/1Nat_run-2}"
			#fi
		#done

	fastfiles=$(ls -1 *FAST* | wc -l)
	for ((i=1;i<=${fastfiles}/2;i++)); do
		fastnii=$(ls *FAST*nii*)
		tempfastnii=$(ls -1 $fastnii | sed '1q;d')
		tp=`fslnvols $tempfastnii`
		for ((j=1;j<=2;j++)); do
			fast=$(ls *FAST*)
			tempfast=$(ls -1 $fast | sed '1q;d')
			tempfastfile="${tempfast%.*}"
			tempfastext="${tempfast##*.}"
			#taskname=$(echo $tempfastfile | awk -F'[_]' '{print $2}')
			mv -n ${tempfast} sub-${subj}_task-fastface_acq-order4_bold.${tempfastext} #change the filenames
			echo "$tempfast changed to sub-${subj}_task-fastface_acq-order4_bold.${tempfastext}"
		done
	done


	#Rest
	#Example filename: 5015_Rest_MB8_1_9
	#BIDS filename: sub-5015_task-rest_bold
	#Capture the number of files to change

#some subjects have zero rest files, some have only 1 but it's the 7 min rest, others the 5 min rest, some subjects have both rests
#this works
#test -n "$(find . -maxdepth 1 -name '*rest*' -print -quit)" && echo "file found" || echo "file not found"
#this works too
#if  [test -n "$(find . -maxdepth 1 -name '*Rest*' -print -quit)" ==0] ; do
		#restfiles=$(ls -1 *Rest* | wc -l)
		#for ((i=1;i<=${restfiles}/2;i++)); do
		#	restnii=$(ls *Rest*nii*)
		#	temprestnii=$(ls -1 $restnii | sed '1q;d')
		#	tp=`fslnvols $temprestnii` #this function captures the number of timepoints for the nii files with an FSL function
#tp is a numerical vaiable with the number of volumes within that functional data (570 for 7 min, 406 for 5 min)
		#	for ((j=1;j<=2;j++)); do
		#		rest=$(ls *Rest*) #This is to refresh the rest variable, same as the Anat case
		#		temprest=$(ls -1 $rest | sed '1q;d') #Capture new file to change
		#		temprestext="${temprest##*.}"
		#		temprestfile="${temprest%.*}"
		#		mv -n ${temprestfile}.${temprestext} sub-${subj}_task-rest_acq-${tp}TP_bold.${temprestext}
		#		echo "${temprestfile}.${temprestext} changed to sub-${subj}_task-rest_acq-${tp}TP_bold.${temprestext}"
		#	done
		#done
	#fi

	###Organize files into folders
	for files in $(ls sub*); do
		Orgfile="${files%.*}" #filename without extension
		Orgext="${files##*.}" #file extensions
		Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev) #reverse filename, separate by _, choose first field
		if [ $Modality == "bold" ]; then
			mv ${Orgfile}.${Orgext} func
		fi
	done

	#Handle duplicate files
	if ls *~* 1> /dev/null 2>&1; then #look for ~ to indicate a file that has the backup rest because there is more than one rest of the same length
		for file in *TP*~*; do
			dupfile="${file%.*}"
			dupext="${file##*.}"
			dupnum=$(echo $file | awk -F'[~]' '{print $2}') #print the second field between the tildes (~1~ captures and prints 1)
			mv $file ${file//.${dupext}/}
			mv $dupfile ${dupfile//TP/TP${dupnum}}
			cd func
			((newnum=$dupnum+1))
			mv $dupfile ${dupfile//TP/TP${newnum}}
			cd ..
		done
		mv sub*TP* func
	fi

	#Rename all *.gz to *.nii.gz
	cd ${niidir}/sub-${subj}/func
	for niifiles in *.gz; do
		mv $niifiles ${niifiles%.*}.nii.gz
	done

	###Check func json for required fields
	#Required fields for func: 'RepetitionTime','VolumeTiming' or 'SliceTiming', and 'TaskName'
	#capture all jsons to test
	cd ${niidir}/sub-${subj}/func #Go into the func folder
	for funcjson in $(ls *.json*); do

		#Repeition Time exist?
		repeatexist=$(cat ${funcjson} | jq '.RepetitionTime')
		if [[ ${repeatexist} == "null" ]]; then
			echo "${funcjson} doesn't have RepetitionTime defined"
		else
			echo "${funcjson} has RepetitionTime defined"
		fi

		#VolumeTiming or SliceTiming exist?
		#Constraint SliceTiming can't be great than TR
		volexist=$(cat ${funcjson} | jq '.VolumeTiming')
		sliceexist=$(cat ${funcjson} | jq '.SliceTiming')
		if [[ ${volexist} == "null" && ${sliceexist} == "null" ]]; then
			echo "${funcjson} doesn't have VolumeTiming or SliceTiming defined"
		else
			if [[ ${volexist} == "null" ]]; then
				echo "${funcjson} has SliceTiming defined"
				#Check SliceTiming is less than TR
				sliceTR=$(cat ${funcjson} | jq '.SliceTiming[] | select(.>="$repeatexist")')
				if [ -z ${sliceTR} ]; then
					echo "All SliceTiming is less than TR" #The slice timing was corrected in the newer dcm2niix version called through command line
				else
					echo "SliceTiming error"
				fi
			else
				echo "${funcjson} has VolumeTiming defined"
			fi
		fi

		#Does TaskName exist?
		taskexist=$(cat ${funcjson} | jq '.TaskName')
		if [ "$taskexist" == "null" ]; then
			jsonname="${funcjson%.*}"
			taskfield=$(echo $jsonname | cut -d '_' -f2 | cut -d '-' -f2)
			jq '. |= . + {"TaskName":"'${taskfield}'"}' ${funcjson} > tasknameadd.json
			rm ${funcjson}
			mv tasknameadd.json ${funcjson}
			echo "TaskName was added to ${jsonname} and matches the tasklabel in the filename"
		else
			Taskquotevalue=$(jq '.TaskName' ${funcjson})
			Taskvalue=$(echo $Taskquotevalue | cut -d '"' -f2)
			jsonname="${funcjson%.*}"
			taskfield=$(echo $jsonname | cut -d '_' -f2 | cut -d '-' -f2)
			if [ $Taskvalue == $taskfield ]; then
				echo "TaskName is present and matches the tasklabel in the filename"
			else
				echo "TaskName and tasklabel do not match"
			fi
		fi

	done
done

echo -n "Do you want to compress the dicom files after conversion (y/n)? "
read DOcompress

###Do compression of the dicom data
	if [ $DOcompress == "y" ]; then
		cd ${dcmdir}/TMS_VM_${subj}/dicom
		for folder in $(ls -d *); do
			echo "Compressing ${folder}"
			tar -zcf ${folder}.tar.gz $folder
			rm -rf $folder
		done
	fi
done
