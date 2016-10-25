#!/bin/bash

_LOGFILE_DATE=`date -d "now + 9 hours " +"%Y%m%d"`
_MODULE_LIST="
10.11.0.15|gw-gex1|/opt/cafx_app/logs/gw-gex1/nts.gw.gaikaex.rate.log
10.11.0.15|gw-gex2|/opt/cafx_app/logs/gw-gex2/nts.gw.gaikaex.rate.log
10.11.0.17|ratemng|/opt/cafx_app/logs/ratemng/dealing.ratemng.log
10.11.0.17|cpratecache_caso|/opt/cafx_app/logs/cpratecache_caso/dealing.cpratecache.log
10.11.0.9|DataSource|/windows/10.1.0.48/caso_app/DataSource/logs/MT4_DATASOURCE.nextop.${_LOGFILE_DATE}.log
"

_CHECK_MIN_START="0"
_CHECK_MIN_END="0"

function get_log(){
    _return=`echo ${_MODULE_LIST} | sed 's/ /\n/g' | grep -v "^#" | grep -wE "$1"`
    _module_ip=`echo ${_return} | awk -F'|' '{print $1}'`
    _module_name=`echo ${_return} | awk -F'|' '{print $2}'`
    _module_log=`echo ${_return} | awk -F'|' '{print $3}'`
    _CHECK_TMP_RETURN="/tmp/check_tmp_${_module_name}.log"
    >${_CHECK_TMP_RETURN}
	for _min in `seq ${_CHECK_MIN_START} ${_CHECK_MIN_END} | sort -nr`
	do
		if [ ${_module_name} == DataSource ]
                  then 
	               _check_date=`date -d "now + 9 hours  ${_min} min " +"%Y/%m/%d %H:%M" `
		       ssh ${_module_ip} " cat ${_module_log} | grep -E '^${_check_date}' "
		  else		
			_check_date=`date -d "${_min} min ago" +"%Y-%m-%d %H:%M" `
			ssh ${_module_ip} " cat ${_module_log}| tr -d '/' | grep -E '^${_check_date}' "
		fi 
#		ssh ${_module_ip} " cat ${_module_log}| tr -d '/' | grep -E '^${_check_date}' "
	done > ${_CHECK_TMP_RETURN}
}



function check_log(){
    _return=`echo ${_MODULE_LIST} | sed 's/ /\n/g' | grep -v "^#" | grep -wE "$1"`
    _module_name=`echo ${_return} | awk -F'|' '{print $2}'`
    _CHECK_TMP_RETURN="/tmp/check_tmp_${_module_name}.log"
    _CHECK_RETURN="/tmp/check_${_module_name}.log"
    >${_CHECK_RETURN}
	case ${_module_name} in
		ratemng)
                		_CHECK_KEY="Publishing front rate"
				_CHECK_KEY1="isTradeable=true"
                ;;
		cpratecache_caso)
				_CHECK_KEY="INFO - Logit - FxBestHedgeRateInfo"
				_CHECK_KEY1=""
		;;
		gw-gex1)
				_CHECK_KEY="35=W"
				_CHECK_KEY1=""
		;;
		gw-gex2)
				_CHECK_KEY="35=W"
				_CHECK_KEY1=""
		;;
		DataSource)
				_CHECK_KEY="DEBUG - Sent:"
				_CHECK_KEY1=""
		;;
	esac
        grep -iwE "${_CHECK_KEY}" ${_CHECK_TMP_RETURN} | grep -iwE "${_CHECK_KEY1}" > ${_CHECK_RETURN}
        if [ -s "${_CHECK_RETURN}" ];
        then
		echo  -e "\e[32m${_module_name} is OK \e[39m....."
	else
		echo  -e "\e[31m${_module_name} is NG \e[39m....."
        fi
}
function check_symbol_log(){
    _return=`echo ${_MODULE_LIST} | sed 's/ /\n/g' | grep -v "^#" | grep -wE "$1"`
    _module_name=`echo ${_return} | awk -F'|' '{print $2}'`
    _CHECK_TMP_RETURN="/tmp/check_tmp_${_module_name}.log"
    _CHECK_RETURN1="/tmp/check1_$2_${_module_name}.log"
    >${_CHECK_RETURN1}
	case ${_module_name} in
		ratemng)
                                _CHECK_KEY="Publishing front rate"
				_CHECK_KEY1="isTradeable=true"
				_CHECK_KEY2="$2"
                ;;
		cpratecache_caso)
				_CHECK_KEY="INFO - Logit - FxBestHedgeRateInfo"
				_CHECK_KEY1=""
				_CHECK_KEY2="$2"
		;;
		gw-gex1)
				_CHECK_KEY="35=W"
				_CHECK_KEY1=""
				_CHECK_KEY2="$2"
		;;
		gw-gex2)
				_CHECK_KEY="35=W"
				_CHECK_KEY1=""
				_CHECK_KEY2="$2"
		;;
		DataSource)
				_CHECK_KEY="DEBUG - Sent:"
				_CHECK_KEY1=""
				_CHECK_KEY2="$2"
		;;
	esac
	
grep -iwE "${_CHECK_KEY}" ${_CHECK_TMP_RETURN} | grep -iwE "${_CHECK_KEY1}" | grep -iwE "${_CHECK_KEY2}" > ${_CHECK_RETURN1}
if [ `ls -l  "${_CHECK_RETURN1}" |awk '{print $5}'` -eq 0 ];
        then
		echo -e "\e[31mSymbol $2 on ${_module_name} is NG \e[39m....."
#else
#		echo -e "\e[32mSymbol $2 on ${_module_name} is OK ....."
fi
}
echo -e "Flow rate:\n"
echo "cp ----> gw ---> ratemng ----> datasource
           |
	   |
	   v
	   cpratecache_caso"
echo ""
get_log gw-gex1;
get_log gw-gex2;
get_log ratemng;
get_log cpratecache_caso;
get_log DataSource;

check_log gw-gex1;
check_log gw-gex2;
check_log ratemng;
check_log cpratecache_caso;
check_log DataSource;

echo "=================================="
echo -e "Check symbol rate error:\n"
for i in `cat /opt/scripts/gex1.txt` ;do check_symbol_log gw-gex1 $i ; done
for j in `cat /opt/scripts/gex2.txt` ;do check_symbol_log gw-gex2 $j ; done
for m in `cat /opt/scripts/ratemng.txt ` ;do check_symbol_log ratemng $m ; done
for n in `cat /opt/scripts/cpratecache_caso.txt` ;do check_symbol_log cpratecache_caso $n ; done
for t in `cat /opt/scripts/DataSource.txt` ;do check_symbol_log DataSource $t ; done
