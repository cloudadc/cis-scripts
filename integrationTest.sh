#! /bin/bash  

BIGIP_USER="admin"
BIGIP_PASS="admin"
BIGIP_MGMT_IP="192.168.200.204"

WAIT_TIME_AFTER_K8S_COMMAND=30
MAX_TIME_FOR_HTTP_CURL=5

VS_IP_001=192.168.200.31
VS_IP_002=192.168.200.32
VS_IP_003=192.168.200.33
VS_IP_004=192.168.200.34
VS_IP_005=192.168.200.35
VS_IP_006=192.168.200.36
VS_IP_007=192.168.200.37
VS_IP_008=192.168.200.38
VS_IP_009=192.168.200.39
VS_IP_010=192.168.200.40
VS_IP_011=192.168.200.41
VS_IP_012=192.168.200.42
VS_IP_013=192.168.200.43
VS_IP_014=192.168.200.44
VS_IP_015=192.168.200.45
VS_IP_016=192.168.200.46
VS_IP_017=192.168.200.47

GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[0;37m'
RESET='\033[0m'

echo "CIS Integration Test"

function_kubectl()
{
FOLDER=$1
FILE=$2

kubectl apply -f $FOLDER/$FILE
}

function_kubectl_cm()
{
FOLDER=$1
FILE=$2

kubectl apply -f $FOLDER/$FILE
sleep $WAIT_TIME_AFTER_K8S_COMMAND
}

assertEqual()
{
TEST=$1
STR_1=$2
STR_2=$3
if [[ -z $STR_1 ]] || [[ -z $STR_2 ]]; then
    echo -e "${RED}  $TEST - failed${RESET}"
elif [ "$STR_1" == "$STR_2" ]; then
    echo -e "${GREEN}  $TEST - pass${RESET}"
else
    echo -e "${RED}  $TEST - failed${RESET}"
fi
}

assertContains()
{
TEST=$1
STR_1=$2 
STR_2=$3 
if [[ -z $STR_1 ]] || [[ -z $STR_2 ]]; then
    echo -e "${RED}  $TEST - failed${RESET}"
elif [[ "$STR_1" == *"$STR_2"* ]]; then
    echo -e "${GREEN}  $TEST - pass${RESET}"
else
    echo -e "${RED}  $TEST - failed${RESET}"
fi
}

waitToDeploy()
{
TEST=$1
SVC=$2
for i in {1..10}
do
  statuscode=$(curl -s -m $MAX_TIME_FOR_HTTP_CURL --write-out %{http_code} --output /dev/null $SVC)
  if [ $statuscode == 200 ]; then
    break
  else
    sleep 3  
  fi
done
if [ $statuscode -ne 200 ]; then
    read -n 1 -s -r -p "After 30 seconds wait $TEST to finish deploy, plase check manually, and press any key to continue..."
    echo "   TEST CONTINUE!"
fi
}

test_function_001()
{
TEST=001
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
waitToDeploy $TEST http://$VS_IP_001
COOKIE=$(curl -s -m $MAX_TIME_FOR_HTTP_CURL http://$VS_IP_001 -I | grep Set-Cookie | awk '{print $2 $3 $4}')
ADDRESS_1=$(curl -s -m $MAX_TIME_FOR_HTTP_CURL --cookie "$COOKIE" http://$VS_IP_001/test | grep address | awk '{print $3}')
ADDRESS_2=$(curl -s -m $MAX_TIME_FOR_HTTP_CURL --cookie "$COOKIE" http://$VS_IP_001/user | grep address | awk '{print $3}')
assertEqual $TEST $ADDRESS_1 $ADDRESS_2
}

test_function_002()
{
TEST=002
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
waitToDeploy $TEST http://$VS_IP_002
COOKIE=$(curl -s -m $MAX_TIME_FOR_HTTP_CURL http://$VS_IP_002 -I | grep Set-Cookie | awk '{print $2 $3 $4}')
ADDRESS_1=$(curl -s -m $MAX_TIME_FOR_HTTP_CURL --cookie "$COOKIE" http://$VS_IP_002/test | grep address | awk '{print $3}')
ADDRESS_2=$(curl -s -m $MAX_TIME_FOR_HTTP_CURL --cookie "$COOKIE" http://$VS_IP_002/user | grep address | awk '{print $3}')
assertEqual $TEST $ADDRESS_1 $ADDRESS_2
}

test_function_003() 
{
TEST=003
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
waitToDeploy $TEST http://$VS_IP_003
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest003~app-1~app_1_svc_pool?\$select=monitor")
assertContains $TEST "$RESP" "custom_http_monitor"
}

test_function_004() 
{
TEST=004
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.1.yaml"
waitToDeploy $TEST http://$VS_IP_004
RESP_1=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest004~app-1~app_1_svc_pool?\$select=monitor")
function_kubectl_cm $TEST "cm.2.yaml"
waitToDeploy $TEST http://$VS_IP_004
RESP_2=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest004~app-1~app_1_svc_pool?\$select=monitor")
function_kubectl_cm $TEST "cm.3.yaml"
waitToDeploy $TEST http://$VS_IP_004
RESP_3=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest004~app-1~app_1_svc_pool?\$select=monitor")
function_kubectl_cm $TEST "cm.1.yaml"
waitToDeploy $TEST http://$VS_IP_004
RESP_4=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest004~app-1~app_1_svc_pool?\$select=monitor")
if [[ -z $RESP_1 ]] || [[ -z $RESP_2 ]] || [[ -z $RESP_3 ]] || [[ -z $RESP_4 ]]; then
    echo -e "${RED}  $TEST - failed${RESET}"
elif [[ "$RESP_1" == *"tcp"* ]] && [[ "$RESP_2" == *"tcp"* ]] && [[ "$RESP_2" == *"custom_http_monitor"* ]] && [[ "$RESP_3" == *"http"* ]] && [[ "$RESP_4" == *"tcp"* ]]; then
    echo -e "${GREEN}  $TEST - pass${RESET}"
else
    echo -e "${RED}  $TEST - failed${RESET}"
fi
}

test_function_005() 
{
TEST=005
function_kubectl $TEST "app-1.yaml"
function_kubectl $TEST "app-2.yaml"
function_kubectl_cm $TEST "cm.yaml"
waitToDeploy $TEST http://$VS_IP_005
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/rule/~cistest005~app-1~iRulesHere?\$select=apiAnonymous")
assertContains $TEST "$RESP" "HTTP_REQUEST"
}

test_function_006() 
{
TEST=006
function_kubectl $TEST "app-1.yaml"
function_kubectl $TEST "app-2.yaml"
function_kubectl_cm $TEST "cm.yaml"
waitToDeploy $TEST http://$VS_IP_006
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/virtual/~cistest006~app~app_svc_vs/policies/~cistest006~app~forward_policy?\$select=fullPath")
assertContains $TEST "$RESP" "forward_policy"
}

test_function_007() 
{
TEST=007
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
waitToDeploy $TEST http://$VS_IP_007
RESP_1=$(curl -s http://$VS_IP_007 | grep address | awk '{print $3}')
RESP_2=$(curl -s http://$VS_IP_007 | grep address | awk '{print $3}')
assertEqual $TEST $RESP_1 $RESP_2
}

test_function_008() 
{
TEST=008
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
waitToDeploy $TEST http://$VS_IP_008
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/virtual/~cistest008~app-1~app_svc_vs?\$select=mirror")
assertContains $TEST "$RESP" "enabled"
}

test_function_009() 
{
TEST=009
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm-1.yaml"
waitToDeploy $TEST http://$VS_IP_009
RESP_1=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest009~app-1~app_1_svc_pool?\$select=loadBalancingMode")
function_kubectl_cm $TEST "cm-2.yaml"
waitToDeploy $TEST http://$VS_IP_009
RESP_2=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest009~app-1~app_1_svc_pool?\$select=loadBalancingMode")
function_kubectl_cm $TEST "cm-3.yaml"
waitToDeploy $TEST http://$VS_IP_009
RESP_3=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest009~app-1~app_1_svc_pool?\$select=loadBalancingMode")
function_kubectl_cm $TEST "cm-1.yaml"
waitToDeploy $TEST http://$VS_IP_009
RESP_4=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/pool/~cistest009~app-1~app_1_svc_pool?\$select=loadBalancingMode")

if [[ -z $RESP_1 ]] || [[ -z $RESP_2 ]] || [[ -z $RESP_3 ]] || [[ -z $RESP_4 ]]; then
    echo -e "${RED}  $TEST - failed${RESET}"
elif [[ "$RESP_1" == *"least-connections-member"* ]] && [[ "$RESP_2" == *"round-robin"* ]] && [[ "$RESP_3" == *"least-sessions"* ]] && [[ "$RESP_4" == *"least-connections-member"* ]]; then
    echo -e "${GREEN}  $TEST - pass${RESET}"
else
    echo -e "${RED}  $TEST - failed${RESET}"
fi
}


test_function_010() 
{
TEST=010
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/snatpool/~cistest010~app-1~app_svc_vs-self?\$select=fullPath")
assertContains $TEST "$RESP" "app_svc_vs-self"
}

test_function_011() 
{
TEST=011
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/virtual/~cistest011~app-1~app_svc_vs/profiles/~cistest011~app-1~customTCPProfile?\$select=fullPath")
assertContains $TEST "$RESP" "customTCPProfile"
}

test_function_012() 
{
TEST=012
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/virtual/~cistest012~app-1~app_svc_vs/profiles/~cistest012~app-1~customHTTPProfile?\$select=fullPath")
assertContains $TEST "$RESP" "customHTTPProfile"
}

test_function_013() 
{
TEST=013
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/virtual/~cistest013~app-1~app_svc_vs/profiles/~cistest013~app-1~customOneConnectProfile?\$select=fullPath")
assertContains $TEST "$RESP" "customOneConnectProfile"
}

test_function_014() 
{
TEST=014
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
statuscode=$(curl -k -s -m $MAX_TIME_FOR_HTTP_CURL --write-out %{http_code} --output /dev/null https://$VS_IP_014)
if [ $statuscode == 200 ]; then
  echo -e "${GREEN}  $TEST - pass${RESET}"
else
  echo -e "${RED}  $TEST - failed${RESET}"
fi
}

test_function_015() 
{
TEST=015
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
statuscode=$(curl -k -s -m $MAX_TIME_FOR_HTTP_CURL --write-out %{http_code} --output /dev/null http://$VS_IP_015)
if [ $statuscode == 200 ]; then
  echo -e "${GREEN}  $TEST - pass${RESET}"
else
  echo -e "${RED}  $TEST - failed${RESET}"
fi
}

test_function_016() 
{
TEST=016
function_kubectl_cm $TEST "cm-2.yaml"
RESP=$(curl -k -s -u "$BIGIP_USER:$BIGIP_PASS"  "https://$BIGIP_MGMT_IP/mgmt/tm/ltm/virtual/~cistest016~app-1~app_svc_vs?\$select=serviceDownImmediateAction")
assertContains $TEST "$RESP" "reset"
}

test_function_017() 
{
TEST=017
function_kubectl $TEST "app.yaml"
function_kubectl_cm $TEST "cm.yaml"
statuscode=$(curl -s -m $MAX_TIME_FOR_HTTP_CURL --write-out %{http_code} --output /dev/null http://$VS_IP_017)
if [ $statuscode == 200 ]; then
  echo -e "${GREEN}  $TEST - pass${RESET}"
else
  echo -e "${RED}  $TEST - failed${RESET}"
fi
}

test_function_018() 
{
TEST=018
function_kubectl $TEST "app.yaml"
sleep 1
ns=bigip-ctlr
RESP=$(kubectl logs $(kubectl get pods -n $ns --no-headers | awk '{print $1}') -n $ns | grep "Multiple Services are tagged")
length=$(echo $RESP | awk '{print length}')
if  [[ $length -ge 0 ]]; then
  echo -e "${GREEN}  $TEST - pass${RESET}"
else
  echo -e "${RED}  $TEST - failed${RESET}"
fi 
}


test_function_001
test_function_002
test_function_003
test_function_004
test_function_005
test_function_006
test_function_007
test_function_008
test_function_009
test_function_010
test_function_011
test_function_012
test_function_013
test_function_014
test_function_015
test_function_016
test_function_017
test_function_018
