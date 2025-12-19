#!/bin/bash

set +e  # 오류가 발생해도 계속 실행

echo "=== 7차시: 설정 관리와 보안 실습 스크립트 ==="
echo "슬라이드 내용을 기반으로 단계별 실행합니다."
echo
echo "학습 목표:"
echo "  - ConfigMap을 통한 애플리케이션 설정 관리"
echo "  - Secret을 활용한 민감 정보 보호"
echo "  - Kubernetes에서 안전한 설정 관리 방법"
echo

# 클러스터 연결 상태 체크
echo "🔍 Kubernetes 클러스터 연결 확인 중..."
if command -v kubectl &> /dev/null; then
    echo "✅ kubectl 설치 확인됨"

    if kubectl cluster-info &>/dev/null; then
        CLUSTER_UP=1
        echo "✅ 클러스터 연결 상태: 정상"
        CLUSTER_INFO=$(kubectl cluster-info | head -1)
        echo "   클러스터 정보: $CLUSTER_INFO"
    else
        CLUSTER_UP=0
        echo "⚠️ 클러스터 연결 상태: 미연결"
        echo "   (Kubernetes 명령어는 시뮬레이션으로 표시됩니다)"
        echo "   클러스터 설정 방법: minikube start 또는 k3s 설치"
    fi
else
    CLUSTER_UP=0
    echo "⚠️ kubectl이 설치되어 있지 않습니다."
    echo "   설치 방법: https://kubernetes.io/docs/tasks/tools/"
fi
echo

echo "Step 1: ConfigMap 이해 및 생성"
echo "슬라이드 1-3 참고: 설정 저장소"
echo "----------------------------------------"
echo "📄 ConfigMap YAML 내용 확인:"
cat configmap.yaml | head -15
echo "..."
echo

if [ $CLUSTER_UP -eq 1 ]; then
    echo "ConfigMap 생성 중..."
    kubectl apply -f configmap.yaml --validate=false 2>/dev/null

    echo "ConfigMap 목록:"
    kubectl get configmaps --no-headers 2>/dev/null || echo "   ConfigMap 조회 실패"

    echo "ConfigMap 상세 정보:"
    kubectl describe configmap app-config 2>/dev/null | head -10 || echo "   상세 정보 조회 실패"

    echo "ConfigMap 데이터 확인:"
    kubectl get configmap app-config -o jsonpath='{.data}' 2>/dev/null || echo "   데이터 조회 실패"
else
    echo "시뮬레이션: kubectl apply -f configmap.yaml"
    echo "   예상 결과: configmap/app-config created"
    echo "   예상 결과: configmap/app-config-files created"
    echo
    echo "시뮬레이션: kubectl get configmaps"
    echo "   NAME               DATA   AGE"
    echo "   app-config         6      1s"
    echo "   app-config-files   1      1s"
fi
echo

echo "Step 2: Secret 이해 및 생성"
echo "슬라이드 4 참고: 민감 정보 관리"
echo "----------------------------------------"
echo "🔐 Secret YAML 내용 확인 (base64 인코딩됨):"
cat secret.yaml | head -14
echo "..."
echo

# Base64 디코딩 예시
echo "💡 Base64 디코딩 예시:"
echo "   username: $(echo 'YWRtaW4=' | base64 --decode) (YWRtaW4= 디코딩)"
echo "   password: $(echo 'bXlwYXNzd29yZA==' | base64 --decode) (bXlwYXNzd29yZA== 디코딩)"
echo

if [ $CLUSTER_UP -eq 1 ]; then
    echo "Secret 생성 중..."
    kubectl apply -f secret.yaml --validate=false 2>/dev/null

    echo "Secret 목록:"
    kubectl get secrets --no-headers 2>/dev/null || echo "   Secret 조회 실패"

    echo "Secret 상세 정보 (데이터는 숨김):"
    kubectl describe secret app-secret 2>/dev/null | grep -v "token:" | head -10 || echo "   상세 정보 조회 실패"
else
    echo "시뮬레이션: kubectl apply -f secret.yaml"
    echo "   예상 결과: secret/app-secret created"
    echo "   예상 결과: secret/tls-secret created"
    echo
    echo "시뮬레이션: kubectl get secrets"
    echo "   NAME         TYPE                  DATA   AGE"
    echo "   app-secret   Opaque                4      1s"
    echo "   tls-secret   kubernetes.io/tls     2      1s"
fi
echo

echo "Step 3: ConfigMap을 환경 변수로 주입"
echo "슬라이드 5 참고: 환경 설정 적용"
echo "----------------------------------------"
if [ $CLUSTER_UP -eq 1 ]; then
    echo "ConfigMap을 환경 변수로 사용하는 Pod 생성..."

    # Pod YAML 생성
    cat > test-configmap-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: configmap-test-pod
