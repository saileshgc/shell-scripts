#!/bin/bash

CONFIG_FILE="opt/app/config/cleanup.cfg"

if [[ ! -f "${CONFIG_FILE}" ]]
then
        echo "Missing  ${CONFIG_FILE}. Cannot Continue"
        exit 1
fi


echo "Started processing ${CONFIG_FILE}"

cat ${CONFIG_FILE}|grep -v "#" | sed '/^$/d'|
{
while read cfgline
do

cfgcheck=`echo ${cfgline}| sed 's/|/ /g'`
cfgarray=($cfgcheck)

if [[ "${#cfgarray[@]}" -ne 7 ]]
then
        echo "Invalid Configuration. Cannot Continue. Please check configuration file"
        exit 1
fi

        msnameCfg=`echo "${cfgline}" | cut -d\| -f1`
        dirName=`echo "${cfgline}" | cut -d\| -f2`
        retentiondays=`echo "${cfgline}" | cut -d\| -f3`
        retentionhours=`echo "${cfgline}" | cut -d\| -f4`
        retentionmins=`echo "${cfgline}" | cut -d\| -f5`
        filePattern=`echo "${cfgline}" | cut -d\| -f6`
        recursive=`echo "${cfgline}" | cut -d\| -f7`

        dirName=`echo $(eval echo ${dirName})`
       
        #microservice level check
		hostname=`hostname`
        if [[ ! -z "${hostname}" && "${hostname}" != *"${msnameCfg}"* ]]; then
                echo "Skipping ${msnameCfg}"
                continue
        fi

       

        if [[ ! -z "${filePattern}" && "${filePattern}" != "" ]]
        then
                cmd="-type f -name '${filePattern}'"

        fi

        if [[ ! -z "${retentionhours}" && "${retentionhours}" -ne 0 ]]
        then
                totalretentionmins=$((${retentionhours}*60))
        fi

        if [[ ! -z "${retentionmins}" && "${retentionmins}" -ne 0 ]]
        then
                totalretentionmins=$((${totalretentionmins}+${retentionmins}))
        fi

        if [[ ! -z "${totalretentionmins}" && "${totalretentionmins}" -ne 0 ]]
        then
                cmd="${cmd} -mmin +${totalretentionmins}"
        fi

        if [[ ! -z "${retentiondays}" && "${retentiondays}" -ne 0 ]]
        then
                cmd="${cmd} -mtime +${retentiondays}"
        fi
       
        if [[ -d "${dirName}" ]]
        then
                if [[ "${recursive}" == "N" ]]
                then
                        cmd="${cmd} -maxdepth 1"
                fi
                        echo "Found ${dirName}. Proceed with deletion"
                        cmd="find ${dirName} ${cmd}"
                        count=`eval ${cmd} |wc -l`
                        if [[ ${count} -ne 0 ]]
                        then
                                echo "Found ${count} files to be deleted. Proceed with deletion"
                                cmd="${cmd} -delete"
                                eval ${cmd}
                                if [ $? -eq 0 ]
                                then
                                        echo "Deleted  ${count} files with Filepattern ${filePattern}"
                                fi
                        else
                                echo " FileCount is ${count}. No files to be deleted"
                        fi
        else
                echo "Cannot find directory ${dirName}"
        fi
done
}

RUNTIME=$(expr $(now_ms) - $STARTTIME)
echo "End processing cleanup.sh elapsed time = $RUNTIME"
exit 0
