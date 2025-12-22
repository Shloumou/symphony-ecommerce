# Architecture Diagrams - E-Commerce Platform

## 1. Technical Architecture (For Developers)

```mermaid
graph TB
    subgraph "Client Layer"
        Browser[Web Browser]
        Mobile[Mobile Device]
    end

    subgraph "Security Layer"
        SSL[SSL/TLS<br/>Let's Encrypt]
        Firewall[Firewall Rules<br/>Port 443/80]
    end

    subgraph "Web Server"
        NGINX[Nginx<br/>HTTP/2, HSTS]
    end

    subgraph "Kubernetes Cluster (Minikube)"
        subgraph "Namespace: ecommerce"
            subgraph "App Pod"
                PHP[PHP 8.2 + Apache<br/>Symfony 5.4]
                QR[2FA QR Code<br/>endroid/qr-code]
                Composer[Composer Dependencies]
            end
            
            subgraph "Database Pod"
                MySQL[(MySQL 8.0<br/>Database)]
            end
            
            subgraph "Admin Pod"
                PHPMyAdmin[PHPMyAdmin<br/>Database Admin]
            end
            
            K8sSecrets[Kubernetes Secrets<br/>mysql-secrets]
        end
    end

    subgraph "Docker Infrastructure"
        DockerImage[Docker Image<br/>ecommerce_web_site_with_sym:latest]
        Dockerfile[Dockerfile<br/>Multi-stage Build]
    end

    subgraph "Storage"
        PVC[Persistent Volume<br/>MySQL Data]
        Uploads[Public Uploads<br/>/public/uploads]
    end

    subgraph "DNS"
        DuckDNS[DuckDNS<br/>salem-ecommerce.duckdns.org<br/>Auto-update every 5min]
    end

    subgraph "AWS Production (Optional)"
        EC2[EC2 t3.medium<br/>Docker Host]
        RDS[RDS MySQL]
        S3[S3 Backup Storage]
        CloudFront[CloudFront CDN]
        Route53[Route 53 DNS]
    end

    Browser --> SSL
    Mobile --> SSL
    SSL --> Firewall
    Firewall --> NGINX
    NGINX --> PHP
    
    PHP --> MySQL
    PHP --> QR
    PHP --> Uploads
    PHPMyAdmin --> MySQL
    
    MySQL --> PVC
    K8sSecrets -.->|Environment Variables| PHP
    K8sSecrets -.->|Credentials| MySQL
    
    Dockerfile --> DockerImage
    DockerImage -.->|minikube image load| PHP
    Composer -.->|Dependencies| PHP
    
    DuckDNS -.->|IP Resolution| SSL
    
    %% AWS Optional
    NGINX -.->|Production Alternative| EC2
    EC2 --> RDS
    EC2 --> S3
    CloudFront -.->|CDN| EC2
    Route53 -.->|DNS| CloudFront

    style PHP fill:#ff9999
    style MySQL fill:#4da6ff
    style NGINX fill:#99ff99
    style QR fill:#ffcc99
    style DockerImage fill:#cc99ff
```

### Technical Components:

