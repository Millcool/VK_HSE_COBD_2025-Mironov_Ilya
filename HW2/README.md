Красивое оформление с гпт
# Домашняя работа №2 — Hadoop + Hive: Анализ движения цен акций

## 🎯 Цель работы

Целью данной домашней работы было:
1. Развернуть экосистему **Hadoop + YARN + Hive** в контейнере Docker.  
2. Создать базу данных в Hive и загрузить туда CSV-датасет с движением цен акций.  
3. С помощью SQL-операторов (**WHERE, COUNT, GROUP BY, HAVING, ORDER BY, JOIN, UNION, WINDOW**) построить 5–6 аналитических витрин.  
4. Для каждой витрины добавить текстовое описание и вывод.

---

## 🧩 Используемые технологии

- **Ubuntu 22.04**
- **Hadoop 3.2.1**
- **Hive 3.1.3**
- **Java 11**
- **Docker + Docker Compose**
- **Beeline CLI**

---

## ⚙️ Структура проекта

```
HW2/
├── Dockerfile                  # Образ с Ubuntu, Hadoop и Hive
├── docker-compose.yml          # Контейнер master (HDFS + YARN + Hive)
├── conf/                       # Конфигурационные файлы Hadoop/Hive
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── yarn-site.xml
│   ├── mapred-site.xml
│   ├── hive-site.xml
│   └── hadoop-env.sh
├── entrypoint.sh               # Скрипт запуска сервисов Hadoop и Hive
├── data/
│   └── stocks.csv              # Исходный CSV с данными по акциям
└── README.md                   # Описание проекта (текущий файл)
```

---

## 🚀 Этапы выполнения

### 1. Развёртывание Hadoop + Hive

Собран Docker-образ на базе Ubuntu 22.04.  
В нём установлены Java 11, Hadoop 3.2.1 и Hive 3.1.3.  
Открыты порты:

| Компонент | Порт | Назначение |
|------------|------|------------|
| HDFS | 9870 | Веб-интерфейс |
| YARN | 8088 | Веб-интерфейс |
| Hive Metastore | 9083 | Сервис метаданных |
| HiveServer2 | 10000 | JDBC-доступ через Beeline |

В `entrypoint.sh` при старте контейнера автоматически поднимаются:
```bash
start-dfs.sh
start-yarn.sh
hive --service metastore -p 9083 &
hiveserver2 --hiveconf hive.metastore.uris=thrift://localhost:9083 &
```

---

### 2. Проверка кластера Hadoop

```bash
docker exec -it hadoop-hw2 bash
jps
# Ожидаемые процессы: NameNode, DataNode, ResourceManager, NodeManager

hdfs dfs -ls /
hdfs dfs -mkdir -p /user/hive/warehouse /tmp/hive
hdfs dfs -chmod -R 1777 /tmp /tmp/hive
hdfs dfs -chmod -R 771  /user/hive/warehouse
```

---

### 3. Настройка Hive Metastore

Hive использует встроенную базу **Apache Derby**.  
Инициализация выполнялась командой:
```bash
schematool -dbType derby -initSchema -verbose
```

При несовместимости библиотек `guava` был удалён конфликтный файл:
```bash
mv /opt/hive/lib/guava-19.0.jar /opt/hive/lib/guava-19.0.jar.bak
```

После этого метастор и HiveServer2 запустились корректно:
```bash
nohup hive --service metastore -p 9083 >/opt/hive/log.metastore 2>&1 &
nohup hiveserver2 --hiveconf hive.metastore.uris=thrift://localhost:9083 >/opt/hive/log.hiveserver2 2>&1 &
```

---

### 4. Подключение через Beeline

```bash
beeline -u "jdbc:hive2://localhost:10000" -n root -p ""
```

---

### 5. Создание базы и загрузка данных

```sql
CREATE DATABASE IF NOT EXISTS stocks_db;
USE stocks_db;

CREATE EXTERNAL TABLE stocks_raw (
    date STRING,
    open FLOAT,
    high FLOAT,
    low FLOAT,
    close FLOAT,
    volume BIGINT,
    name STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/stocks';
```

---

## 📊 Построенные аналитические витрины

