-- ============================================
-- Скрипт загрузки данных в Hive
-- ============================================

-- 1. Создание базы данных
CREATE DATABASE IF NOT EXISTS stocks_hw;
USE stocks_hw;

-- 2. Создание внешней (staging) таблицы для сырого CSV
-- Формат CSV: date,open,high,low,close,volume,Name
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
LOCATION '/data/stocks_hw/stg_prices_csv';

-- 3. Создание основной таблицы для работы
CREATE TABLE IF NOT EXISTS stocks_raw (
  `date`   STRING,
  `open`   DOUBLE,
  `high`   DOUBLE,
  `low`    DOUBLE,
  `close`  DOUBLE,
  `volume` BIGINT,
  `name`   STRING
)
STORED AS PARQUET;

-- 4. Загрузка данных из CSV в основную таблицу
-- Примечание: Данные должны быть загружены в HDFS перед выполнением этого скрипта
-- Команда для загрузки: hdfs dfs -put /data/all_stocks_5yr.csv /data/stocks_hw/stg_prices_csv/
INSERT OVERWRITE TABLE stocks_raw
SELECT 
  date,
  open,
  high,
  low,
  close,
  volume,
  name
FROM stg_prices_csv
WHERE date IS NOT NULL 
  AND name IS NOT NULL
  AND close IS NOT NULL
  AND date != 'date';  -- Исключаем заголовок CSV

