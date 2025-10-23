-- 1. БД
CREATE DATABASE IF NOT EXISTS stocks_hw;
USE stocks_hw;

-- 2. Внешняя (staging) таблица под сырой CSV
-- Формат CSV: date,open,high,low,close,volume,Name
-- date в CSV = 'yyyy-MM-dd'
CREATE EXTERNAL TABLE IF NOT EXISTS stg_prices_csv (
  `date`   STRING,
  `open`   DOUBLE,
  `high`   DOUBLE,
  `low`    DOUBLE,
  `close`  DOUBLE,
  `volume` BIGINT,
  `name`   STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  "separatorChar" = ",",
  "quoteChar"     = "\"",
  "escapeChar"    = "\\"
)
STORED AS TEXTFILE
LOCATION 'hdfs:///data/stocks_hw/stg_prices_csv';  -- поменяй путь на свой HDFS/S3