spec:
  containers:
  - name: test-container
    image: busybox
    command: ['sh', '-c', 'echo "환경 변수 확인:"; echo "ENVIRONMENT=\$ENVIRONMENT"; echo "LOG_LEVEL=\$LOG_LEVEL"; echo "DATABASE_HOST=\$DATABASE_HOST"; sleep 10']
    envFrom:
    - configMapRef:
        name: app-config
  restartPolicy: Never
EOF

    kubectl apply -f test-configmap-pod.yaml 2>/dev/null
    sleep 5
    echo "Pod 실행 결과:"
    kubectl logs configmap-test-pod 2>/dev/null || echo "   Pod 로그 조회 실패"
    kubectl delete pod configmap-test-pod --ignore-not-found=true 2>/dev/null
    rm -f test-configmap-pod.yaml
else
    echo "시뮬레이션: ConfigMap 환경 변수 주입 테스트"
    echo "   Pod 생성: configmap-test-pod"
    echo "   예상 출력:"
    echo "   환경 변수 확인:"
    echo "   ENVIRONMENT=production"
    echo "   LOG_LEVEL=info"
    echo "   DATABASE_HOST=database-service"
fi
echo

echo "Step 4: Secret을 환경 변수로 주입"
echo "슬라이드 6 참고: 비밀 정보 적용"
echo "----------------------------------------"
if [ $CLUSTER_UP -eq 1 ]; then
    echo "Secret을 환경 변수로 사용하는 Pod 생성..."

    # Pod YAML 생성
    cat > test-secret-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: secret-test-pod
spec:
  containers:
  - name: test-container
    image: busybox
    command: ['sh', '-c', 'echo "Secret 환경 변수 확인:"; echo "USERNAME=\$username (실제 값은 숨김)"; echo "API_KEY 존재: \$([ -z \$api_key ] && echo NO || echo YES)"; sleep 10']
    envFrom:
    - secretRef:
        name: app-secret
  restartPolicy: Never
EOF

    kubectl apply -f test-secret-pod.yaml 2>/dev/null
    sleep 5
    echo "Pod 실행 결과:"
    kubectl logs secret-test-pod 2>/dev/null || echo "   Pod 로그 조회 실패"
    kubectl delete pod secret-test-pod --ignore-not-found=true 2>/dev/null
    rm -f test-secret-pod.yaml
else
    echo "시뮬레이션: Secret 환경 변수 주입 테스트"
    echo "   Pod 생성: secret-test-pod"
    echo "   예상 출력:"
    echo "   Secret 환경 변수 확인:"
    echo "   USERNAME=admin (실제 값은 숨김)"
    echo "   API_KEY 존재: YES"
fi
echo

echo "Step 5: 볼륨 마운트로 설정 파일 사용"
echo "슬라이드 7 참고: 파일 기반 설정"
echo "----------------------------------------"
if [ $CLUSTER_UP -eq 1 ]; then
    echo "ConfigMap을 볼륨으로 마운트하는 예시..."

    # ConfigMap 생성
    kubectl create configmap file-config --from-literal=app.properties="version=1.0\nport=8080\nhost=0.0.0.0" 2>/dev/null

    # Pod YAML 생성
    cat > volume-mount-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: volume-test-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: file-config
EOF

    kubectl apply -f volume-mount-pod.yaml 2>/dev/null
    sleep 5

    echo "마운트된 설정 파일 확인:"
    kubectl exec volume-test-pod -- cat /etc/config/app.properties 2>/dev/null || echo "   파일 조회 실패"

    kubectl delete pod volume-test-pod --ignore-not-found=true 2>/dev/null
    kubectl delete configmap file-config --ignore-not-found=true 2>/dev/null
    rm -f volume-mount-pod.yaml
else
    echo "시뮬레이션: ConfigMap을 볼륨으로 마운트"
    echo "   ConfigMap 생성: file-config"
    echo "   Pod 생성: volume-test-pod"
    echo "   마운트 경로: /etc/config/"
    echo "   예상 파일 내용:"
    echo "   version=1.0"
    echo "   port=8080"
    echo "   host=0.0.0.0"
fi
echo

echo "Step 6: 새로운 테스트 Pod 파일들 확인"
echo "추가된 실습용 YAML 파일들"
echo "----------------------------------------"
echo "📄 새로 생성된 테스트 파일들:"
echo "   - test-configmap-pod.yaml: ConfigMap 환경 변수 주입 예제"
echo "   - test-secret-pod.yaml: Secret 환경 변수 주입 예제"
echo "   - test-volume-mount-pod.yaml: ConfigMap 볼륨 마운트 예제"
echo

