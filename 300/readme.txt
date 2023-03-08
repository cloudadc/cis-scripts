= How to do ?
 
Test Performance in 5 sevices counts dimension(50, 100, 150, 200, 250), on each dimension we should record:

1. add 50 svc times
2. add 1 svc times
3. scale up(pool members from 1 to 2) 1 svc times
4. add 1 svc times


[source, bash]
.*50 SVC*
----
kubectl apply -f deploy-50.yaml
kubectl apply -f cm-50.yaml

kubectl apply -f deploy-51.yaml
kubectl apply -f cm-51.yaml

kubectl scale -n bigip-ctlr-ns-2 deploy/app-svc-25-app --replicas=2

kubectl apply -f cm-50.yaml

kubectl scale -n bigip-ctlr-ns-2 deploy/app-svc-25-app --replicas=1
----

[source, bash]
.*100 SVC*
----
kubectl apply -f deploy-100.yaml
kubectl apply -f cm-100.yaml

kubectl apply -f deploy-101.yaml
kubectl apply -f cm-101.yaml

kubectl scale -n bigip-ctlr-ns-4 deploy/app-svc-25-app --replicas=2

kubectl apply -f cm-100.yaml

kubectl scale -n bigip-ctlr-ns-4 deploy/app-svc-25-app --replicas=1
----

[source, bash]
.*150 SVC*
----
kubectl apply -f deploy-150.yaml
kubectl apply -f cm-150.yaml

kubectl apply -f deploy-151.yaml
kubectl apply -f cm-151.yaml

kubectl scale -n bigip-ctlr-ns-6 deploy/app-svc-25-app --replicas=2

kubectl apply -f cm-150.yaml

kubectl scale -n bigip-ctlr-ns-6 deploy/app-svc-25-app --replicas=1
----

[source, bash]
.*200 SVC*
----
kubectl apply -f deploy-200.yaml
kubectl apply -f cm-200.yaml

kubectl apply -f deploy-201.yaml
kubectl apply -f cm-201.yaml

kubectl scale -n bigip-ctlr-ns-8 deploy/app-svc-25-app --replicas=2

kubectl apply -f cm-200.yaml

kubectl scale -n bigip-ctlr-ns-8 deploy/app-svc-25-app --replicas=1
----

[source, bash]
.*250 SVC*
----
kubectl apply -f deploy-249.yaml
kubectl apply -f cm-249.yaml

kubectl apply -f deploy-250.yaml
kubectl apply -f cm-250.yaml

kubectl scale -n bigip-ctlr-ns-10 deploy/app-svc-24-app --replicas=2

kubectl apply -f cm-249.yaml

kubectl scale -n bigip-ctlr-ns-10 deploy/app-svc-24-app --replicas=1
----
