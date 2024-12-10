#!/bin/bash

declare -A tests=(
  ["Check_kubectl"]="command_check kubectl"
  ["Check_helm"]="command_check helm"
  ["Check_docker"]="command_check docker"
  ["Check_grafana"]="http_health_check http://localhost:3000/api/health 'database.*ok'"
  ["Check_prometheus"]="http_health_check http://localhost:30900/-/ready 'Ready'"
  ["Check_promtail"]="http_health_check http://localhost:31059/ready 'Ready'"
  ["Check_Loki"]="loki_health_check"
  ["Check_cephblockpool"]="run_command kubectl -n rook-ceph get cephblockpool replicapool -o jsonpath='{.status.phase}' Ready"
  ["Check_swagger-petstore"]="curl_check http://localhost:30080"
)

declare -A results
details=()
failed_counter=0


command_check() {
  command -v "$1" &> /dev/null
}

http_health_check() {
  local url=$1
  local expected=$2
  echo "Trying -> curl -s $url"
  for i in {1..50}; do
    if curl -s "$url" | grep -q "$expected"; then
      echo "OK"
      return 0
    fi
    echo -n "."
    sleep 1 
  done
  echo "FAILED"
  return 1 
}

loki_health_check() {
  kubectl exec -n monitoring "$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s loki-loki-distributed-memberlist.monitoring.svc.cluster.local:3100/ready | grep -q 'ready'
}

run_command(){
    last_arg="${!#}"  
   "${@:1:$(($#-1))}" | grep -q "$last_arg"
}

curl_check() {
    curl $@ &> /dev/null
}

# Run tests
for test_name in "${!tests[@]}"; do
  eval "${tests[$test_name]}"
  if [ $? -eq 0 ]; then
    results["$test_name"]="PASS"
  else
    ((failed_counter++))
    results["$test_name"]="FAIL"
    details["$test_name"]="$test_name: FAILED"
  fi
done

# Print summary
echo "==============================="
for test_name in "${!tests[@]}"; do
  if [ "${results[$test_name]}" == "PASS" ]; then
    echo "${test_name}: ${results[$test_name]}"
  else
    echo "${details[$test_name]}"
  fi
done

echo "==============================="
if [ "$failed_counter" -eq 0 ]; then 
  echo "All tests PASSED"
else
  echo "$failed_counter test(s) FAILED"
fi
echo

exit "$failed_counter"
