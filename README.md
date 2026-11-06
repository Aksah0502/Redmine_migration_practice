# Redmine Migration: 4.2.11 to 7.0.3

A hands-on DevOps project demonstrating the migration of Redmine from version **4.2.11 to 7.0.3** using Docker, PostgreSQL, and Nginx. The project implements database backup and restoration, application migration, Blue-Green deployment, traffic switching, and rollback procedures.

## 1. Project Overview

The objective of this project is to upgrade an existing Redmine application from version 4.2.11 to 7.0.3 while preserving application data and minimizing service downtime.

The migration is divided into three modules:

- **Module 1 – Blue Environment:** Deploy Redmine 4.2.11, configure PostgreSQL, populate sample data, and create database and attachment backups.
- **Module 2 – Green Environment:** Deploy Redmine 7.0.3, restore the backup, execute database migrations, and validate the upgraded application.
- **Module 3 – Blue-Green Deployment:** Configure Nginx as a reverse proxy, switch traffic between Blue and Green environments, and test rollback.

## 2. Technology Stack

| Technology | Purpose |
|---|---|
| Redmine 4.2.11 | Existing application (Blue) |
| Redmine 7.0.3 | Upgraded application (Green) |
| Ruby | Application runtime |
| Ruby on Rails | Web application framework |
| PostgreSQL 15 | Relational database |
| Docker | Application containerization |
| Docker Compose | Multi-container management |
| Nginx | Reverse proxy and traffic routing |
| PowerShell | Local environment management |

## 3. Project Architecture

The project uses two independent Redmine environments connected through an Nginx reverse proxy.

```text
                    User / Browser
                          |
                          |
                    localhost:8080
                          |
                          v
                    +-----------+
                    |   Nginx   |
                    |  Reverse  |
                    |   Proxy   |
                    +-----------+
                          |
                 Active Traffic Route
                    /           \
                   /             \
                  v               v
          +-------------+   +-------------+
          | Blue        |   | Green       |
          | Redmine     |   | Redmine     |
          | 4.2.11      |   | 7.0.3       |
          | Port: 3000  |   | Port: 3001  |
          +-------------+   +-------------+
                |                 |
                v                 v
          +-------------+   +-------------+
          | PostgreSQL  |   | PostgreSQL  |
          | Blue DB     |   | Green DB    |
          +-------------+   +-------------+
                                  ^
                                  |
                          Restored Backup
```

**Traffic routing:**
- Blue environment: `http://localhost:3000`
- Green environment: `http://localhost:3001`
- Nginx entry point: `http://localhost:8080`

Nginx forwards incoming requests to the environment configured in its upstream section.

## 4. Project Structure

```text
Migration_Practice/
│
├── redmine/                       # Redmine 4.2.11 source
│
├── redmine-7.0/                   # Redmine 7.0.3 source
│
├── deployment/
│   │
│   ├── module-1/
│   │   ├── Dockerfile
│   │   ├── docker-compose.yaml
│   │   ├── database.yml
│   │   ├── Gemfile.local
│   │   ├── .env
│   │   └── seed-data.ps1
│   │
│   ├── module-2/
│   │   ├── Dockerfile
│   │   ├── docker-compose.yaml
│   │   ├── database.yml
│   │   ├── Gemfile.local
│   │   └── .env
│   │
│   └── module-3/
│       ├── docker-compose.yaml
│       └── nginx.conf
│
├── runtime-data/
│   └── attachments/
│
├── backups/
│   ├── baseline-4.2.11.txt
│   ├── redmine-4.2.11.dump
│   └── attachments/
│
└── README.md
```

*Note: Environment files, backup files, and runtime data are excluded from Git using `.gitignore`.*

## 5. Implementation

### Module 1: Deploying Redmine 4.2.11 (Blue)

The first module establishes the existing application environment.

**Tasks performed:**

1. Created a Docker-based environment for Redmine 4.2.11.
2. Configured PostgreSQL as the database.
3. Set up persistent storage for database files and attachments.
4. Started the application and verified access.
5. Created sample users, a project, issues, and an attachment.
6. Generated a PostgreSQL database backup using `pg_dump`.
7. Backed up the attachment directory separately.