if [ $CLUSTER_UP -eq 1 ]; then
    echo "테스트 Pod들 실행해보기..."

    # ConfigMap 테스트 Pod 실행
    if [ -f "test-configmap-pod.yaml" ]; then
        echo "ConfigMap 테스트 Pod 실행 중..."
        kubectl apply -f test-configmap-pod.yaml 2>/dev/null
        sleep 3
        kubectl logs configmap-test-pod 2>/dev/null || echo "   ConfigMap Pod 로그 조회 실패"
        kubectl delete -f test-configmap-pod.yaml --ignore-not-found=true 2>/dev/null
    fi

    # Secret 테스트 Pod 실행
    if [ -f "test-secret-pod.yaml" ]; then
        echo "Secret 테스트 Pod 실행 중..."
        kubectl apply -f test-secret-pod.yaml 2>/dev/null
        sleep 3
        kubectl logs secret-test-pod 2>/dev/null || echo "   Secret Pod 로그 조회 실패"
        kubectl delete -f test-secret-pod.yaml --ignore-not-found=true 2>/dev/null
    fi

    echo "볼륨 마운트 테스트는 별도 ConfigMap이 필요하므로 생략..."
else
    echo "시뮬레이션: 테스트 Pod들 실행"
    echo "   test-configmap-pod.yaml -> Environment Variables 출력"
    echo "   test-secret-pod.yaml -> Secret 환경 변수 확인"
    echo "   test-volume-mount-pod.yaml -> 볼륨 마운트 파일 확인"
fi
echo

echo "Step 7: 보안 고려사항"
echo "슬라이드 8 참고: Secret 보호"
echo "----------------------------------------"
echo "⚠️ 중요 보안 사항:"
echo "   1. Secret은 base64 인코딩만 제공 (암호화 아님)"
echo "   2. etcd에 암호화하여 저장하려면 추가 설정 필요"
echo "   3. RBAC으로 Secret 접근 제한 권장"
echo "   4. Git에 Secret을 커밋하지 말 것"
echo

if [ $CLUSTER_UP -eq 1 ]; then
    echo "Secret 데이터 확인 (base64 인코딩 상태):"
    kubectl get secret app-secret -o jsonpath='{.data.username}' 2>/dev/null && echo " <- base64 인코딩됨"

    echo "디코딩된 값 (실제 운영에서는 하지 말 것):"
    USERNAME=$(kubectl get secret app-secret -o jsonpath='{.data.username}' 2>/dev/null | base64 --decode)
    [ ! -z "$USERNAME" ] && echo "   username: $USERNAME"
else
    echo "시뮬레이션: Secret 보안 확인"
    echo "   base64 인코딩된 값: YWRtaW4="
    echo "   디코딩된 값: admin"
    echo "   ⚠️ 주의: base64는 암호화가 아닌 단순 인코딩!"
fi
echo

echo "Step 8: 정리 (Cleanup)"
echo "슬라이드 9 참고: 리소스 정리"
echo "----------------------------------------"
if [ $CLUSTER_UP -eq 1 ]; then
    echo "생성된 리소스 정리 중..."
    kubectl delete configmap app-config app-config-files --ignore-not-found=true 2>/dev/null
    kubectl delete secret app-secret tls-secret --ignore-not-found=true 2>/dev/null
    kubectl delete pod --all --ignore-not-found=true 2>/dev/null

    echo "남은 리소스 확인:"
    echo "ConfigMaps:"
    kubectl get configmaps --no-headers 2>/dev/null || echo "   없음"
    echo "Secrets:"
    kubectl get secrets --field-selector type!=kubernetes.io/service-account-token --no-headers 2>/dev/null || echo "   없음"
else
    echo "시뮬레이션: 리소스 정리"
    echo "   kubectl delete configmap app-config app-config-files"
    echo "   kubectl delete secret app-secret tls-secret"
    echo "   kubectl delete pod --all"
fi
echo

echo "=== 실습 완료 ==="
echo "설정 관리와 보안 실습 완료"
echo
echo "📋 학습 목표 달성 확인:"
echo "  ✅ ConfigMap 생성 및 조회"
echo "  ✅ Secret 생성 및 안전한 저장 이해"
echo "  ✅ Pod에서 환경 변수 주입 방법 학습"
echo "  ✅ 볼륨 마운트로 파일 설정 사용법 이해"
echo "  ✅ 보안 측면 이해 및 올바른 사용법 습득"
echo
echo "💡 핵심 포인트:"
echo "  - ConfigMap: 일반 설정 정보 저장 (평문)"
echo "  - Secret: 민감한 정보 저장 (base64 인코딩)"
echo "  - 환경별로 다른 ConfigMap/Secret 사용 가능"
echo "  - Git에는 절대 Secret 커밋 금지!"
echo
echo "🚀 다음 단계:"
echo "  - 8차시: HPA를 통한 자동 스케일링과 모니터링"