resource "databricks_sql_table" "etl_run_log" {
  name         = "etl_run_log"
  catalog_name = databricks_catalog.prod.name
  schema_name  = databricks_schema.control.name

  table_type         = "MANAGED"
  data_source_format = "DELTA"

  warehouse_id = var.warehouse_id

  column {
    name = "run_id"
    type = "STRING"
  }

  column {
    name = "pipeline_name"
    type = "STRING"
  }

  column {
    name = "flow_name"
    type = "STRING"
  }

  column {
    name = "layer"
    type = "STRING"
  }

  column {
    name = "object_name"
    type = "STRING"
  }

  column {
    name = "start_ts"
    type = "TIMESTAMP"
  }

  column {
    name = "end_ts"
    type = "TIMESTAMP"
  }

  column {
    name = "duration_sec"
    type = "BIGINT"
  }

  column {
    name = "status"
    type = "STRING"
  }

  column {
    name = "rows_written"
    type = "BIGINT"
  }

  column {
    name = "created_at"
    type = "TIMESTAMP"
  }

  column {
    name = "error_message"
    type = "STRING"
  }

  column {
    name = "error_detail"
    type = "STRING"
  }

  properties = {
    "delta.enableDeletionVectors"     = "true"
    "delta.enableRowTracking"         = "true"
    "delta.feature.appendOnly"        = "supported"
    "delta.feature.deletionVectors"   = "supported"
    "delta.feature.domainMetadata"    = "supported"
    "delta.feature.invariants"        = "supported"
    "delta.feature.rowTracking"       = "supported"
    "delta.minReaderVersion"          = "3"
    "delta.minWriterVersion"          = "7"
    "delta.parquet.compression.codec" = "zstd"
  }

  comment = "ETL execution log table managed by Terraform"
}

# aplicar grants a la tabla 

#resource "databricks_grant" "etl_run_log_sp" {
#  table     = databricks_sql_table.etl_run_log.id
#  principal = var.deploy_principal
#
#  privileges = [
#    "SELECT",
#    "MODIFY"
#  ]
#}