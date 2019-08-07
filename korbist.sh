#!/bin/bash
sudo apt -y install gpw
sudo apt -y install screen
user=whoami
random_script_name=$(gpw 1 16)

cat > /tmp/$random_script_name.sh << ELF

#!/bin/bash
while true
do


FILEUNION=~/unionfile
if [ -f \$FILEUNION ]; then
   echo "Файл '\$FILEUNION' существует."
   echo "Starting one more time script now..."

cat ~/unionfile | cut -d":" -f1 | uniq > ~/projectname_list_previous
cat ~/unionfile | cut -d":" -f2 | uniq > ~/billings_list_previous

function create_projects(){
newprojectname=\$(gpw 1 4)-\$(gpw 1 5)-\$(gpw 1 6)
gcloud projects create \$newprojectname
}

while create_projects; do
  echo "All done"
  echo "sleeping 10 seconds now"
sleep 10
done

echo "All possible projects was created"

gcloud projects list | cut -f 1 -d ' ' | tail -n+2 > ~/projectname_list

echo ""
echo "All project list:"
echo ""
cat ~/projectname_list
echo ""
sleep 1

echo ""
echo ""
cat ~/projectname_list ~/projectname_list_previous |sort |uniq -u > ~/projectname_list_current
echo ""
echo ""
echo "Projects for current work:"
echo ""
cat ~/projectname_list_current
echo ""
sleep 1

#echo ""
#cat ~/relink_union | cut -d":" -f2 | sort | uniq -c > ~/relink_output
#echo ""
#echo "List projects and billings with numbers match from relink_union was created:"
#cat ~/relink_output
#echo ""
#sleep 1


#N=3
#while IFS=" " read -r n billingname_to_add_id; do
# if [ \$n -lt \$N ]
# then
#	Nres=\$((\$N-\$n))
#	mapfile -t arr < <(cat ~/projectname_list_current | head -n \$Nres)
#sed -i "1,\$Nres d" ~/projectname_list_current
#echo ""
#echo "Reading N project from current list and cut and paste to unionfile_current"
#echo ""
#for i in "\${arr[@]}"
#do
#   echo "\$i:\$billingname_to_add_id" >> ~/unionfile_current
#   echo ""
#   echo "Adding new pair to unionfile_curent:"
#   echo ""
#   cat ~/unionfile_current
#sleep 1
#done
	
#  fi
#done < <(cat ~/relink_output | cut -d":" -f2 | sort | uniq | column -t)




echo ""
cat ~/unionfile | cut -d":" -f2 | sort | uniq -c > ~/output
echo ""
echo "List projects and billings with numbers match was created:"
cat ~/output
echo ""
sleep 1

N=3
while IFS=" " read -r n billingname_to_add_id; do
  if [ \$n -lt \$N ]
  then
    
	Nres=\$((\$N-\$n))
	mapfile -t arr < <(cat ~/projectname_list_current | head -n \$Nres)
sed -i "1,\$Nres d" ~/projectname_list_current
echo ""
echo "Reading N project from current list and cut and paste to unionfile_current"
echo ""
for i in "\${arr[@]}"
do
   echo "\$i:\$billingname_to_add_id" >> ~/unionfile_current
   echo ""
   echo "Adding new pair to unionfile_curent:"
   echo ""
   cat ~/unionfile_current
sleep 1
done
	
  fi
done < <(cat ~/output | cut -d":" -f2 | sort | uniq | column -t)

while IFS=":" read projectname_id billingname_id; do

function link_to_billing(){
gcloud beta billing projects link \$projectname_id --billing-account \$billingname_id
}


if link_to_billing ; then
    echo "Project \$projectname_id successfully linked to \$billingname_id"
    echo "sleeping 10 seconds now"
    sleep 10
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	grep '\$billingname_id' ~/unionfile_current >> ~/relink_list_\$billingname_id
	grep '\$billingname_id' ~/unionfile >> ~/relink_list_\$billingname_id
	cat ~/relink_list_\$billingname_id | sort -u > ~/relink_list_sorted_\$billingname_id
	mv ~/relink_list_sorted_\$billingname_id ~/relink_list_\$billingname_id
	sleep 1
	
	echo "Remove all current limited projects from unionfile"
	grep -v '\$billingname_id' ~/unionfile_current > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile_current;
	grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile;
