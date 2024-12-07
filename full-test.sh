#!/bin/bash

tests=("Check kubectl" "Check helm" "Check docker" "Check swagger" "Check ceph-pool pvc" "Check grafana" ...)
results=()
details=()

check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    return 1
  fi
  return 0
}

check_helm() {
  if ! command -v helm &> /dev/null; then
    return 1
  fi
  return 0
}

check_docker() {
  if ! command -v docker &> /dev/null; then
    return 1
  fi
  return 0
}

# Run tests
for test_name in "${tests[@]}"; do
  case $test_name in
    "Check kubectl")
        check_kubectl
        test_result=$?
        ;;
     "Check helm")
        check_helm
        test_result=$?    
        ;;
    "Check docker")
        check_helm
        test_result=$?
        ;;
  esac
  
  if [ $test_result -ne 0 ]; then
    results+=("FAIL")
    details+=("$test_name failed. See test_results.log for details.")
  else
    results+=("PASS")
    details+=("$test_name passed.")
  fi
done

# Print summary
echo "Test Summary:"
for i in "${!tests[@]}"; do
  if [ "${results[$i]}" = "PASS" ]; then
    echo -e "${GREEN}${tests[$i]}: ${results[$i]}${NC}"
  else
    echo -e "${RED}${tests[$i]}: ${results[$i]}${NC}"
  fi
done

# Print details for fails
for i in "${!tests[@]}"; do
  [ "${results[$i]}" = "FAIL" ] && echo "${details[$i]}"
done


#2 verify helm is installed
#3 verify docker is installed
#4 swagger is spun off
#5 verivy ceph-pool pvc, ceph-cluster, ceph status
#6 Verify grafana, promtail, loki are availiable 

#kubectl -n rook-ceph exec -it $( kubectl get pods -n rook-ceph -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') -- bash
# kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') -- bash
# ceph osd status
# ceph osd tree
# 
#  kubectl -n rook-ceph get cephblockpool replicapool
# NAME          PHASE   TYPE         FAILUREDOMAIN   AGE
# replicapool   Ready   Replicated   host            20m
# 
#  kubectl get pvc rook-ceph-pvc
# NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      VOLUMEATTRIBUTESCLASS   AGE
# rook-ceph-pvc   Bound    pvc-d3fc2e36-3e0e-4fd4-8720-43e9175a97bd   1Gi        RWO            rook-ceph-block   <unset>                 20m
# 
# kubectl -n rook-ceph get cephcluster
# NAME        DATADIRHOSTPATH   MONCOUNT   AGE   PHASE   MESSAGE                        HEALTH        EXTERNAL   FSID
# rook-ceph   /var/lib/rook     1          64m   Ready   Cluster created successfully   HEALTH_WARN              7eeab713-23fe-4e0e-a98a-c9b7d93af12
# 
#  kubectl -n rook-ceph get pods -l app=rook-ceph-osd
# NAME                               READY   STATUS    RESTARTS   AGE
# rook-ceph-osd-0-57bf5d558d-k7st8   1/1     Running   0          21m
# rook-ceph-osd-1-7bcbcd74b-msdrc    1/1     Running   0          21m
# rook-ceph-osd-2-7855cc7b4d-spqmh   1/1     Running   0          21m
# rook-ceph-osd-3-85c9b749b-lfxpx    1/1     Running   0          20m