**Application URL:** `http://localhost:3000`

The backup serves as the recovery point and migration source for the Green environment.

### Module 2: Migrating to Redmine 7.0.3 (Green)

The second module creates a separate environment for the upgraded application.

**Tasks performed:**

1. Created a new Docker image for Redmine 7.0.3.
2. Configured a separate PostgreSQL database.
3. Restored the Blue database backup into the Green database.
4. Restored the attachment files.
5. Executed Redmine database migrations to update the schema.
6. Started the upgraded application.
7. Verified users, projects, issues, and attachment availability.

**Application URL:** `http://localhost:3001`

The Green environment was validated independently before receiving traffic through Nginx.

### Module 3: Blue-Green Deployment Using Nginx

The third module implements traffic management using Nginx.

**Tasks performed:**

1. Created an Nginx reverse proxy container.
2. Configured an upstream server to point to the Blue environment.
3. Verified application access through Nginx.
4. Changed the upstream configuration to point to Green.
5. Validated the Nginx configuration and reloaded it.
6. Verified that Redmine 7.0.3 was accessible through the same entry point.
7. Switched traffic back to Blue to test the rollback procedure.

**Nginx entry point:** `http://localhost:8080`

The application version can be changed behind the same entry point by updating the Nginx upstream configuration and reloading Nginx.

## 6. Validation and Testing

The following checks were performed during the migration:

| Test | Result |
|---|---|
| Redmine 4.2.11 deployment | Passed |
| PostgreSQL connectivity | Passed |
| Database backup creation | Passed |
| Attachment backup | Passed |
| Green database restoration | Passed |
| Green attachment restoration | Passed |
| Database migrations | Completed |
| Redmine 7.0.3 startup | Passed |
| Existing users and projects | Verified |
| Existing issues | Verified |
| Attachment download | Verified |
| Nginx traffic switching | Passed |
| Rollback procedure | Executed |

## 7. Rollback Strategy

The Blue environment is retained as the previous application version and serves as the rollback target during the deployment exercise.

If an issue is identified after switching traffic to Green:

1. Update the Nginx upstream to point back to Blue.
2. Validate the Nginx configuration using `nginx -t`.
3. Reload Nginx.
4. Verify application accessibility through the Nginx entry point.

**Important:** This exercise demonstrates traffic rollback. It does not implement reverse database synchronization. If Green has accepted new production writes, switching an old Redmine 4.2.11 application back to the upgraded database is unsafe. A production rollback requires a planned data-reconciliation strategy.

## 8. Key Learning Outcomes

Through this project, the following DevOps concepts were implemented and practiced:

- Docker image creation and container management.
- Multi-container application deployment using Docker Compose.
- PostgreSQL database backup and restoration.
- Persistent storage and attachment management.
- Application version migration and database schema upgrades.
- Blue-Green deployment strategy.
- Nginx reverse proxy configuration.
- Traffic switching and rollback procedures.
- Environment-specific configuration and secret management.

## 9. Running the Project

**Prerequisites:**
- Docker Desktop
- Docker Compose
- Git
- Windows PowerShell

Start each module from its respective directory.

**Module 1 – Blue:**

```powershell
cd deployment/module-1
docker compose up -d --build
```

**Module 2 – Green:**

```powershell
cd deployment/module-2
docker compose up -d --build
```

**Module 3 – Nginx:**

```powershell
cd deployment/module-3
docker compose up -d
```

Access the applications:

| Environment | URL |
|---|---|
| Blue | http://localhost:3000 |
| Green | http://localhost:3001 |
| Nginx | http://localhost:8080 |

*Note: The database restoration, attachment restoration, and Redmine migration steps must be completed as described in the implementation sections. Starting the containers alone does not perform the entire migration.*

---

**Project Type:** DevOps Practice / Application Migration  
**Migration:** Redmine 4.2.11 → Redmine 7.0.3  
**Deployment Strategy:** Blue-Green Deployment  
**Status:** Implementation and validation completed in a local Docker-based environment.
