# Production Linux Server Automation & Observability

> **DevOps portfolio project:** Automated deployment of a Java/JSP
> application on Ubuntu with Nginx, Apache Tomcat, PostgreSQL, systemd,
> security hardening, monitoring, alerting, and operational automation.

[![Linux](https://img.shields.io/badge/Linux-Ubuntu-orange?logo=ubuntu)](https://ubuntu.com/)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange?logo=amazon-aws)](https://aws.amazon.com/ec2/)
[![Bash](https://img.shields.io/badge/Automation-Bash-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Nginx](https://img.shields.io/badge/Web_Server-Nginx-green?logo=nginx)](https://nginx.org/)
[![Tomcat](https://img.shields.io/badge/Application_Server-Tomcat-yellow?logo=apache)](https://tomcat.apache.org/)
[![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-orange?logo=prometheus)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Dashboards-Grafana-orange?logo=grafana)](https://grafana.com/)

------------------------------------------------------------------------

## 1. Project Overview

This project automates the setup, deployment, and observability of a
Java/JSP web application on an Ubuntu server.

The objective is to demonstrate practical DevOps skills across the
complete application lifecycle:

-   Provisioning an AWS EC2 server
-   Configuring an Ubuntu Linux environment
-   Installing and configuring Java, Tomcat, Nginx, and PostgreSQL
-   Deploying a JSP application as a WAR file
-   Managing the application with `systemd`
-   Applying Linux security and access controls
-   Collecting system and application metrics
-   Building dashboards and alerts
-   Automating backups, log management, and health checks
-   Documenting repeatable operational procedures

The project is designed to be developed locally in a virtual machine
first and then deployed to AWS EC2.

> **Implementation status:** This repository is developed incrementally.
> Features marked as planned are not represented as completed until the
> corresponding scripts, configuration, tests, and documentation are
> added.

------------------------------------------------------------------------

## 2. Architecture

### 2.1 Application and Infrastructure Architecture

``` mermaid
flowchart TD
    User[Internet User] --> SG[AWS Security Group]
    SG --> Nginx[Nginx Reverse Proxy]
    Nginx --> Tomcat[Apache Tomcat]
    Tomcat --> JSP[JSP / Java Web Application]
    JSP --> PostgreSQL[(PostgreSQL Database)]

    Admin[Administrator] --> SSH[Hardened SSH]
    SSH --> Ubuntu[Ubuntu EC2 Server]

    Ubuntu --> Systemd[systemd Service]
    Systemd --> Tomcat

    Ubuntu --> NodeExporter[Node Exporter]
    Tomcat --> AppMetrics[Application Metrics]
    NodeExporter --> Prometheus[Prometheus]
    AppMetrics --> Prometheus
    Prometheus --> Grafana[Grafana Dashboards]
    Prometheus --> Alertmanager[Alertmanager]
```

### 2.2 Request Flow

``` text
Client Browser
      |
      | HTTP / HTTPS
      v
Nginx Reverse Proxy
      |
      | Proxy to internal Tomcat port
      v
Apache Tomcat
      |
      | JSP rendering / Java application logic
      v
JSP Application
      |
      | JDBC
      v
PostgreSQL
```

### 2.3 Observability Flow

``` text
Linux Host
   |
   +--> Node Exporter --------+
                              |
JSP/Tomcat Application -------+--> Prometheus --> Grafana
                              |
Application Health Checks ----+
                              |
                              +--> Alertmanager --> Notification Channel
```

Prometheus follows a pull-based monitoring model:

1.  Prometheus discovers configured monitoring targets.
2.  Prometheus periodically scrapes metrics over HTTP.
3.  Metrics are stored in the Prometheus time-series database.
4.  Grafana queries Prometheus to display dashboards.
5.  Alerting rules are evaluated by Prometheus.
6.  Alertmanager groups, routes, and sends notifications.

------------------------------------------------------------------------

## 3. Technology Stack

Area                 Technology                            Purpose
  -------------------- ------------------------------------- ------------------------------------
Cloud                AWS EC2                               Compute infrastructure
Operating System     Ubuntu Linux                          Application host
Automation           Bash                                  Repeatable server operations
Cloud CLI            AWS CLI                               EC2 and AWS resource automation
Web Server           Nginx                                 Reverse proxy and HTTP entry point
Application Server   Apache Tomcat                         JSP/Java application runtime
Application          Java + JSP                            Business application
Database             PostgreSQL                            Persistent application data
Service Manager      systemd                               Application lifecycle management
Monitoring           Prometheus                            Metrics collection and storage
Host Metrics         Node Exporter                         Linux system metrics
Visualization        Grafana                               Monitoring dashboards
Alerting             Alertmanager                          Alert routing and notifications
Security             UFW, SSH hardening, least privilege   Host protection
Version Control      Git and GitHub                        Source control and documentation

------------------------------------------------------------------------

## 4. Repository Structure

``` text
Linux Administration Project/
├── README.md
├── scripts/
│   ├── create-key-pair.sh
│   ├── create-ec2.sh
│   ├── setup-server.sh
│   ├── setup-security.sh
│   ├── setup-tomcat.sh
│   ├── setup-postgresql.sh
│   ├── deploy-jsp-app.sh
│   ├── setup-nginx.sh
│   ├── setup-monitoring.sh
│   ├── backup-database.sh
│   ├── health-check.sh
│   └── cleanup.sh
├── config/
│   ├── systemd/
│   │   └── jsp-app.service
│   ├── nginx/
│   │   └── jsp-app.conf
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── alertmanager/
│       └── alertmanager.yml
├── monitoring/
│   ├── rules/
│   │   └── infrastructure-alerts.yml
│   └── dashboards/
│       └── application-dashboard.json
├── database/
│   ├── schema/
│   └── backup/
├── docs/
│   ├── architecture.md
│   ├── deployment-guide.md
│   ├── troubleshooting.md
│   └── security-notes.md
└── .gitignore
```

The exact structure may evolve as the project is implemented.

------------------------------------------------------------------------

## 5. Automation Workflow

### Phase 1: Provision AWS Infrastructure

The provisioning workflow is designed to be repeatable and
parameterized.

``` text
Validate AWS CLI and credentials
          |
          v
Validate region, subnet, and security group
          |
          v
Create or validate EC2 key pair
          |
          v
Save private .pem file locally with secure permissions
          |
          v
Discover Ubuntu AMI
          |
          v
Launch EC2 instance
          |
          v
Wait for instance to become available
          |
          v
Display instance ID, private IP, public IP, and SSH command
```

The EC2 provisioning script should:

-   Avoid hardcoded credentials
-   Accept configuration through arguments or environment variables
-   Validate required AWS resources before launching
-   Use tags for resource identification
-   Never commit private keys or secrets to Git
-   Fail safely when required resources are missing

### Phase 2: Configure the Ubuntu Server

The server setup script will prepare the base operating system.

Planned tasks:

-   Update package metadata and security packages
-   Install required utilities
-   Create dedicated application and deployment users
-   Configure directory ownership and permissions
-   Configure UFW rules
-   Apply SSH hardening
-   Configure time synchronization
-   Create application, log, backup, and deployment directories
-   Enable required services

Example directory layout on the server:

``` text
/opt/jsp-app/
├── releases/
├── current -> releases/<version>
├── config/
├── logs/
└── backups/
```

### Phase 3: Install and Configure Tomcat

The Tomcat setup workflow will:

1.  Install the required Java runtime.
2.  Create a dedicated `tomcat` user.
3.  Install Tomcat in a controlled directory.
4.  Set appropriate ownership and permissions.
5.  Configure environment variables.
6.  Create a `systemd` service.
7.  Configure Tomcat to listen on an internal port.
8.  Verify that Tomcat is healthy.

Tomcat should not be exposed directly to the public internet when Nginx
is used as the reverse proxy.

### Phase 4: Deploy the JSP Application

The deployment script will:

1.  Validate the WAR file.
2.  Upload or copy the application artifact.
3.  Create a versioned release directory.
4.  Stop or gracefully reload the application when required.
5.  Deploy the WAR file.
6.  Apply application configuration securely.
7.  Start the service.
8.  Run a health check.
9.  Print deployment status and useful logs.

Example deployment flow:

``` text
Build WAR artifact
       |
       v
Transfer artifact to server
       |
       v
Create versioned release
       |
       v
Update application configuration
       |
       v
Restart or reload Tomcat
       |
       v
Run HTTP health check
       |
       v
Record deployment result
```

### Phase 5: Configure Nginx

Nginx will act as the public-facing reverse proxy.

Responsibilities:

-   Listen on HTTP and HTTPS
-   Forward requests to Tomcat
-   Hide the internal Tomcat port
-   Configure access and error logs
-   Set proxy headers
-   Support request timeouts
-   Provide a controlled entry point for TLS configuration

Example Nginx flow:

``` text
Client --> Nginx:80/443 --> Tomcat:8080
```

Before enabling a configuration:

``` bash
sudo nginx -t
```

After validation:

``` bash
sudo systemctl reload nginx
```

------------------------------------------------------------------------

## 6. Monitoring and Observability

Observability is included to show how the deployed system can be
monitored after installation.

### 6.1 Prometheus

Prometheus will collect metrics from configured targets such as:

-   Linux host metrics through Node Exporter
-   Application metrics where an exporter or instrumentation endpoint is
    available
-   HTTP health-check endpoints
-   Additional service exporters as the project expands

Typical Prometheus configuration concepts:

-   `scrape_configs`
-   Static target discovery
-   Scrape intervals
-   Labels
-   Recording rules
-   Alerting rules

### 6.2 Node Exporter

Node Exporter provides host-level metrics such as:

-   CPU utilization
-   Memory usage
-   Disk space
-   Disk I/O
-   Network traffic
-   System load
-   Filesystem availability

### 6.3 Grafana

Grafana dashboards will be used to visualize:

-   CPU and memory utilization
-   Disk usage and filesystem capacity
-   Network traffic
-   Application availability
-   Request-related metrics where available
-   Service restart events
-   Alert status

### 6.4 Alertmanager

Alertmanager will be configured to handle alerts generated by
Prometheus.

Possible alerts include:

-   Host is down
-   Disk usage exceeds a threshold
-   High memory usage
-   High CPU usage for a sustained period
-   Application health check failure
-   Tomcat service unavailable
-   PostgreSQL service unavailable
-   Excessive restart activity

> Alert thresholds should be tuned using observed baseline behavior
> instead of choosing arbitrary values without validation.

------------------------------------------------------------------------

## 7. Security Design

Security is treated as part of the deployment process rather than a
separate final step.

### Planned controls

-   Use IAM users or roles with minimum required permissions
-   Avoid hardcoding AWS access keys
-   Store private key files outside source control
-   Apply `chmod 400` to SSH private keys
-   Disable direct application execution as `root`
-   Use dedicated Linux service accounts
-   Restrict inbound traffic using AWS Security Groups
-   Configure UFW on the Ubuntu host
-   Allow SSH only from trusted source IPs where practical
-   Expose only required public ports
-   Keep PostgreSQL private and restrict database access
-   Store secrets outside Git-tracked files
-   Validate Nginx and systemd configuration before activation
-   Maintain operating system and package updates

Example `.gitignore` entries:

``` gitignore
*.pem
.env
.env.*
!.env.example
.idea/
*.log
backups/
```

------------------------------------------------------------------------

## 8. Backup and Recovery

The project will include operational scripts for database and
configuration backups.

Planned backup targets:

-   PostgreSQL databases
-   Nginx configuration
-   Tomcat configuration
-   Application configuration
-   systemd unit files
-   Monitoring configuration

A backup process should define:

-   Backup location
-   Naming convention
-   Retention period
-   File permissions
-   Failure handling
-   Restore procedure
-   Verification process

A backup is not considered reliable until a restore test has been
performed.

------------------------------------------------------------------------

## 9. Logging and Troubleshooting

Important logs will be identified and documented.

### Common commands

Check service status:

``` bash
sudo systemctl status nginx
sudo systemctl status tomcat
sudo systemctl status postgresql
```

Follow service logs:

``` bash
sudo journalctl -u tomcat -f
sudo journalctl -u nginx -f
```

Check Nginx configuration:

``` bash
sudo nginx -t
```

Check listening ports:

``` bash
sudo ss -tulpn
```

Check disk and memory:

``` bash
df -h
free -h
uptime
```

Check running processes:

``` bash
ps aux
```

Check recent system errors:

``` bash
sudo journalctl -p err -b
```

Troubleshooting documentation will cover:

-   Application startup failures
-   WAR deployment errors
-   Java version mismatches
-   Tomcat permission problems
-   Nginx `502 Bad Gateway`
-   PostgreSQL connection failures
-   Port conflicts
-   Disk exhaustion
-   Failed systemd services
-   Missing environment variables

------------------------------------------------------------------------

## 10. Example systemd Service Design

The application should be managed as a service instead of being started
manually in a terminal.

Conceptual service responsibilities:

``` text
systemd
   |
   +--> Start application
   +--> Stop application
   +--> Restart on failure
   +--> Manage startup ordering
   +--> Provide centralized logs
   +--> Start application at boot
```

A production-oriented service should define:

-   A dedicated service user
-   Working directory
-   Environment configuration
-   Restart policy
-   Dependency ordering
-   Resource and permission boundaries
-   Appropriate stop and start behavior

The final unit file will be stored under:

``` text
/etc/systemd/system/
```

After changes:

``` bash
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl restart tomcat
```

------------------------------------------------------------------------

## 11. Validation and Testing

Each automation stage should include validation.

Area                 Validation
  -------------------- ----------------------------------------------
AWS authentication   `aws sts get-caller-identity`
EC2 provisioning     Instance reaches `running` state
SSH access           Login using the generated private key
Linux setup          Required packages and users exist
Tomcat               Service is active and HTTP endpoint responds
JSP application      Application page or health endpoint loads
PostgreSQL           Connection and query test succeeds
Nginx                `nginx -t` succeeds
Reverse proxy        Public request reaches Tomcat
Monitoring           Prometheus targets show `UP`
Dashboards           Grafana queries return data
Alerting             Test alert is generated and routed
Backups              Backup is created and restore is tested

The goal is to make the scripts idempotent where practical: running a
setup script again should not unnecessarily break an existing working
configuration.

------------------------------------------------------------------------

## 12. How to Run

### Prerequisites

Install or configure:

-   AWS CLI
-   An AWS account with appropriate permissions
-   Bash environment
-   Git
-   An existing JSP application or WAR artifact
-   A configured AWS region
-   An existing or provisionable VPC, subnet, and security group

Verify AWS CLI authentication:

``` bash
aws sts get-caller-identity
```

Make scripts executable:

``` bash
chmod +x scripts/*.sh
```

Example EC2 provisioning command:

``` bash
./scripts/create-ec2.sh \
  ap-south-1 \
  production-server-key \
  subnet-xxxxxxxx \
  sg-xxxxxxxx
```

The private key should be stored at the project root:

``` text
./production-server-key.pem
```

SSH example:

``` bash
ssh -i ./production-server-key.pem ubuntu@<PUBLIC_IP>
```

Do not share or commit the private key.

------------------------------------------------------------------------

## 13. Resume-Ready Project Highlights

This project is intended to demonstrate the following practical skills:

-   Automated AWS EC2 provisioning using AWS CLI and Bash
-   Linux server administration on Ubuntu
-   Secure SSH and firewall configuration
-   Nginx reverse proxy configuration
-   Java/JSP application deployment on Tomcat
-   Linux service management using systemd
-   PostgreSQL installation and operational management
-   Prometheus-based metrics collection
-   Grafana dashboard creation
-   Alertmanager-based alert routing
-   Shell scripting with validation and error handling
-   Log analysis and operational troubleshooting
-   Backup automation and restore validation
-   Infrastructure and deployment documentation

### Example resume bullet

> Built a Bash-driven Linux server automation project that provisions
> AWS EC2 infrastructure and deploys a Java/JSP application using Nginx,
> Apache Tomcat, PostgreSQL, and systemd; added Prometheus, Node
> Exporter, Grafana, and Alertmanager for infrastructure monitoring,
> dashboards, and alerting.

Only include components in the final resume bullet after they have been
implemented, tested, and documented in this repository.

------------------------------------------------------------------------

## 14. Project Roadmap

-   [ ] Create and validate AWS key pair automation
-   [ ] Provision Ubuntu EC2 instance
-   [ ] Implement secure SSH access
-   [ ] Create base Ubuntu server setup script
-   [ ] Configure UFW and security groups
-   [ ] Install Java and Tomcat
-   [ ] Create systemd service configuration
-   [ ] Deploy JSP WAR artifact
-   [ ] Install and configure PostgreSQL
-   [ ] Configure Nginx reverse proxy
-   [ ] Add application health checks
-   [ ] Install Node Exporter
-   [ ] Install and configure Prometheus
-   [ ] Create Grafana dashboards
-   [ ] Configure Alertmanager
-   [ ] Add database backup automation
-   [ ] Add log rotation and retention
-   [ ] Test failure and recovery scenarios
-   [ ] Document deployment and troubleshooting
-   [ ] Add CI validation for shell scripts
-   [ ] Review security and remove hardcoded configuration

------------------------------------------------------------------------

## 15. Engineering Principles

This project follows these principles:

1.  **Automation over manual repetition** --- repeatable tasks should be
    scripted.
2.  **Least privilege** --- services and users should receive only
    required permissions.
3.  **Fail fast** --- scripts should validate inputs and stop on
    critical errors.
4.  **Observability by design** --- deployments should be measurable and
    diagnosable.
5.  **Recoverability** --- backups must be accompanied by restore
    procedures.
6.  **Documentation** --- every operational process should be
    reproducible by another engineer.
7.  **Honest project reporting** --- the README should reflect what has
    actually been implemented and tested.

------------------------------------------------------------------------

## 16. Author

Maintained as a hands-on DevOps learning and portfolio project.

The repository will evolve from basic Linux administration and Bash
automation toward a more production-oriented deployment and
observability workflow.
