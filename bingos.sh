#!/bin/bash

sudo apt -y install gpw
sudo apt -y install screen
if [ -z "$STY" ]; then exec screen -dm -S screenName /bin/bash "$0"; fi


while true
do
  #тут проверка существования файлов

FILEUNION=~/unionfile
if [ -f $FILEUNION ]; then
   echo "Файл '$FILEUNION' существует."
   echo "Starting one more time script now..."

#записываем список созданных в первый раз безлимитных проектов и биллингов в файл previous 
cat ~/unionfile | cut -d":" -f1 | uniq > ~/projectname_list_previous
cat ~/unionfile | cut -d":" -f2 | uniq > ~/billings_list_previous

#функция создания проектов
function create_projects(){
newprojectname=$(gpw 1 4)-$(gpw 1 5)-$(gpw 1 6)
gcloud projects create $newprojectname

}

#создаем все возможные проекты
while create_projects; do
  echo "All done"
  sleep 1
done

echo "All possible projects was created"

#получаем список всех существующих проектов
gcloud projects list | cut -f 1 -d ' ' | tail -n+2 > ~/projectname_list

echo ""
echo "All project list:"
echo ""
cat ~/projectname_list
echo ""
sleep 2

echo ""
echo ""
# получаем список новых неюзанных проектов 
cat ~/projectname_list ~/projectname_list_previous |sort |uniq -u > ~/projectname_list_current
echo ""
echo ""
echo "Projects for current work:"
echo ""
cat ~/projectname_list_current
echo ""
sleep 2
#comm -2 -3 projectname_list projectname_list_previous > projectname_list_current

#получаем файл проектов биллингов с количеством одинаковых биллингов из файла релинков
echo ""
cat ~/relink_union | cut -d":" -f2 | sort | uniq -c > ~/relink_output
echo ""
echo "List projects and billings with numbers match from relink_union was created:"
cat ~/relink_output
echo ""
sleep 2


#считаем биллинги с незанятыми слотами из файла релинков (меньше 5)
N=5
while IFS=" " read -r n billingname_to_add_id; do
  if [ $n -lt $N ] # если $n < $N
  then
    #считаем сколько нужно добавить
	Nres=$(($N-$n))
	#считываем в массив нужное количество первых строк
	mapfile -t arr < <(cat ~/projectname_list_current | head -n $Nres)
#удаляем данное количество первых строк
sed -i "1,$Nres d" ~/projectname_list_current
echo ""
echo "Reading N project from current list and cut and paste to unionfile_current"
echo ""
#формируем список проект:билл для релинка
for i in "${arr[@]}"
do
   echo "$i:$billingname_to_add_id" >> ~/unionfile_current
   echo ""
   echo "Adding new pair to unionfile_curent:"
   echo ""
   cat ~/unionfile_current
   # or do whatever with individual element of the array
sleep 2
done
	
  fi
done < <(cat ~/relink_output | cut -d":" -f2 | sort | uniq | column -t)



#получаем файл проектов биллингов с количеством одинаковых биллингов из файла сделанных

echo ""
cat ~/unionfile | cut -d":" -f2 | sort | uniq -c > ~/output
echo ""
echo "List projects and billings with numbers match was created:"
cat ~/output
echo ""
sleep 2

#считаем биллинги с незанятыми слотами из файла сделанных (меньше 5)
N=5
while IFS=" " read -r n billingname_to_add_id; do
  if [ $n -lt $N ] # если $n < $N
  then
    
	Nres=$(($N-$n))
	mapfile -t arr < <(cat ~/projectname_list_current | head -n $Nres)
sed -i "1,$Nres d" ~/projectname_list_current
echo ""
echo "Reading N project from current list and cut and paste to unionfile_current"
echo ""
for i in "${arr[@]}"
do
   echo "$i:$billingname_to_add_id" >> ~/unionfile_current
   echo ""
   echo "Adding new pair to unionfile_curent:"
   echo ""
   cat ~/unionfile_current
   # or do whatever with individual element of the array
sleep 2
done
	
  fi
done < <(cat ~/output | cut -d":" -f2 | sort | uniq | column -t)

while IFS=":" read projectname_id billingname_id; do

function link_to_billing(){
gcloud beta billing projects link $projectname_id --billing-account $billingname_id
}


if link_to_billing ; then
    echo "Project $projectname_id successfully linked to $billingname_id"
	
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	#сохранение пятерки (или хвоста)лимитного биллинга в файл для последующего релинка
	grep '$billingname_id' ~/unionfile_current >> ~/relink_list_$billingname_id
	#experimental
	grep '$billingname_id' ~/unionfile >> ~/relink_list_$billingname_id
	#
	cat ~/relink_list_$billingname_id | sort -u > ~/relink_list_sorted_$billingname_id
	mv ~/relink_list_sorted_$billingname_id ~/relink_list_$billingname_id
	sleep 2
	
	echo "Remove all current limited projects from unionfile"
	# удаляем из файла unionfile все проекты с лимитным биллингом
	grep -v '$billingname_id' ~/unionfile_current > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile_current;
    # experimental
	grep -v '$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile;
fi

done < ~/unionfile_current

Echo "All projects was successfully linked to their billings"


echo "Creating instances from unionfile_current..."
echo ""
cat ~/unionfile_current
sleep 2
echo ""

while IFS=":" read projectname_id billingname_id; do

gcloud config set project $projectname_id	
gcloud services enable compute.googleapis.com