fi

done < ~/unionfile_current

echo "All projects was successfully linked to their billings"


echo "Creating instances from unionfile_current..."
echo ""
cat ~/unionfile_current
sleep 1
echo ""

while IFS=":" read projectname_id billingname_id; do

gcloud config set project \$projectname_id	
gcloud services enable compute.googleapis.com


gcloud compute zones list | cut -f 1 -d ' ' | tail -n+2 | shuf > ~/shuffed-regions
grep -v 'asia-east2' ~/shuffed-regions > ~/shuffed-regions_temp; mv ~/shuffed-regions_temp ~/shuffed-regions; rm ~/shuffed-regions_temp;

firstregion=\$(sed '1!d' shuffed-regions)
secondregion=\$(sed '2!d' shuffed-regions)
randomname=\$(shuf -i 100-100000 -n 1)

function create_instances_repeat (){
gcloud compute instances create instance-\$randomname \\
--zone=europe-west4-a \\
--image-project ubuntu-os-cloud \\
--image-family ubuntu-minimal-1604-lts \\
--custom-cpu=16 \\
--custom-memory=15Gb \\
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/restynom/bora-mako/master/vst-install.sh | bash -s'
}

function create_instances_1 (){

gcloud compute instances create instance-1 \\
--zone=\$firstregion \\
--image-project ubuntu-os-cloud \\
--image-family ubuntu-minimal-1604-lts \\
--custom-cpu=16 \\
--custom-memory=15Gb \\
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/restynom/bora-mako/master/vst-install.sh | bash -s'
}

function create_instances_2 (){
gcloud compute instances create instance-2 \\
--zone=\$secondregion \\
--image-project ubuntu-os-cloud \\
--image-family ubuntu-minimal-1604-lts \\
--custom-cpu=16 \\
--custom-memory=15Gb \\
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/restynom/bora-mako/master/vst-install.sh | bash -s'
}


case "\$(create_instances_1 2>&1 ...)" in
 *'Try a different zone, or try again later.'* )
 create_instances_repeat 
 echo "Instance_\$randomname on \$projectname_id in europe was successfully created..."
 echo "sleeping 5 seconds now"
 sleep 5
 ;;
  *'Limit'* )
  echo "Error limit was detected. Save projects to relink file and continue"
	grep '\$billingname_id' ~/unionfile_current >> ~/relink_list_\$billingname_id
	grep '\$billingname_id' ~/unionfile >> ~/relink_list_\$billingname_id
	cat ~/relink_list_\$billingname_id | sort -u > ~/relink_list_sorted_\$billingname_id
	mv ~/relink_list_sorted_\$billingname_id ~/relink_list_\$billingname_id
	sleep 1
	echo "Remove all current limited projects from unionfile"
	grep -v '\$billingname_id' ~/unionfile_current > ~/unionfile_temp
	mv ~/unionfile_temp ~/unionfile_current
        grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp
	mv ~/unionfile_temp ~/unionfile
 ;;
  * ) 
 create_instances_1
 echo "Instance_1 on \$projectname_id was successfully created..."
 echo "sleeping 5 seconds now"
 sleep 5
 ;;
esac


case "\$(create_instances_2 2>&1 ...)" in
 *'Try a different zone, or try again later.'* )
 create_instances_repeat 
 echo "Instance_\$randomname on \$projectname_id in europe was successfully created..."
 echo "sleeping 5 seconds now"
 sleep 5
 ;;
  *'Limit'* )
  echo "Error limit was detected. Save projects to relink file and continue"
	
	grep '\$billingname_id' ~/unionfile_current >> ~/relink_list_\$billingname_id
	grep '\$billingname_id' ~/unionfile >> ~/relink_list_\$billingname_id
	cat ~/relink_list_\$billingname_id | sort -u > ~/relink_list_sorted_\$billingname_id
	mv ~/relink_list_sorted_\$billingname_id ~/relink_list_\$billingname_id
	sleep 1
	
	echo "Remove all current limited projects from unionfile"
	grep -v '\$billingname_id' ~/unionfile_current > ~/unionfile_temp
	mv ~/unionfile_temp ~/unionfile_current
        grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp
	mv ~/unionfile_temp ~/unionfile
 ;;
  * )
 create_instances_2
 echo "Instance_2 on \$projectname_id was successfully created..."
 echo "sleeping 5 seconds now"
 sleep 5
 ;;
