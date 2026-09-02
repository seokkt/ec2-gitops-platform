# Monitoring

## Architecture

Prometheus와 Grafana를 `monitoring` 네임스페이스에 각각 단일 Deployment로 실행한다. 두 서비스는 ClusterIP로만 제공하며 외부 Ingress를 만들지 않는다. Prometheus는 Kubernetes Pod discovery로 `demo` 네임스페이스의 demo-api Pod 두 개를 개별 타깃으로 수집하고, Grafana는 내부 DNS로 Prometheus에 연결한다.

구성은 다음 흐름을 따른다.

```text
demo-api Pods (/metrics) <- Prometheus <- Grafana
                              |             |
                           2Gi PVC       1Gi PVC
```

## Lightweight design

단일 t3.small 노드의 CPU와 메모리를 보수적으로 사용하기 위해 kube-prometheus-stack과 Prometheus Operator를 사용하지 않는다. Alertmanager, kube-state-metrics, node-exporter, Loki, Tempo, OpenTelemetry Collector도 이번 범위에서 제외한다. Prometheus 보존 기간은 4시간, 보존 크기는 512MB로 제한한다. Grafana analytics reporting과 update check도 비활성화하며 추가 플러그인은 설치하지 않는다.

## Pod discovery

Prometheus ServiceAccount는 cluster-admin 권한 없이 Pod의 `get`, `list`, `watch`만 허용받는다. `role: pod` Kubernetes service discovery 결과 중 다음 조건을 모두 만족하는 타깃만 유지한다.

- namespace: `demo`
- Pod label: `app=demo-api`
- Pod phase: `Running`
- container port: `8000`
- metrics path: `/metrics`

Service를 통하지 않으므로 Prometheus의 Targets 화면에는 각 demo-api Pod가 별도 타깃으로 표시된다.

## Create the Grafana secret

Grafana 관리자 비밀번호는 Git에 저장하지 않는다. 모니터링 Application을 적용하기 전에 k3s EC2에서 다음 스크립트를 실행한다. 입력한 비밀번호는 화면이나 파일에 출력되지 않는다.

```bash
cd ~/ec2-gitops-platform
bash scripts/create-grafana-secret.sh
```

스크립트는 `monitoring` 네임스페이스를 안전하게 생성하고 `grafana-admin` Secret을 생성 또는 갱신한다. 관리자 사용자 이름은 `admin`이다.

## Apply the ArgoCD Application

변경된 저장소를 GitHub에 반영한 후 다음 명령으로 monitoring Application을 등록한다.

```bash
cd ~/ec2-gitops-platform
git pull --ff-only origin main
kubectl apply -f kubernetes/argocd/monitoring-application.yaml
kubectl get application monitoring -n argocd
kubectl get pods,pvc,svc -n monitoring
```

## Access Prometheus

첫 번째 터미널에서 다음 명령을 유지한다.

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

브라우저에서 `http://localhost:9090`에 접속한다. 원격 EC2에서 port-forward를 실행한다면 SSH 터널을 함께 사용한다.

```bash
ssh -L 9090:localhost:9090 ubuntu@<K3S_PUBLIC_IP>
```

## Access Grafana

다른 터미널에서 다음 명령을 유지한다.

```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

브라우저에서 `http://localhost:3000`에 접속하고 `admin`과 Secret 생성 시 입력한 비밀번호를 사용한다. `EC2 GitOps/EC2 GitOps Demo API` 대시보드는 provisioning으로 자동 생성되며 Prometheus Data Source도 수동 등록할 필요가 없다.

원격 EC2에서 port-forward를 실행한다면 별도 SSH 터널을 사용할 수 있다.

```bash
ssh -L 3000:localhost:3000 ubuntu@<K3S_PUBLIC_IP>
```

## Generate test traffic

k3s EC2의 Traefik이 제공하는 localhost 포트 80을 통해 트래픽을 생성한다.

```bash
for i in $(seq 1 100); do
  curl -s http://localhost/api/hello > /dev/null
done
```

Grafana 대시보드의 기본 시간 범위는 최근 15분이며 10초마다 새로 고침된다.

## Check Prometheus targets

Prometheus port-forward를 실행한 상태에서 `http://localhost:9090/targets`를 연다. `prometheus` 타깃 한 개와 `demo-api` Pod 타깃 두 개가 `UP`인지 확인한다. CLI로도 확인할 수 있다.

```bash
curl -s http://localhost:9090/api/v1/targets
```

## Troubleshooting

Pod나 PVC 상태를 먼저 확인한다.

```bash
kubectl get pods,pvc,svc -n monitoring
kubectl describe pod -n monitoring -l app=prometheus
kubectl describe pod -n monitoring -l app=grafana
kubectl logs -n monitoring deployment/prometheus
kubectl logs -n monitoring deployment/grafana
```

Grafana Pod가 `CreateContainerConfigError`라면 Secret과 키를 확인한다.

```bash
kubectl get secret grafana-admin -n monitoring
kubectl describe pod -n monitoring -l app=grafana
```

Prometheus에서 demo-api 타깃이 보이지 않으면 Pod label, 포트 및 RBAC를 확인한다.

```bash
kubectl get pods -n demo -l app=demo-api --show-labels
kubectl get pods -n demo -l app=demo-api -o wide
kubectl auth can-i list pods --as=system:serviceaccount:monitoring:prometheus -n demo
```

Grafana에 대시보드나 Data Source가 나타나지 않으면 provisioning ConfigMap과 Grafana 로그를 확인한다.

```bash
kubectl get configmap -n monitoring
kubectl logs -n monitoring deployment/grafana
```
