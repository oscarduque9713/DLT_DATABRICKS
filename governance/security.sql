
ALTER TABLE IDENTIFIER({{CATALOG}} || '.ly_bronze.customer_rw')
ALTER COLUMN doc_id
SET TAGS ('classification' = 'PII');

ALTER TABLE IDENTIFIER({{CATALOG}} || '.ly_bronze.customer_rw')
ALTER COLUMN email
SET TAGS ('classification' = 'PII');

ALTER TABLE IDENTIFIER({{CATALOG}} || '.ly_bronze.customer_rw')
ALTER COLUMN phone
SET TAGS ('classification' = 'PII');


ALTER TABLE IDENTIFIER({{CATALOG}} || '.ly_silver.dim_customer')
ALTER COLUMN doc_id
SET TAGS ('classification' = 'PII');

ALTER TABLE IDENTIFIER({{CATALOG}} || '.ly_silver.dim_customer')
ALTER COLUMN email
SET TAGS ('classification' = 'PII');

ALTER TABLE IDENTIFIER({{CATALOG}} || '.ly_silver.dim_customer')
ALTER COLUMN phone
SET TAGS ('classification' = 'PII');


CREATE OR REPLACE FUNCTION IDENTIFIER({{CATALOG}} || '.security.mask_pii')(value STRING)
RETURNS STRING
RETURN
  CASE
    WHEN is_account_group_member('pii_readers')
      THEN value
    ELSE '****'
  END;