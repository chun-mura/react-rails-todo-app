# Todo App インフラ構成図

## 全体構成図

```mermaid
graph TB
    %% ユーザー
    User[ユーザー] --> CF[CloudFront<br/>CDN + SSL終端]

    %% CloudFront
    CF --> WAF[WAF Web ACL<br/>セキュリティ保護]
    WAF --> ALB[Application Load Balancer<br/>ロードバランシング]

    %% ALB ターゲット
    ALB --> ECS_FE[ECS Frontend<br/>React App]
    ALB --> ECS_BE[ECS Backend<br/>Rails API]

    %% データベース層
    ECS_BE --> RDS_Proxy[RDS Proxy<br/>コネクションプール]
    RDS_Proxy --> Aurora[Aurora PostgreSQL<br/>クラスター]

    %% ストレージ
    ECS_FE --> ECR_FE[ECR Frontend<br/>Docker Images]
    ECS_BE --> ECR_BE[ECR Backend<br/>Docker Images]

    %% ネットワーク
    subgraph "VPC"
        subgraph "Public Subnets"
            ALB
        end

        subgraph "Private Subnets"
            ECS_FE
            ECS_BE
            RDS_Proxy
        end

        subgraph "Database Subnets"
            Aurora
        end
    end

    %% セキュリティ
    Secrets[Secrets Manager<br/>認証情報] --> RDS_Proxy
    Secrets --> ECS_BE

    %% 監視
    CloudWatch[CloudWatch<br/>ログ・メトリクス] --> ECS_FE
    CloudWatch --> ECS_BE
    CloudWatch --> Aurora

    %% DNS
    Route53[Route 53<br/>DNS管理] --> CF

    %% 証明書
    ACM[ACM<br/>SSL証明書] --> CF
    ACM --> ALB

    %% スタイル
    classDef userClass fill:#e1f5fe
    classDef cdnClass fill:#f3e5f5
    classDef securityClass fill:#ffebee
    classDef computeClass fill:#e8f5e8
    classDef storageClass fill:#fff3e0
    classDef networkClass fill:#f1f8e9
    classDef monitoringClass fill:#e0f2f1

    class User userClass
    class CF,ALB cdnClass
    class WAF,Secrets,ACM securityClass
    class ECS_FE,ECS_BE,RDS_Proxy,Aurora computeClass
    class ECR_FE,ECR_BE storageClass
    class Route53 networkClass
    class CloudWatch monitoringClass
```

## ネットワーク構成図

```mermaid
graph TB
    subgraph "Internet"
        User[ユーザー]
    end

    subgraph "AWS Cloud"
        subgraph "VPC (10.0.0.0/16)"
            subgraph "Public Subnets"
                ALB[ALB<br/>10.0.1.0/24<br/>10.0.2.0/24]
            end

            subgraph "Private Subnets"
                ECS_FE[ECS Frontend<br/>10.0.3.0/24<br/>10.0.4.0/24]
                ECS_BE[ECS Backend<br/>10.0.5.0/24<br/>10.0.6.0/24]
                RDS_Proxy[RDS Proxy<br/>10.0.7.0/24<br/>10.0.8.0/24]
            end

            subgraph "Database Subnets"
                Aurora[Aurora PostgreSQL<br/>10.0.9.0/24<br/>10.0.10.0/24]
            end
        end

        %% 外部サービス
        CF[CloudFront]
        WAF[WAF]
        Secrets[Secrets Manager]
        ECR[ECR]
        Route53[Route 53]
    end

    %% 接続
    User --> CF
    CF --> WAF
    WAF --> ALB
    ALB --> ECS_FE
    ALB --> ECS_BE
    ECS_BE --> RDS_Proxy
    RDS_Proxy --> Aurora
    ECS_FE --> ECR
    ECS_BE --> ECR
    ECS_BE --> Secrets
    RDS_Proxy --> Secrets
    CF --> Route53

    %% スタイル
    classDef internetClass fill:#e3f2fd
    classDef vpcClass fill:#f1f8e9
    classDef publicClass fill:#fff3e0
    classDef privateClass fill:#e8f5e8
    classDef dbClass fill:#fce4ec
    classDef serviceClass fill:#f3e5f5

    class User internetClass
    class ALB publicClass
    class ECS_FE,ECS_BE,RDS_Proxy privateClass
    class Aurora dbClass
    class CF,WAF,Secrets,ECR,Route53 serviceClass
```

