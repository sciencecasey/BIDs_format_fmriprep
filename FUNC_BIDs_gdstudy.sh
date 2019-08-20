#!/bin/bash
#Modified from Stanford Reproducible Neuroscience website
#modified for GD rename only on hoffman machine by Casey Jayne 8/19/2019

set -e  #to automatically exit out if the script command exits with a "non-zero" status

####Defining pathways
toplvl=/Users/casey/Desktop/working_folder/bids_structure_practice/GD_study/  #set this directory to the top level folder you want to move things into
sourcedir=/Users/casey/Desktop/working_folder/bids_structure_practice/GD_study/source
outputdir=/Users/casey/Desktop/working_folder/bids_structure_practice/GD_study/raw
session=1
softwaredir=/usr/local/Cellar
subjects=8001

###Create dataset_description.json
jo -p Name="GD Bodymorph Index" BIDSVersion="1.0.2" >> ${outputdir}/dataset_description.json
#adds a json file using the jo package and command from the file set in a separate folder "dataset_description"


for subj in $subjects; do  #change this to the folder you want it to be
	echo "Processing subject $subj"

	
	##Conversion
	mkdir -p ${outputdir}/sub-${subj}/ses-${session}/anat 
	for direcs in {*mprage*,*MPRAGE*}; do
		dcm2niix -b y -z y -o ${outputdir}/sub-${subj}/ses-${session} -f ${subj}_%p_%s ${sourcedir}/*_${subj}_S${session}/dicom/Prisma*/201*****/FEU*/${direcs}
	done
	
	cd ${outputdir}/sub-${subj}/ses-${session}
	
	
	anatfiles=$(ls -1 *MPRAGE* | wc -l)
	for ((i=1;i<=${anatfiles};i++)); do
		Anat=$(ls *MPRAGE*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed.
		tempanat=$(ls -1 $Anat | sed '1q;d') #Capture new file to change
		tempanatext="${tempanat##*.}"
		tempanatfile="${tempanat%.*}"
		mv -n ${tempanatfile}.${tempanatext} sub-${subj}_ses-${session}_T1w.${tempanatext}
		echo "${tempanat} changed to sub-${subj}_ses-${session}_T1w.${tempanatext}"
	done
	
	#Rename all *.gz to *.nii.gz and move to correct folder
	for i in sub-${subj}_*.gz; do
		mv $i "${i%.*}.nii.gz"
	done
	for files in *T1w*; do mv $files anat; done
	
	####Functional Organization####
	#Create subject folder
	mkdir -p ${outputdir}/sub-${subj}/ses-${session}/func

	###Convert dcm to nii
	cd ${sourcedir}/*_${subj}_S${session}/dicom/Prisma*/201*****/FEU*
	for direcs in BODYMORPH_1* BODYMORPH_2* BODYMORPH_3* BODY_LOCALIZER* REST*; do
		#grab the directories within each functional task folders
		dcm2niix -b y -z y -o ${outputdir}/sub-${subj}/ses-${session}/ -f ${subj}_%p_%s ${sourcedir}/*_${subj}_S${session}/dicom/Prisma*/201*****/FEU*/${direcs}
	done

	#Changing directory into the subject folder
	cd ${outputdir}/sub-${subj}/ses-${session}

	##Rename func files
	#Break the func down into each task
	#BODYMORPH task
	#BODYLOCALIZER task
	#REST task
	#Capture the number of files to change
	bmfiles=$(ls -1 *BODYMORPH* | wc -l)
	#capture the number of total BM functional task files
	for ((i=1;i<=${bmfiles};i++)); do
		bm=$(ls *MORPH*)
		tempbm=$(ls -1 $bm | sed '1q;d')
		tempbmfile="${tempbm%.*}"
		tempbmext="${tempbm##*.}"
		tp=`fslnvols $tempbm`
		Tr=$(echo $tempbm | awk -F '[_]' '{print $5}')
		num=$(echo $tempbmfile | rev | cut -d '_' -f1 | rev)
			if [[ $num == *.nii ]]
				then num=${num%.nii}
			fi
		taskname=$(echo $tempbmfile | awk -F'[_]' '{print $2}')
		run=$(echo $tempbmfile | awk -F'[_]' '{print $3}')
		#always backup so that you don't rewrite the filenames
		#this makes a ~1~ if there are more than one
		mv -n ${tempbm} sub-${subj}_ses-${session}_task-bodymorph_run-${run}_acq-TP${tp}_ce-${Tr}_dir-${num}_bold.${tempbmext}
		echo "${tempbm} changed to sub-${subj}_ses-${session}_task-bodymorph_run-${run}_acq-TP${tp}_ce-${Tr}_dir-${num}_bold.${tempbmext}"
	done
	blfiles=$(ls -1 *BODY_LOCALIZE* | wc -l)
	#capture the number of total BL functional task files
	for ((i=1;i<=${blfiles};i++)); do
		bl=$(ls *LOCAL*)
		tempbl=$(ls -1 $bl | sed '1q;d')
		tempblfile="${tempbl%.*}"
		tempblext="${tempbl##*.}"
		tp=`fslnvols $tempbl`
		Tr=$(echo $tempbl | awk -F '[_]' '{print $5}')
		num=$(echo $tempblfile | rev | cut -d '_' -f1 | rev)
			if [[ $num == *.nii ]]
				then num=${num%.nii}
			fi
		taskname=$(echo $tempblfile | awk -F'[_]' '{print $2$3}')
		#always backup so that you don't rewrite the filenames
		#this makes a ~1~ if there are more than one
		mv -n ${tempbl} sub-${subj}_ses-${session}_task-localizer_acq-TP${tp}-${Tr}_dir-${num}_bold.${tempblext}
		echo "${tempbl} changed to sub-${subj}_ses-${session}_task-localizer_acq-TP${tp}-${Tr}_dir-${num}_bold.${tempblext}"
	done
	restfiles=$(ls *REST* | wc -l)
	for ((i=1;i<=${restfiles};i++)); do
		rest=$(ls *REST*)
		temprest=$(ls -1 $rest | sed '1q;d')
		temprestfile="${temprest%.*}"
		temprestext="${temprest##*.}"
		tp=`fslnvols $temprest`
		Tr=$(echo $temprest | awk -F '[_]' '{print $6}')
		num=$(echo $temprestfile | rev | cut -d '_' -f1 | rev)
			if [[ $num == *.nii ]]
				then num=${num%.nii}
			fi
		mv -n $temprest sub-${subj}_ses-${session}_task-rest_acq-TP${tp}-${Tr}_dir-${num}_rest.${temprestext}
		echo "$temprest changed to sub-${subj}_ses-${session}_task-rest_acq-TP${tp}-${Tr}_dir-${num}_rest.${temprestext}"
	done
	
	#Rename all *.gz to *.nii.gz and move to correct folder
	for i in sub-${subj}_*.gz; do
		mv $i "${i%.*}.nii.gz"
	done
	for files in *bold*; do mv $files func; done

	####Diffusion Organization####
	#Create subject folder
	mkdir -p ${outputdir}/sub-${subj}/ses-${session}/dwi

	###Convert DWI dcm to nii
	cd ${sourcedir}/*_${subj}_S${session}/dicom/Prisma*/201*****/FEU*
	for direcs in {*DWI*,*DTI*}; do
		dcm2niix -b y -z y -o ${outputdir}/sub-${subj}/ses-${session}/ -f ${subj}_%p_%s ${sourcedir}/*_${subj}_S${session}/dicom/Prisma*/201*****/FEU*/${direcs}
	done

	dwifiles=$(ls -1 *DWI* | wc -l)
	for ((i=1;i<="${dwifiles}";i++)); do
		dwi=$(ls *DWI*)
		tempdwi=$(ls -1 *DWI* | sed '1q;d')
		tempdwifile="${tempdwi%.*}"
		tempdwiext="${tempdwi##*.}"
		tp=`fslnvols $tempdwi`
		tempdir=$(echo $tempdwi | awk -F '_' '{print $3$4}')
		dir="${tempdir##dir}"
		mv -n $tempdwi sub-${subj}_ses-${session}_acq-TP${tp}-auto-7B5_dir-${dir}_dwi.${tempdwiext}
		echo "changed $tempdwi to sub-${subj}_ses-${session}_acq-TP${tp}-auto-7B5_dir-${dir}_dwi.${tempdwiext}"
	done
	dtifiles=$(ls -1 *DTI* | wc -l)
	for ((i=1;i<="${dtifiles}";i++)); do
		dti=$(ls *DTI*)
		tempdti=$(ls -1 *DTI* | sed '1q;d')
		tempdtifile="${tempdti%.*}"
		tempdtiext="${tempdti##*.}"
		tp=`fslnvols $tempdti`
		tempdir=$(echo $tempdti | awk -F '_' '{print $3$4}')
		dir=$(echo $tempdir | awk -F 'dir' '{print $1$2}')
		b=$(echo $tempdti | awk -F '_' '{print $5$6}')
		mv -n $tempdti sub-${subj}_ses-${session}_acq-TP${tp}-${b}-dti_dir-${dir}_dwi.${tempdtiext}
		echo "changed $tempdti to sub-${subj}_ses-${session}_acq-TP${tp}-${b}-dti_dir-${dir}_dwi.${tempdtiext}"
	done
		
	#Rename all *.gz to *.nii.gz and move to correct folder
	for i in sub-${subj}_*.gz; do
		mv $i "${i%.*}.nii.gz"
	done
	for files in *_dwi*; do mv $files dwi; done

	#Handle duplicate files
	for file in *TP0*; do
		dupfile="${file%.*}"
		dupext="${file##*.}"
		mv $file ${file//.${dupext}/}
		mv $dupfile ${dupfile//TP0*/TP0-duplicate.${dupext}}
	done

	
	
	
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