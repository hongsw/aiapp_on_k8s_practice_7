# 7차시: 설정 관리와 보안

## 학습 목적
- ConfigMap을 사용하여 애플리케이션 설정 관리
- Secret을 활용한 민감 정보 보호
- Kubernetes에서 안전한 설정 관리 방법

## 주요 개념
- **ConfigMap**: 키-값 쌍으로 애플리케이션 설정을 저장
- **Secret**: 암호화된 민감 정보를 저장
- **보안**: 클러스터 외부로는 노출되지 않는 설계

## 실습 실행 방법

### 1. ConfigMap 생성 및 사용
```bash
# ConfigMap 생성
kubectl apply -f configmap.yaml

# ConfigMap 확인
kubectl get configmaps
kubectl describe configmap app-config

# 데이터 확인
kubectl get configmap app-config -o yaml
```

### 2. Secret 생성 및 사용
```bash
# Secret 생성
kubectl apply -f secret.yaml

# Secret 확인 (데이터는 인코딩됨)
kubectl get secrets
kubectl describe secret app-secret

# Secret 데이터 디코드해서 확인
kubectl get secret app-secret -o 'go-template={{index .data "username"}}' | base64 --decode
```

### 3. Pod에서 ConfigMap과 Secret 사용
```bash
# 환경 변수로 설정 사용
kubectl run test-pod --image=busybox --env-from=configmap/app-config --env-from=secret/app-secret

# 볼륨으로 파일로 마운트
kubectl create configmap my-config-file --from-file=config.properties
kubectl run nginx-pod --image=nginx --volume-mount='name=config-vol,mountPath=/etc/config' --volume='name=config-vol,configMap=default/my-config-file' --dry-run=client -o yaml > pod-with-config.yaml
```

### 4. 보안 고려사항
- Secret은 base64 인코딩만 제공 (암호화 아님)
- 외부에서 Secret 내용 접근 금지
- RBAC로 Secret 접근 제어 가능

### 5. 실습 정리
```bash
kubectl delete -f configmap.yaml -f secret.yaml
kubectl delete pods --all
```

## 실습 팁
- ConfigMap은 업데이트 가능하지만, Pod은 재시작해야 반영
- Secret을 연결된 Pod들은 재시작 필요
- 개발/운영 환경별 ConfigMap 분리하여 관리

## 참고자료
- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

## 실습 완료 체크리스트
- [ ] ConfigMap 생성 및 조회
- [ ] Secret 생성 및 안전한 저장 확인
- [ ] Pod에서 환경 변수 주입 테스트
- [ ] 볼륨 마운트로 파일 설정 사용
- [ ] 보안 측면 이해 및 올바른 사용 습득
