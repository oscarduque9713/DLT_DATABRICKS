# ============================================================
# GOVERNED TAG: classification
# ============================================================

# ------------------------------------------------------------
# PASO 1 - Leer el governed tag existente
# ------------------------------------------------------------

data "databricks_tag_policy" "classification" {
  tag_key = "classification"
}


# ------------------------------------------------------------
# PASO 2 - PERMISOS DEL TAG
# ------------------------------------------------------------
#
# TEMPORALMENTE DESACTIVADO.
#
# Motivo:
# Primero queremos reconstruir toda la infraestructura PROD
# usando sp-github-terraform-prod.
#
# Después de validar que Terraform funciona correctamente
# desde GitHub Actions, volveremos a habilitar este bloque.
#
resource "databricks_access_control_rule_set" "classification_permissions" {
  name = "accounts/${var.account_id}/tagPolicies/${data.databricks_tag_policy.classification.id}/ruleSets/default"

  grant_rules {
    principals = [

      # Service Principal DEV
      "servicePrincipals/d1d0dadf-f5aa-4686-bbaf-213583824bc7",

      # Service Principal UAT
      "servicePrincipals/ac32d38f-9573-471c-b5c9-b2ff8ec290f6",

      # Service Principal PROD
      "servicePrincipals/${var.deploy_principal}"
    ]

    role = "roles/tagPolicy.assigner"
  }

  grant_rules {
    principals = [
      "servicePrincipals/${var.terraform_principal}",
      "users/mercedesvargas945@gmail.com"
    ]

    role = "roles/tagPolicy.manager"
  }
}