gcloud compute zones list | cut -f 1 -d ' ' | tail -n+2 | shuf > ~/shuffed-regions

firstregion=$(sed '1!d' shuffed-regions)
secondregion=$(sed '2!d' shuffed-regions)

function create_instances (){

gcloud compute instances create instance-1 \
--zone=$firstregion \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/gasteen/opt/master/vst-install.sh | bash -s'
sleep 3s
gcloud compute instances create instance-2 \
--zone=$secondregion \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/gasteen/opt/master/vst-install.sh | bash -s'
sleep 1s
}

if create_instances ; then
    echo "Instances on $projectname_id was successfully created..."
	
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	#сохранение пятерки (или хвоста)
	grep '$billingname_id' ~/unionfile_current >> ~/relink_list_$billingname_id
	grep '$billingname_id' ~/unionfile >> ~/relink_list_$billingname_id
	cat ~/relink_list_$billingname_id | sort -u > ~/relink_list_sorted_$billingname_id
	mv ~/relink_list_sorted_$billingname_id ~/relink_list_$billingname_id
	sleep 2
	
	echo "Remove all current limited projects from unionfile"
	grep -v '$billingname_id' ~/unionfile_current > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile_current; rm ~/unionfile_temp;
    grep -v '$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile;

fi

echo "All instances on $projectname_id was created"
echo "Going to the next one..."
done < ~/unionfile_current

cat ~/relink_list_* > ~/relink_union 
rm ~/relink_list_*
#cat ~/unionfile ~/unionfile_current

echo "Some cleaning..."
rm ~/billinga* ~/projectsa* ~/shuffed-regions
echo "All is done!"
echo ""
#если нет, то выполняется первая часть скрипта

else
   echo "Файл '$FILEUNION' не найден."
    echo "Starting first time script now..."


function create_projects(){
newprojectname=$(gpw 1 4)-$(gpw 1 5)-$(gpw 1 6)
gcloud projects create $newprojectname

}


while create_projects; do
  echo "All done"
  sleep 1
done
echo ""
echo "All possible projects was created"

##############################################
# получаем список всех существующих проектов
gcloud projects list | cut -f 1 -d ' ' | tail -n+2 > ~/projectname_list
# делим список проектов на пятерки + остаток

split ~/projectname_list -l5 projects

# получаем список всех существующих биллингов
gcloud beta billing accounts list | cut -f 1 -d ' ' | tail -n+2 > ~/billings_list
# делим список биллингов на единицы
split ~/billings_list -l1 billing

# функция генерации списка проект:биллинг из существующих данных
function generate_project_billing_list(){

exec 2>/dev/null

for index in {a..z}

do

awk -v OFS=: '
    # read the smaller file into memory
    NR == FNR {size2++; billinga'$index'[FNR] = $0; next}
    # store the last line of the array as the zero-th element
    FNR == 1 && NR > 1 {billinga'$index'[0] = billinga'$index'[size2]}
    # print the current line of projects and the corresponding billing line
    {print $0, billinga'$index'[FNR % size2]}
' billinga$index projectsa$index >> ~/unionfile

done
}

#Генерация списка проект:биллинг
generate_project_billing_list
echo "Projects and billings list was successfully generated"

cat ~/unionfile
sleep 2

while IFS=":" read projectname_id billingname_id; do

function link_to_billing(){
gcloud beta billing projects link $projectname_id --billing-account $billingname_id
}


if link_to_billing ; then
    echo "Project $projectname_id successfully linked to $billingname_id"
	
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	#сохранение пятерки (или хвоста)
	grep '$billingname_id' ~/unionfile > ~/relink_list_$billingname_id
	cat ~/relink_list_$billingname_id
	sleep 2
	
	echo "Remove all current limited projects from unionfile"
	grep -v '$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile; rm ~/unionfile_temp;


fi

done < ~/unionfile

Echo "All projects was successfully linked to their billings"

echo "Creating instances..."
echo ""
cat ~/unionfile
sleep 2
echo ""

while IFS=":" read projectname_id billingname_id; do

gcloud config set project $projectname_id	
gcloud services enable compute.googleapis.com


gcloud compute zones list | cut -f 1 -d ' ' | tail -n+2 | shuf > ~/shuffed-regions

firstregion=$(sed '1!d' shuffed-regions)
secondregion=$(sed '2!d' shuffed-regions)

function create_instances (){

gcloud compute instances create instance-1 \
--zone=$firstregion \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/gasteen/opt/master/vst-install.sh | bash -s'
sleep 3s
gcloud compute instances create instance-2 \
--zone=$secondregion \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/gasteen/opt/master/vst-install.sh | bash -s'
sleep 1s
}

if create_instances ; then
    echo "Instances on $projectname_id was successfully created..."
	
else
    echo "Error limit was detected. Save projects to relink file and continue"
	
	#сохранение пятерки (или хвоста)
	grep '$billingname_id' ~/unionfile >> ~/relink_list_$billingname_id
	cat ~/relink_list_$billingname_id
	sleep 2
	
	echo "Remove all current limited projects from unionfile"
	grep -v '$billingname_id' ~/unionfile > ~/unionfile_temp; mv ~/unionfile_temp ~/unionfile; rm ~/unionfile_temp;


fi

echo "All instances on $projectname_id was created"
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
  if [[ "$x" == 'q' ]]
  then
    break
  fi
done 
