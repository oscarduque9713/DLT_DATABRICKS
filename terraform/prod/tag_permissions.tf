# ============================================================
# GOVERNED TAG: classification
# ============================================================
#
# Objetivo:
# Administrar mediante Terraform quién puede:
#
# 1. Asignar el governed tag "classification".
# 2. Administrar la política del governed tag.
#
# IMPORTANTE:
# El tag "classification" YA EXISTE.
# Por eso usamos un bloque "data" en lugar de "resource".
#
# "data" significa:
#   Terraform consulta un recurso existente.
#
# "resource" significaría:
#   Terraform crea o administra el ciclo de vida del recurso.
# ============================================================


# ------------------------------------------------------------
# PASO 1 - Leer el governed tag existente
# ------------------------------------------------------------

data "databricks_tag_policy" "classification" {

  # Nombre real del governed tag existente en Databricks.
  tag_key = "classification"
}


# ------------------------------------------------------------
# PASO 2 - Administrar los permisos del governed tag
# ------------------------------------------------------------

resource "databricks_access_control_rule_set" "classification_permissions" {

  # Construimos el identificador completo del Rule Set.
  #
  # var.account_id
  #   -> viene de variables.tf / terraform.tfvars
  #
  # data.databricks_tag_policy.classification.id
  #   -> es el ID que Terraform obtuvo al consultar
  #      el governed tag "classification".
  #
  # Ejemplo conceptual:
  #
  # accounts/<account-id>/tagPolicies/<tag-policy-id>/ruleSets/default

  name = "accounts/${var.account_id}/tagPolicies/${data.databricks_tag_policy.classification.id}/ruleSets/default"


  # ----------------------------------------------------------
  # PASO 3 - Permiso ASSIGN
  # ----------------------------------------------------------
  #
  # DEV, UAT y PROD pueden ASIGNAR el governed tag
  # "classification" sobre objetos permitidos.
  #
  # Por ejemplo:
  #   - columnas
  #   - tablas
  #   - schemas
  #
  # Esto NO les permite modificar la definición del tag.
  # Solo utilizarlo/asignarlo.
  # ----------------------------------------------------------

  grant_rules {

    principals = [

      # Service Principal DEV
      "servicePrincipals/d1d0dadf-f5aa-4686-bbaf-213583824bc7",

      # Service Principal UAT
      "servicePrincipals/ac32d38f-9573-471c-b5c9-b2ff8ec290f6",

      # Service Principal PROD
      #
      # No escribimos el Client ID directamente.
      # Terraform lo obtiene desde:
      #
      # variable "deploy_principal"
      #
      # cuyo valor está definido en terraform.tfvars.
      "servicePrincipals/${var.deploy_principal}"
    ]

    # Rol que permite asignar el governed tag.
    role = "roles/tagPolicy.assigner"
  }


  # ----------------------------------------------------------
  # PASO 4 - Permiso MANAGE
  # ----------------------------------------------------------
  #
  # El usuario administrador conserva el permiso para
  # administrar la política del governed tag.
  #
  # MANAGE permite acciones administrativas sobre
  # la política, no solamente asignar el tag.
  # ----------------------------------------------------------

  grant_rules {

    principals = [

      # Usuario administrador
      "users/mercedesvargas945@gmail.com"
    ]

    # Rol administrativo del governed tag.
    role = "roles/tagPolicy.manager"
  }
}