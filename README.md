#DLT_DATABRICKS

Proyecto de Data Engineering desplegado en **Azure Databricks** mediante **Databricks Asset Bundles**, **GitHub Actions** y **autenticación OIDC** / **Workload Identity Federation**.

El repositorio separa el ciclo de despliegue de aplicaciones Databricks de la infraestructura administrada con Terraform.

###Arquitectura

```GitHub
│
├── develop
│    └── GitHub Actions
│         └── sp-github-dev
│              └── Databricks DEV
│
├── uat
│    └── GitHub Actions
│         └── sp-github-uat
│              └── Databricks UAT
│
└── main
     └── GitHub Actions
          └── sp-github-prod
               └── Databricks PROD

Terraform PROD
└── sp-github-terraform-prod
     └── Infraestructura Unity Catalog / Storage / Grants
```

###Ambientes

| Ambiente | Branch | Bundle target | Modo | Catalog | Storage Account |
|----------|--------|---------------|------|---------|-----------------|
| DEV | `develop` | `dev` | development | `adbdep_0013` | `adlsproject13dev2` |
| UAT | `uat` | `uat` | development | `adbuat_0013` | `adlsproject13uat2` |
| PROD | `main` | `prod` | production | `adbprod_0013` | `adlsproject13prod2` |

###Estructura del repositorio

```DLT_DATABRICKS/
├── .github/
│   └── workflows/
│       ├── deploy.yml
│       └── terraform-prod.yml
├── governance/
│   └── security.sql
├── monitoring/
│   └── etl_run_log.ipynb
├── resources/
│   ├── pipeline.yml
│   ├── job.yml
│   └── alerts.yml
├── terraform/
│   └── prod/
├── transformations/
├── databricks.yml
└── README.md
```

##Databricks Asset Bundle

El archivo databricks.yml define tres targets:

* dev

* uat

* prod

Las variables **catalog**, **storage_account** y **warehouse_id** cambian automáticamente según el target.

Ejemplos:

databricks bundle validate -t dev
databricks bundle validate -t uat
databricks bundle validate -t prod

Para desplegar manualmente:

databricks bundle deploy -t dev
databricks bundle deploy -t uat
databricks bundle deploy -t prod

El despliegue normal debe hacerse mediante GitHub Actions para evitar problemas de ownership entre identidades distintas.

###Recursos del Bundle

####Pipeline

resources/pipeline.yml define el pipeline Lakeflow/Delta Live Tables. Los nombres y configuraciones deben usar variables del Bundle y no valores hardcodeados de DEV/UAT/PROD.

Patrón esperado:

name: ${bundle.target}_ingest_y_transform
catalog: ${var.catalog}

La cuenta de storage debe recibirse mediante:

STORAGE_ACCOUNT: ${var.storage_account}

###Job

resources/job.yml orquesta:

1. Pipeline de transformación.

2. Gobierno y seguridad.

3. Logging en control.etl_run_log.

4. Alertas.

El Job debe usar:

warehouse_id: ${var.warehouse_id}

y nunca un Warehouse ID hardcodeado.

###Alerts

resources/alerts.yml declara las alertas como recursos del Bundle.

Esto evita usar IDs de alerts manuales, ya que esos IDs son diferentes en cada workspace.

Las referencias desde el Job deben usar:

${resources.alerts.alert_fallos.id}
${resources.alerts.alert_slo.id}

###PROD

PROD usa:

Workspace:
https://adb-7405618768922549.9.azuredatabricks.net

Catalog:
adbprod_0013

Storage:
adlsproject13prod2

SQL Warehouse:
1f12be5ac4de5390

El target PROD debe usar:

mode: production

####Identidades

###Asset Bundle

El despliegue del Bundle en PROD utiliza:

sp-github-prod

Esta identidad despliega y ejecuta recursos de aplicación.

####Terraform

La infraestructura PROD utiliza una identidad separada:

sp-github-terraform-prod

No debe utilizarse esta identidad para el deploy normal del Asset Bundle.

###GitHub Environments

Deben existir los environments:

dev
uat
prod

Cada environment debe contener:

DATABRICKS_HOST
DATABRICKS_CLIENT_ID

En PROD, DATABRICKS_CLIENT_ID debe corresponder a sp-github-prod.

Terraform utiliza variables separadas para su propia identidad.

No almacenar en GitHub YAML:

* PAT

* Client secrets

* Passwords

* Storage keys

* SAS tokens

La autenticación utiliza OIDC.

##Flujo CI/CD
```
feature
   │
   ▼
Pull Request
   │
develop
   │
   ▼
Deploy DEV
   │
   ▼
Validación
   │
   ▼
Pull Request
   │
uat
   │
   ▼
Deploy UAT
   │
   ▼
Validación
   │
   ▼
Pull Request
   │
main
   │
   ▼
GitHub Environment PROD approval
   │
   ▼
Deploy PROD
```

# GitHub Actions

El workflow `.github/workflows/deploy.yml` ejecuta:

```text
develop → bundle validate -t dev → bundle deploy -t dev
uat     → bundle validate -t uat → bundle deploy -t uat
main    → bundle validate -t prod → bundle deploy -t prod
```

Para PROD se recomienda configurar **Required reviewers** sobre el GitHub Environment prod.

También se recomienda proteger la branch main y permitir cambios únicamente mediante Pull Request.

#Validación antes de promover a PROD

Antes del merge **uat -> main**:

databricks bundle validate -t uat

Después del merge, GitHub Actions debe:

Autenticarse como sp-github-prod.

Ejecutar databricks bundle validate -t prod.

Esperar aprobación del Environment prod, si está configurada.

Ejecutar databricks bundle deploy -t prod.

##Verificación después del primer deploy PROD

Revisar:

- Pipeline **${bundle.target}_ingest_y_transform**.

- Job ${bundle.target}_Job_complete.

- Streaming tables de bronze/silver/gold/control.

- control.etl_run_log.

- Governed tag classification.

- Masking de PII.

- SQL Alerts.

- Lineage.

- Permisos del Service Principal.

- Acceso al SQL Warehouse.

- Acceso al storage PROD.

##Terraform

Terraform administra la infraestructura base PROD, incluyendo según la configuración actual:

- Storage Credential.

- External Locations.

- Catalog PROD.

- Schemas.

- Workspace Binding.

- Unity Catalog grants.

- Governed tag permissions.

- Tabla técnica control.etl_run_log.

Comandos locales:

```terraform -chdir=terraform/prod init
terraform -chdir=terraform/prod validate
terraform -chdir=terraform/prod plan
terraform -chdir=terraform/prod state list
```

Regla importante

No mezclar responsabilidades:
```
sp-github-terraform-prod -> infraestructura
```

```
sp-github-prod -> Asset Bundle / pipelines / jobs
```

Esta separación reduce privilegios y facilita auditoría, troubleshooting y futuras migraciones.