esac

echo "All instances on \$projectname_id was created"
echo " "
gcloud compute instances list
echo " "
echo "Going to the next one..."
done < ~/unionfile_current

cat ~/relink_list_* > ~/relink_union 
rm ~/relink_list_*

echo "Some cleaning..."
rm ~/billinga* ~/projectsa* ~/shuffed-regions
echo "All is done!"
echo ""

else
   echo "Файл '\$FILEUNION' не найден."
    echo "Starting first time script now..."





while read first_project_to_unlink; do
gcloud beta billing projects unlink \$first_project_to_unlink
done < <(gcloud projects list | grep "My Project" | cut -f 1 -d ' ')


function create_projects(){
newprojectname=\$(gpw 1 4)-\$(gpw 1 5)-\$(gpw 1 6)
gcloud projects create \$newprojectname
}


while create_projects; do
  echo "All done"
  echo "sleeping 10 seconds now"
sleep 10
done
echo ""
echo "All possible projects was created"

gcloud projects list | cut -f 1 -d ' ' | tail -n+2 > ~/projectname_list

split ~/projectname_list -l3 projects

gcloud beta billing accounts list | cut -f 1 -d ' ' | tail -n+2 > ~/billings_list
split ~/billings_list -l1 billing

function generate_project_billing_list(){

exec 2>/dev/null

for index in {a..z}

do

awk -v OFS=: '
    NR == FNR {size2++; billinga'\$index'[FNR] = \$0; next}
    FNR == 1 && NR > 1 {billinga'\$index'[0] = billinga'\$index'[size2]}
    {print \$0, billinga'\$index'[FNR % size2]}
' billinga\$index projectsa\$index >> ~/unionfile

done
}

generate_project_billing_list
echo "Projects and billings list was successfully generated"

cat ~/unionfile
sleep 1

while IFS=":" read projectname_id billingname_id; do

function link_to_billing(){
gcloud beta billing projects link \$projectname_id --billing-account \$billingname_id
}


if link_to_billing ; then
    echo "Project \$projectname_id successfully linked to \$billingname_id"
	echo "sleeping 10 seconds now"
sleep 10
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	grep '\$billingname_id' ~/unionfile > ~/relink_list_\$billingname_id
	cat ~/relink_list_\$billingname_id
	sleep 1
	
	echo "Remove all current limited projects from unionfile"
	grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile; rm ~/unionfile_temp;

fi

done < ~/unionfile

echo "All projects was successfully linked to their billings"

echo "Creating instances..."
echo ""
cat ~/unionfile
sleep 1
echo ""

while IFS=":" read projectname_id billingname_id; do

gcloud config set project \$projectname_id	
gcloud services enable compute.googleapis.com


gcloud compute zones list | cut -f 1 -d ' ' | tail -n+2 | shuf > ~/shuffed-regions
grep -v 'asia-east2' ~/shuffed-regions > ~/shuffed-regions_temp; mv ~/shuffed-regions_temp ~/shuffed-regions; rm ~/shuffed-regions_temp;

firstregion=\$(sed '1!d' shuffed-regions)
secondregion=\$(sed '2!d' shuffed-regions)
randomname=\$(shuf -i 100-100000 -n 1)

function create_instances_repeat (){
gcloud compute instances create instance-\$randomname \\
--zone=europe-west4-a \\
--image-project ubuntu-os-cloud \\
--image-family ubuntu-minimal-1604-lts \\
--custom-cpu=16 \\
--custom-memory=15Gb \\
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/restynom/bora-mako/master/vst-install.sh | bash -s'
}


function create_instances_1 (){

gcloud compute instances create instance-1 \\
--zone=\$firstregion \\
--image-project ubuntu-os-cloud \\
--image-family ubuntu-minimal-1604-lts \\
--custom-cpu=16 \\
--custom-memory=15Gb \\
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/restynom/bora-mako/master/vst-install.sh | bash -s'
}

function create_instances_2 (){
gcloud compute instances create instance-2 \\
--zone=\$secondregion \\
--image-project ubuntu-os-cloud \\
--image-family ubuntu-minimal-1604-lts \\
--custom-cpu=16 \\
--custom-memory=15Gb \\
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/restynom/bora-mako/master/vst-install.sh | bash -s'
}