| № | Название витрины | Используемые конструкции | Описание |
|---|------------------|--------------------------|-----------|
| 1 | **avg_close_per_company** | `GROUP BY`, `AVG`, `ORDER BY` | Средняя цена закрытия для каждой компании. |
| 2 | **max_volume_day** | `ORDER BY`, `LIMIT`, `GROUP BY` | День с максимальным объёмом торгов по каждой компании. |
| 3 | **quarterly_growth** | `WINDOW`, `LAG`, `PARTITION BY` | Рост или падение цены закрытия по кварталам. |
| 4 | **top5_by_volume** | `GROUP BY`, `HAVING` | ТОП-5 компаний по среднему дневному объёму торгов. |
| 5 | **high_vs_low_volatility** | `UNION`, `JOIN` | Сравнение акций с высокой и низкой волатильностью. |
| 6 | **monthly_summary** | `GROUP BY`, `MONTH(date)` | Средняя и медианная цена закрытия за месяц. |

---

## 📈 Примеры SQL-запросов

### 1. Средняя цена закрытия
```sql
CREATE TABLE avg_close_per_company AS
SELECT
  name,
  ROUND(AVG(close), 2) AS avg_close
FROM stocks_raw
WHERE close IS NOT NULL
GROUP BY name
ORDER BY avg_close DESC;
```

### 2. День с максимальным объёмом торгов
```sql
CREATE TABLE max_volume_day AS
SELECT
  name,
  date,
  volume
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY name ORDER BY volume DESC) AS rn
  FROM stocks_raw
) t
WHERE rn = 1;
```

### 3. Динамика изменения цены (окно)
```sql
CREATE TABLE quarterly_growth AS
SELECT
  name,
  date,
  close,
  LAG(close, 1) OVER (PARTITION BY name ORDER BY date) AS prev_close,
  ROUND(
    ((close - LAG(close, 1) OVER (PARTITION BY name ORDER BY date))
     / LAG(close, 1) OVER (PARTITION BY name ORDER BY date)) * 100, 2
  ) AS growth_pct
FROM stocks_raw
WHERE close IS NOT NULL;
```

### 4. ТОП-5 компаний по объёму торгов
```sql
CREATE TABLE top5_by_volume AS
SELECT
  name,
  ROUND(AVG(volume), 0) AS avg_volume
FROM stocks_raw
GROUP BY name
HAVING AVG(volume) IS NOT NULL
ORDER BY avg_volume DESC
LIMIT 5;
```

### 5. Высокая vs низкая волатильность
```sql
CREATE TABLE volatility_union AS
SELECT name, 'HIGH' AS vol_type, stddev(close) AS volatility
FROM stocks_raw
GROUP BY name
HAVING stddev(close) > 5
UNION ALL
SELECT name, 'LOW' AS vol_type, stddev(close) AS volatility
FROM stocks_raw
GROUP BY name
HAVING stddev(close) <= 5;
```

### 6. Месячная статистика
```sql
CREATE TABLE monthly_summary AS
SELECT
  name,
  substr(date, 1, 7) AS month,
  ROUND(AVG(close), 2) AS avg_close,
  MAX(close) AS max_close,
  MIN(close) AS min_close
FROM stocks_raw
GROUP BY name, substr(date, 1, 7)
ORDER BY name, month;
```

---

## 🧾 Итоговые результаты

✅ Hadoop и Hive успешно развёрнуты в Docker.  
✅ HDFS, YARN, Metastore и HiveServer2 функционируют корректно.  
✅ Датасет успешно загружен в Hive.  
✅ Построено 6 витрин, каждая демонстрирует разные SQL-возможности.  
✅ Все запросы выполняются через Beeline без ошибок.

---

## 🛠 Полезные команды

```bash
# Проверка HDFS
hdfs dfs -ls /

# Просмотр логов Hive
tail -n 50 /opt/hive/log.metastore
tail -n 50 /opt/hive/log.hiveserver2

# Подключение к Hive
beeline -u "jdbc:hive2://localhost:10000" -n root -p ""
```


## ✍️ Автор

**Илья Миронов**  
Магистратура, 3 семестр — курс «Анализ больших данных»  
Октябрь 2025 г.