## セキュリティ構成図

```mermaid
graph TB
    %% セキュリティレイヤー
    subgraph "セキュリティレイヤー"
        WAF[WAF Web ACL<br/>AWS Managed Rules<br/>レート制限<br/>地理的制限]

        subgraph "ネットワークセキュリティ"
            SG_ALB[Security Group - ALB<br/>80/tcp HTTP<br/>443/tcp HTTPS]
            SG_ECS[Security Group - ECS<br/>80/tcp Frontend<br/>3001/tcp Backend]
            SG_RDS[Security Group - RDS<br/>5432/tcp PostgreSQL]
        end

        subgraph "認証・認可"
            IAM_Role[IAM Role<br/>ECS Task Role<br/>RDS Proxy Role]
            Secrets[Secrets Manager<br/>データベースパスワード<br/>JWT Secret Key<br/>Rails Master Key]
        end

        subgraph "暗号化"
            ACM[ACM<br/>SSL/TLS証明書<br/>ドメイン検証]
            KMS[KMS<br/>データ暗号化<br/>キー管理]
        end
    end

    %% 接続
    WAF --> SG_ALB
    SG_ALB --> SG_ECS
    SG_ECS --> SG_RDS
    IAM_Role --> Secrets
    IAM_Role --> KMS
    ACM --> WAF

    %% スタイル
    classDef securityClass fill:#ffebee
    classDef networkClass fill:#e8f5e8
    classDef authClass fill:#fff3e0
    classDef cryptoClass fill:#f3e5f5

    class WAF securityClass
    class SG_ALB,SG_ECS,SG_RDS networkClass
    class IAM_Role,Secrets authClass
    class ACM,KMS cryptoClass
```

## データフロー図

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant CF as CloudFront
    participant WAF as WAF
    participant ALB as ALB
    participant FE as Frontend (ECS)
    participant BE as Backend (ECS)
    participant RP as RDS Proxy
    participant DB as Aurora DB
    participant SM as Secrets Manager

    %% 静的コンテンツ要求
    U->>CF: GET / (静的ファイル)
    CF->>WAF: リクエスト通過
    WAF->>ALB: セキュリティチェック
    ALB->>FE: フォワード
    FE->>CF: レスポンス
    CF->>U: キャッシュ済みコンテンツ

    %% API要求
    U->>CF: POST /api/todos
    CF->>WAF: リクエスト通過
    WAF->>ALB: セキュリティチェック
    ALB->>BE: API要求
    BE->>SM: 認証情報取得
    SM->>BE: 認証情報
    BE->>RP: データベース接続
    RP->>DB: SQL実行
    DB->>RP: 結果
    RP->>BE: データ
    BE->>ALB: APIレスポンス
    ALB->>WAF: レスポンス
    WAF->>CF: レスポンス
    CF->>U: 結果
```

## コンポーネント詳細

### フロントエンド (React)
- **コンテナ**: ECS Fargate
- **ポート**: 80
- **ヘルスチェック**: `/`
- **キャッシュ**: 静的ファイル（JS/CSS/画像）は長期キャッシュ

### バックエンド (Rails API)
- **コンテナ**: ECS Fargate
- **ポート**: 3001
- **ヘルスチェック**: `/health`
- **キャッシュ**: APIはキャッシュなし

### データベース (Aurora PostgreSQL)
- **エンジン**: Aurora PostgreSQL 15.10
- **インスタンス**: db.t4g.medium × 2
- **接続**: RDS Proxy経由
- **バックアップ**: 7日間保持

### セキュリティ
- **WAF**: AWS Managed Rules + レート制限
- **証明書**: ACM (us-east-1 for CloudFront, ap-northeast-1 for ALB)
- **暗号化**: 転送時・保存時両方で暗号化
- **IAM**: 最小権限の原則

### 監視・ログ
- **CloudWatch**: メトリクス・ログ収集
- **ALB**: アクセスログ
- **ECS**: タスクログ
- **RDS**: パフォーマンスインサイト