case "\$(create_instances_1 2>&1 ...)" in
 *'Try a different zone, or try again later.'* )
 create_instances_repeat 
 echo "Instance_\$randomname on \$projectname_id in europe was successfully created..."
 echo "sleeping 5 seconds now"
 sleep 5
 ;;
  *'Limit'* )
  #newautomatic
  
  echo "Error limit was detected. Now we go to unlink and link one more time"
	
  grep '$billingname_id' ~/unionfile > ~/unlink_list
	while IFS=":" read unlink_projectname_id current_billing_id; do
	gcloud beta billing projects unlink $unlink_projectname_id
	done < ~/unlink_list
	
	while IFS=":" read unlink_projectname_id current_billing_id; do
	gcloud beta billing projects link \$unlink_projectname_id --billing-account \$current_billing_id
	echo "unlink and link $unlink_projectname_id to \$current_billing_id successfully done!"
  done < ~/unlink_list
  
  #oldhandblock
  #echo "Error limit was detected. Save projects to relink file and continue"
	#grep '\$billingname_id' ~/unionfile >> ~/relink_list_\$billingname_id
	#cat ~/relink_list_\$billingname_id
	#sleep 1
	#echo "Remove all current limited projects from unionfile"
	#grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp
	#mv ~/unionfile_temp ~/unionfile; rm ~/unionfile_temp
 ;;
  * ) 
 create_instances_1
 echo "Instance_1 on \$projectname_id was successfully created..."
 echo "sleeping 5 seconds now"
 sleep 5
 ;;
esac


case "\$(create_instances_2 2>&1 ...)" in
 *'Try a different zone, or try again later.'* )
 create_instances_repeat 
 echo "Instance_\$randomname on \$projectname_id in europe was successfully created..."
 echo "sleeping 5 seconds now"
 sleep 5
 ;;
  *'Limit'* )
  
  #newautomatic
  
  echo "Error limit was detected. Now we go to unlink and link one more time"
	
  grep '\$billingname_id' ~/unionfile > ~/unlink_list
	while IFS=":" read unlink_projectname_id current_billing_id; do
	gcloud beta billing projects unlink \$unlink_projectname_id
	done < ~/unlink_list
	
	while IFS=":" read unlink_projectname_id current_billing_id; do
	gcloud beta billing projects link \$unlink_projectname_id --billing-account \$current_billing_id
	echo "unlink and link $unlink_projectname_id to \$current_billing_id successfully done!"
  done < ~/unlink_list
  
  #oldhandblock
  #echo "Error limit was detected. Save projects to relink file and continue"
  #grep '\$billingname_id' ~/unionfile >> ~/relink_list_\$billingname_id
  #cat ~/relink_list_\$billingname_id
  #sleep 1
  #echo "Remove all current limited projects from unionfile"
  #grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp
  #mv ~/unionfile_temp ~/unionfile
  #rm ~/unionfile_temp
 ;;
  * ) 
 create_instances_2
 echo "Instance_2 on \$projectname_id was successfully created..."
 echo "sleeping 5 seconds now"
 sleep 5
 ;;
esac


echo "All instances on \$projectname_id was created"
echo ""
gcloud compute instances list
echo ""
echo "Going to the next one..."
done < ~/unionfile

#cat ~/relink_list_* > ~/relink_union 
#rm ~/relink_list_*


echo "Some cleaning..."
rm ~/billinga* ~/projectsa* ~/shuffed-regions
echo "All is done!"
echo ""
#echo "billings that need to relink:"
#cat ~/relink_union | cut -d: -f2 | sort -u
echo ""
fi
  echo ""
  echo "Press [enter] to restart script or [q] and then [enter] to quit"
  read x
  if [[ "\$x" == 'q' ]]
  then
    break
  fi
done

ELF

chmod a+x /tmp/$random_script_name.sh

screen -dmS mysession bash -c "/tmp/$random_script_name.sh; exec bash"

#screen -S work bash -c "/tmp/$random_script_name.sh"
#screen -S mysession bash
#screen -r mysession -X stuff "/tmp/$random_script_name.sh"$(echo -ne '\015')