1. **Frontend Layer**: Web browsers and mobile devices
2. **Security**: SSL/TLS (Let's Encrypt), Firewall rules (ports 80/443)
3. **Web Server**: Nginx with HTTP/2, HSTS headers
4. **Application**: PHP 8.2 + Symfony 5.4 in Docker container
5. **Database**: MySQL 8.0 with persistent storage
6. **Orchestration**: Kubernetes (Minikube) with 3 pods
7. **Authentication**: 2FA with QR code generation (TOTP)
8. **DNS**: DuckDNS with automatic IP updates
9. **Production**: AWS CloudFormation template available (EC2, RDS, S3, CloudFront)

---

## 2. Functional Architecture (For Clients/Business)

```mermaid
graph TB
    subgraph "Users"
        Customer[Customer<br/>👤 Public User]
        Admin[Administrator<br/>👨‍💼 Admin User]
    end

    subgraph "Public Features"
        Home[🏠 Homepage<br/>Product Catalog]
        ProductView[📦 Product Details<br/>Images, Price, Description]
        Cart[🛒 Shopping Cart<br/>Add/Remove Items]
        Search[🔍 Search Products<br/>By Name/Category]
    end

    subgraph "Authentication & Security"
        Login[🔐 Login System<br/>Username + Password]
        TwoFA[📱 Two-Factor Auth<br/>Google Authenticator]
        Register[📝 Registration<br/>Create Account]
        PasswordPolicy[🔒 Password Policy<br/>Min 8 chars, complexity]
    end

    subgraph "Order Management"
        Checkout[💳 Checkout Process<br/>Order Summary]
        OrderHistory[📋 Order History<br/>Track My Orders]
        Payment[💰 Payment Processing<br/>Payment Gateway]
    end

    subgraph "Product Management (Admin)"
        AddProduct[➕ Add Product<br/>Name, Price, Stock]
        EditProduct[✏️ Edit Product<br/>Update Details]
        DeleteProduct[🗑️ Delete Product<br/>Remove from Catalog]
        ManageStock[📊 Stock Management<br/>Inventory Control]
    end

    subgraph "Category Management (Admin)"
        AddCategory[➕ Add Category<br/>Create New Category]
        EditCategory[✏️ Edit Category<br/>Modify Category]
        DeleteCategory[🗑️ Delete Category<br/>Remove Category]
    end

    subgraph "User Management (Admin)"
        ViewUsers[👥 View Users<br/>User List]
        ManageRoles[👑 Manage Roles<br/>Admin/Customer]
        UserActivity[📈 User Activity<br/>Login History]
    end

    subgraph "Reports & Analytics (Admin)"
        Sales[📊 Sales Reports<br/>Revenue Analytics]
        PopularProducts[⭐ Popular Products<br/>Best Sellers]
        Dashboard[📺 Admin Dashboard<br/>Overview]
    end

    subgraph "Data Storage"
        Database[(🗄️ Secure Database<br/>Encrypted Data)]
        Backups[💾 Automatic Backups<br/>Daily Snapshots]
    end

    %% Customer Flow
    Customer --> Home
    Customer --> Search
    Customer --> Register
    Home --> ProductView
    ProductView --> Cart
    Cart --> Login
    Login --> TwoFA
    TwoFA --> Checkout
    Checkout --> Payment
    Payment --> OrderHistory
    
    %% Admin Flow
    Admin --> Login
    Login --> TwoFA
    TwoFA --> Dashboard
    Dashboard --> AddProduct
    Dashboard --> EditProduct
    Dashboard --> DeleteProduct
    Dashboard --> ManageStock
    Dashboard --> AddCategory
    Dashboard --> EditCategory
    Dashboard --> ViewUsers
    Dashboard --> Sales
    Dashboard --> PopularProducts
    
    %% Data Flow
    AddProduct --> Database
    EditProduct --> Database
    Cart --> Database
    Payment --> Database
    Register --> Database
    Database --> Backups
    
    %% Security
    Login --> PasswordPolicy
    Register --> PasswordPolicy

    style Customer fill:#99ccff
    style Admin fill:#ff9999
    style TwoFA fill:#ffcc99
    style Database fill:#99ff99
    style Payment fill:#ffff99
    style Dashboard fill:#cc99ff
```

### Functional Modules:

#### **For Customers:**
1. **Product Browsing**: View products, search, filter by category
2. **Shopping**: Add to cart, view cart, proceed to checkout
3. **Account Management**: Register, login with 2FA, view order history
4. **Secure Payment**: Process orders with integrated payment gateway

#### **For Administrators:**
1. **Product Management**: Add, edit, delete products and manage stock
2. **Category Management**: Organize products into categories
3. **User Management**: View users, assign roles, monitor activity
4. **Reports**: Sales analytics, popular products, revenue tracking
5. **Dashboard**: Centralized overview of all operations

#### **Security Features:**
- 🔐 Two-Factor Authentication (2FA) with QR code
- 🔒 Strong password policy enforcement
- 🛡️ Firewall protection (ports 80/443)
- 🔐 SSL/TLS encryption for all communications
- 💾 Automatic daily backups

---

## 3. High Availability Architecture (With Load Balancer)

```mermaid
graph TB
    subgraph "Client Layer"
        Browser2[Web Browser]
        Mobile2[Mobile Device]
    end

    subgraph "Security Layer"
        SSL2[SSL/TLS<br/>Let's Encrypt]
        Firewall2[Firewall Rules<br/>Port 443/80]
    end

    subgraph "Web Server Layer"
        NGINX2[Nginx<br/>Reverse Proxy]
    end

    subgraph "Load Balancing Layer"
        LB[Load Balancer<br/>HAProxy / MetalLB<br/>Round Robin]
    end

    subgraph "Kubernetes Cluster 1 (Primary)"
        subgraph "Namespace: ecommerce-1"
            subgraph "App Pod 1A"
                PHP1A[PHP 8.2 + Apache<br/>Symfony 5.4]
                QR1A[2FA QR Code]
            end
            
            subgraph "App Pod 1B"
                PHP1B[PHP 8.2 + Apache<br/>Symfony 5.4]
                QR1B[2FA QR Code]
            end
            
            subgraph "Database Pod 1"
                MySQL1[(MySQL 8.0<br/>Primary)]
            end
            
            PVC1[Persistent Volume 1<br/>MySQL Data]
        end
    end

    subgraph "Kubernetes Cluster 2 (Secondary)"
        subgraph "Namespace: ecommerce-2"
            subgraph "App Pod 2A"
                PHP2A[PHP 8.2 + Apache<br/>Symfony 5.4]
                QR2A[2FA QR Code]
            end
            
            subgraph "App Pod 2B"
                PHP2B[PHP 8.2 + Apache<br/>Symfony 5.4]
                QR2B[2FA QR Code]
            end
            
            subgraph "Database Pod 2"
                MySQL2[(MySQL 8.0<br/>Replica)]
            end
            
            PVC2[Persistent Volume 2<br/>MySQL Data]
        end
    end

    subgraph "Shared Storage"
        NFS[NFS Server<br/>Shared Uploads]
        SharedPVC[Shared PVC<br/>/public/uploads]
    end

    subgraph "Database Replication"
        Replication[MySQL Replication<br/>Primary → Replica<br/>Async/Sync]
    end

    Browser2 --> SSL2
    Mobile2 --> SSL2
    SSL2 --> Firewall2
    Firewall2 --> NGINX2
    NGINX2 --> LB
    
    LB -->|50% Traffic| PHP1A
    LB -->|50% Traffic| PHP1B
    LB -.->|Failover| PHP2A
    LB -.->|Failover| PHP2B
    
    PHP1A --> MySQL1
    PHP1B --> MySQL1
    PHP2A --> MySQL2
    PHP2B --> MySQL2
    
    MySQL1 --> PVC1
    MySQL2 --> PVC2
    
    MySQL1 -->|Replication| Replication
    Replication -->|Sync Data| MySQL2
    
    PHP1A --> SharedPVC
    PHP1B --> SharedPVC
    PHP2A --> SharedPVC
    PHP2B --> SharedPVC
    
    SharedPVC --> NFS

    style LB fill:#ff6666
    style MySQL1 fill:#4da6ff
    style MySQL2 fill:#80bfff
    style PHP1A fill:#ff9999
    style PHP1B fill:#ff9999
    style PHP2A fill:#ffcccc
    style PHP2B fill:#ffcccc
    style NFS fill:#99ff99
    style Replication fill:#ffcc99
```

### High Availability Components:

1. **Load Balancer (HAProxy/MetalLB)**:
   - Distributes traffic across multiple pods
   - Round-robin or least-connections algorithm
   - Health checks and automatic failover
   - Supports session persistence (sticky sessions)

2. **Multiple App Pods**:
   - Cluster 1: 2 pods (PHP1A, PHP1B) - Primary cluster
   - Cluster 2: 2 pods (PHP2A, PHP2B) - Failover cluster
   - Horizontal scaling capability
   - Zero-downtime deployments

3. **Database Replication**:
   - Primary MySQL (Cluster 1) - Read/Write
   - Replica MySQL (Cluster 2) - Read-only or failover
   - Asynchronous or synchronous replication
   - Automatic failover with promotion

4. **Shared Storage (NFS)**:
   - Centralized file storage for uploads
   - All pods access same files
   - Prevents data inconsistency
   - Can be replaced with S3/MinIO

5. **Traffic Distribution**:
   - 50% traffic to Cluster 1 (primary)
   - 50% standby on Cluster 2 (failover)
   - Automatic failover if cluster fails
   - Geographic distribution possible

### Load Balancer Configuration:

```yaml
# MetalLB LoadBalancer Service Example
apiVersion: v1
kind: Service
metadata:
  name: ecommerce-lb
  namespace: ecommerce
spec:
  type: LoadBalancer
  selector:
    app: ecommerce-app
  ports:
  - port: 80
    targetPort: 80
    name: http
  - port: 443
    targetPort: 443
    name: https
  sessionAffinity: ClientIP  # Sticky sessions for 2FA
```

### Benefits:
- ✅ **High Availability**: No single point of failure
- ✅ **Scalability**: Easily add more pods
- ✅ **Load Distribution**: Better performance
- ✅ **Disaster Recovery**: Automatic failover
- ✅ **Zero Downtime**: Rolling updates

---

## 4. Deployment Flow (Technical)

```mermaid
graph LR
    subgraph "Development"
        Code[Source Code<br/>Symfony + PHP]
        Dockerfile[Dockerfile]
    end

    subgraph "Build Process"
        Build[Docker Build<br/>~10 minutes]
        Image[Docker Image<br/>with QR Code libs]
    end

    subgraph "Deployment"
        Load[minikube image load]
        K8sDeploy[kubectl apply]
        Pods[Running Pods]
    end

    subgraph "Persistence"
        Script[rebuild-and-deploy.sh]
        Systemd[Systemd Service<br/>Auto-start]
    end

    Code --> Dockerfile
    Dockerfile --> Build
    Build --> Image
    Image --> Load
    Load --> K8sDeploy
    K8sDeploy --> Pods
    
    Script --> Build
    Systemd --> Script

    style Image fill:#cc99ff
    style Pods fill:#99ff99
    style Script fill:#ffcc99
```

---

## 5. Data Flow (Business Process)

```mermaid
sequenceDiagram
    participant C as Customer
    participant W as Website
    participant A as Authentication
    participant D as Database
    participant P as Payment Gateway
    participant E as Email Service

    C->>W: Browse Products
    W->>D: Fetch Product List
    D-->>W: Return Products
    W-->>C: Display Products
    
    C->>W: Add to Cart
    W->>D: Save Cart Session
    
    C->>W: Proceed to Checkout
    W->>A: Request Login
    C->>A: Enter Credentials
    A->>D: Verify User
    D-->>A: User Valid
    A->>C: Show 2FA QR Code
    C->>A: Scan QR Code & Enter OTP
    A-->>W: Authentication Success
    
    W->>C: Show Order Summary
    C->>W: Confirm Order
    W->>P: Process Payment
    P-->>W: Payment Success
    W->>D: Save Order
    D-->>W: Order ID
    W->>E: Send Confirmation Email
    E-->>C: Email Received
    W-->>C: Order Confirmation Page
```

---

## How to Use These Diagrams:

### For Developers:
- Use **Diagram 1 (Technical Architecture)** to understand the infrastructure
- Use **Diagram 3 (High Availability Architecture)** for production setup
- Reference **Diagram 4 (Deployment Flow)** for CI/CD processes
- Study the component relationships and data flow

### For Clients/Business:
- Show **Diagram 2 (Functional Architecture)** to explain features
- Use **Diagram 5 (Data Flow)** to demonstrate the purchase process
- Highlight security features (2FA, SSL, backups)
- Use **Diagram 3 (High Availability)** to explain reliability and uptime

### Viewing These Diagrams:
1. **GitHub/GitLab**: Automatically renders Mermaid diagrams
2. **VS Code**: Install "Markdown Preview Mermaid Support" extension
3. **Online**: Copy code to https://mermaid.live/
4. **Documentation**: Use in Confluence, Notion, or technical docs

---

## Quick Reference:

| Diagram | Audience | Purpose |
|---------|----------|---------|
| Technical Architecture | Developers, DevOps | Infrastructure overview, component relationships |
| Functional Architecture | Product Owners, Clients | Business features, user workflows |
| High Availability Architecture | Architects, DevOps | Production setup with load balancing and failover |
| Deployment Flow | DevOps, Developers | Build and deployment process |
| Data Flow | Business Analysts, QA | Transaction process, data movement |

---

**Created**: December 5, 2025  
**Project**: E-Commerce Platform with Symfony 5.4  
**Environment**: Kubernetes (Minikube) / AWS CloudFormation Ready
