#!/bin/bash
sudo apt -y install gpw
sudo apt -y install screen

random_script_name=$(gpw 1 16)

cat > ~/start.sh << ELF

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
  sleep 1
done

echo "All possible projects was created"

gcloud projects list | cut -f 1 -d ' ' | tail -n+2 > ~/projectname_list

echo ""
echo "All project list:"
echo ""
cat ~/projectname_list
echo ""
sleep 2

echo ""
echo ""
cat ~/projectname_list ~/projectname_list_previous |sort |uniq -u > ~/projectname_list_current
echo ""
echo ""
echo "Projects for current work:"
echo ""
cat ~/projectname_list_current
echo ""
sleep 2

echo ""
cat ~/relink_union | cut -d":" -f2 | sort | uniq -c > ~/relink_output
echo ""
echo "List projects and billings with numbers match from relink_union was created:"
cat ~/relink_output
echo ""
sleep 2


N=5
while IFS=" " read -r n billingname_to_add_id; do
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
sleep 2
done
	
  fi
done < <(cat ~/relink_output | cut -d":" -f2 | sort | uniq | column -t)




echo ""
cat ~/unionfile | cut -d":" -f2 | sort | uniq -c > ~/output
echo ""
echo "List projects and billings with numbers match was created:"
cat ~/output
echo ""
sleep 2

N=5
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
sleep 2
done
	
  fi
done < <(cat ~/output | cut -d":" -f2 | sort | uniq | column -t)

while IFS=":" read projectname_id billingname_id; do

function link_to_billing(){
gcloud beta billing projects link \$projectname_id --billing-account \$billingname_id
}


if link_to_billing ; then
    echo "Project \$projectname_id successfully linked to \$billingname_id"
	
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	grep '\$billingname_id' ~/unionfile_current >> ~/relink_list_\$billingname_id
	grep '\$billingname_id' ~/unionfile >> ~/relink_list_\$billingname_id
	cat ~/relink_list_\$billingname_id | sort -u > ~/relink_list_sorted_\$billingname_id
	mv ~/relink_list_sorted_\$billingname_id ~/relink_list_\$billingname_id
	sleep 2
	
	echo "Remove all current limited projects from unionfile"
	grep -v '\$billingname_id' ~/unionfile_current > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile_current;
	grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile;
fi

done < ~/unionfile_current

echo "All projects was successfully linked to their billings"


echo "Creating instances from unionfile_current..."
echo ""
cat ~/unionfile_current
sleep 2
echo ""

while IFS=":" read projectname_id billingname_id; do

gcloud config set project \$projectname_id	
gcloud services enable compute.googleapis.com


gcloud compute zones list | cut -f 1 -d ' ' | tail -n+2 | shuf > ~/shuffed-regions

firstregion=\$(sed '1!d' shuffed-regions)
secondregion=\$(sed '2!d' shuffed-regions)

function create_instances (){

gcloud compute instances create instance-1 \
--zone=\$firstregion \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/gasteen/opt/master/vst-install.sh | bash -s'
sleep 3s
gcloud compute instances create instance-2 \
--zone=\$secondregion \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/gasteen/opt/master/vst-install.sh | bash -s'
sleep 1s
}

if create_instances ; then
    echo "Instances on \$projectname_id was successfully created..."
	
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	grep '\$billingname_id' ~/unionfile_current >> ~/relink_list_\$billingname_id
	grep '\$billingname_id' ~/unionfile >> ~/relink_list_\$billingname_id
	cat ~/relink_list_\$billingname_id | sort -u > ~/relink_list_sorted_\$billingname_id
	mv ~/relink_list_sorted_\$billingname_id ~/relink_list_\$billingname_id
	sleep 2
	
	echo "Remove all current limited projects from unionfile"
	grep -v '\$billingname_id' ~/unionfile_current > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile_current; rm ~/unionfile_temp;
    grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile;

fi

echo "All instances on \$projectname_id was created"
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


function create_projects(){
newprojectname=\$(gpw 1 4)-\$(gpw 1 5)-\$(gpw 1 6)
gcloud projects create \$newprojectname

}


while create_projects; do
  echo "All done"
  sleep 1
done
echo ""
echo "All possible projects was created"

gcloud projects list | cut -f 1 -d ' ' | tail -n+2 > ~/projectname_list

split ~/projectname_list -l5 projects

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
sleep 2

while IFS=":" read projectname_id billingname_id; do

function link_to_billing(){
gcloud beta billing projects link \$projectname_id --billing-account \$billingname_id
}


if link_to_billing ; then
    echo "Project \$projectname_id successfully linked to \$billingname_id"
	
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	grep '\$billingname_id' ~/unionfile > ~/relink_list_\$billingname_id
	cat ~/relink_list_\$billingname_id
	sleep 2
	
	echo "Remove all current limited projects from unionfile"
	grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile; rm ~/unionfile_temp;


fi

done < ~/unionfile

echo "All projects was successfully linked to their billings"

echo "Creating instances..."
echo ""
cat ~/unionfile
sleep 2
echo ""

while IFS=":" read projectname_id billingname_id; do

gcloud config set project \$projectname_id	
gcloud services enable compute.googleapis.com


gcloud compute zones list | cut -f 1 -d ' ' | tail -n+2 | shuf > ~/shuffed-regions

firstregion=\$(sed '1!d' shuffed-regions)
secondregion=\$(sed '2!d' shuffed-regions)

function create_instances (){

gcloud compute instances create instance-1 \
--zone=\$firstregion \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/gasteen/opt/master/vst-install.sh | bash -s'
sleep 3s
gcloud compute instances create instance-2 \
--zone=\$secondregion \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/gasteen/opt/master/vst-install.sh | bash -s'
sleep 1s
}

if create_instances ; then
    echo "Instances on \$projectname_id was successfully created..."
	
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	grep '\$billingname_id' ~/unionfile >> ~/relink_list_\$billingname_id
	cat ~/relink_list_\$billingname_id
	sleep 2
	
	echo "Remove all current limited projects from unionfile"
	grep -v '\$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile; rm ~/unionfile_temp;


fi

echo "All instances on \$projectname_id was created"
echo "Going to the next one..."
done < ~/unionfile

cat ~/relink_list_* > ~/relink_union 
rm ~/relink_list_*


echo "Some cleaning..."
rm ~/billinga* ~/projectsa* ~/shuffed-regions
echo "All is done!"
echo ""
echo "billings that need to relink:"
cat ~/relink_union | cut -d: -f2 | sort -u
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
chmod +x ~/start.sh
sudo su
script /dev/null
screen -S nameOfSession bash ~/start.sh
