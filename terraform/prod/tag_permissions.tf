# ============================================================
# GOVERNED TAG: classification
# ============================================================
#
# Objetivo:
#
# Administrar mediante Terraform los permisos del governed tag:
#
#   classification
#
# Este tag ya existe en el Metastore, por lo tanto Terraform
# NO lo crea.
#
# Terraform solamente:
#
#   1. Busca el tag existente.
#   2. Busca los Service Principals PROD.
#   3. Administra los permisos Assign y Manage.
#
# IMPORTANTE:
#
# El recurso databricks_access_control_rule_set es autoritativo.
#
# Esto significa que Terraform intentará dejar exactamente
# los permisos declarados en este archivo.
#
# Por ese motivo debemos conservar aquí:
#
#   - DEV
#   - UAT
#   - PROD
#   - Terraform PROD
#   - Usuario administrador
#
# Si alguno se elimina del código, Terraform podría eliminar
# también ese permiso del governed tag.
# ============================================================


# ------------------------------------------------------------
# PASO 1 - Leer el governed tag existente
# ------------------------------------------------------------
#
# El governed tag "classification" ya fue creado previamente
# en el Metastore.
#
# Este data source NO crea ningún recurso.
#
# Solamente busca el tag y obtiene información como:
#
#   - ID de la Tag Policy
#   - Tag key
#
# Ese ID será utilizado posteriormente para construir el
# nombre del Access Control Rule Set.
#
data "databricks_tag_policy" "classification" {
  tag_key = "classification"
}


# ------------------------------------------------------------
# PASO 2 - Leer Service Principal Terraform PROD
# ------------------------------------------------------------
#
# Busca en Databricks el Service Principal utilizado por
# Terraform para administrar infraestructura PROD.
#
# La variable:
#
#   var.terraform_principal
#
# contiene el Application / Client ID de:
#
#   sp-github-terraform-prod
#
# Usamos el data source en lugar de construir manualmente:
#
#   servicePrincipals/<application-id>
#
# De esta forma Terraform obtiene directamente el identificador
# ACL correcto mediante:
#
#   acl_principal_id
#
data "databricks_service_principal" "terraform_prod" {
  application_id = var.terraform_principal
}


# ------------------------------------------------------------
# PASO 3 - Leer Service Principal de ejecución PROD
# ------------------------------------------------------------
#
# Busca el Service Principal utilizado por los pipelines,
# jobs y Asset Bundles en PROD.
#
# La variable:
#
#   var.deploy_principal
#
# corresponde a:
#
#   sp-github-prod
#
# Este SP NO administra infraestructura.
#
# Solamente necesita poder asignar el governed tag
# "classification" a los objetos permitidos.
#
data "databricks_service_principal" "deploy_prod" {
  application_id = var.deploy_principal
}


# ------------------------------------------------------------
# PASO 4 - Administrar permisos del governed tag
# ------------------------------------------------------------
#
# Este recurso administra el Rule Set asociado al governed tag
# "classification".
#
# IMPORTANTE:
#
# Este recurso es autoritativo.
#
# Terraform compara:
#
#   permisos declarados aquí
#
#             VS
#
#   permisos existentes en Databricks
#
# y modifica el Rule Set para que ambos coincidan.
#
# Por eso debemos incluir TODOS los principals que queremos
# conservar.
#
resource "databricks_access_control_rule_set" "classification_permissions" {

  # ----------------------------------------------------------
  # Identificador completo del Rule Set
  # ----------------------------------------------------------
  #
  # El formato esperado por Databricks es:
  #
  # accounts/<account_id>/tagPolicies/<tag_policy_id>/ruleSets/default
  #
  # account_id:
  #   viene de var.account_id
  #
  # tag_policy_id:
  #   viene del data source classification
  #
  name = "accounts/${var.account_id}/tagPolicies/${data.databricks_tag_policy.classification.id}/ruleSets/default"


  # ----------------------------------------------------------
  # PERMISO: ASSIGN
  # ----------------------------------------------------------
  #
  # Permite utilizar el governed tag "classification".
  #
  # Estos Service Principals pueden asignar el tag a los
  # objetos que administran dentro de sus respectivos
  # ambientes.
  #
  grant_rules {

    principals = [

      # ------------------------------------------------------
      # Service Principal DEV
      # ------------------------------------------------------
      #
      # Puede asignar el tag classification en DEV.
      #
      "servicePrincipals/d1d0dadf-f5aa-4686-bbaf-213583824bc7",


      # ------------------------------------------------------
      # Service Principal UAT
      # ------------------------------------------------------
      #
      # Puede asignar el tag classification en UAT.
      #
      "servicePrincipals/ac32d38f-9573-471c-b5c9-b2ff8ec290f6",


      # ------------------------------------------------------
      # Service Principal PROD
      # ------------------------------------------------------
      #
      # sp-github-prod
      #
      # Es la identidad utilizada por los pipelines/jobs
      # desplegados en PROD.
      #
      # acl_principal_id devuelve el formato correcto esperado
      # por Databricks para ACLs.
      #
      data.databricks_service_principal.deploy_prod.acl_principal_id
    ]

    # Permite asignar el governed tag.
    role = "roles/tagPolicy.assigner"
  }


  # ----------------------------------------------------------
  # PERMISO: MANAGE
  # ----------------------------------------------------------
  #
  # Los principals de este bloque pueden administrar los
  # permisos del governed tag.
  #
  # Esto es más poderoso que Assign.
  #
  grant_rules {

    principals = [

      # ------------------------------------------------------
      # Terraform PROD
      # ------------------------------------------------------
      #
      # sp-github-terraform-prod
      #
      # Terraform necesita Manage porque este mismo Service
      # Principal administra este Rule Set desde GitHub Actions.
      #
      # Esto permite que durante:
      #
      #   terraform plan
      #   terraform apply
      #
      # pueda leer y modificar los permisos del governed tag.
      #
      data.databricks_service_principal.terraform_prod.acl_principal_id,


      # ------------------------------------------------------
      # Usuario administrador
      # ------------------------------------------------------
      #
      # Se conserva un usuario administrador con Manage para
      # operaciones manuales y escenarios de bootstrap/recovery.
      #
      "users/mercedesvargas945@gmail.com"
    ]

    # Permite administrar la Tag Policy y su Rule Set.
    role = "roles/tagPolicy.manager"
  }
}