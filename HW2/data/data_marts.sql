-- ============================================
-- Аналитические витрины для анализа акций
-- ============================================

USE stocks_hw;

-- ============================================
-- ВИТРИНА 1: Средняя цена закрытия по компаниям
-- ============================================
-- Используемые конструкции: WHERE, GROUP BY, AVG, ORDER BY
-- Описание: Витрина демонстрирует среднюю цену закрытия акций для каждой компании
-- за весь анализируемый период. Позволяет сравнить средний уровень цен между
-- различными компаниями и выявить наиболее дорогие и дешевые акции.
-- 
-- Тезисы:
-- 1. Рассчитывается средняя цена закрытия (AVG(close)) для каждой компании
-- 2. Используется фильтрация WHERE для исключения записей с NULL значениями
-- 3. Группировка по названию компании (GROUP BY name) для агрегации данных
-- 4. Результаты сортируются по убыванию средней цены (ORDER BY DESC)
-- 5. Витрина помогает инвесторам быстро оценить средний уровень цен акций
-- 6. Может использоваться для сравнения относительной стоимости акций
-- 7. Позволяет выявить компании с наиболее стабильными ценами

CREATE TABLE IF NOT EXISTS avg_close_per_company AS
SELECT
  name,
  ROUND(AVG(close), 2) AS avg_close,
  COUNT(*) AS total_records
FROM stocks_raw
WHERE close IS NOT NULL
  AND name IS NOT NULL
GROUP BY name
ORDER BY avg_close DESC;

-- ============================================
-- ВИТРИНА 2: День с максимальным объемом торгов по каждой компании
-- ============================================
-- Используемые конструкции: WINDOW (ROW_NUMBER), PARTITION BY, ORDER BY, WHERE
-- Описание: Витрина определяет день с максимальным объемом торгов для каждой компании.
-- Это позволяет выявить пики торговой активности и связать их с конкретными датами,
-- что может быть полезно для анализа событий, вызвавших повышенный интерес к акциям.
--
-- Тезисы:
-- 1. Используется оконная функция ROW_NUMBER() для ранжирования записей
-- 2. PARTITION BY name обеспечивает независимое ранжирование для каждой компании
-- 3. ORDER BY volume DESC сортирует записи по убыванию объема торгов
-- 4. Фильтр WHERE rn = 1 выбирает только записи с максимальным объемом
-- 5. Витрина помогает выявить дни с аномально высокой торговой активностью
-- 6. Может использоваться для анализа корреляции между событиями и объемом торгов
-- 7. Позволяет идентифицировать компании с наиболее волатильными торговыми днями

CREATE TABLE IF NOT EXISTS max_volume_day AS
SELECT
  name,
  date,
  volume,
  open,
  high,
  low,
  close
FROM (
  SELECT 
    name,
    date,
    volume,
    open,
    high,
    low,
    close,
    ROW_NUMBER() OVER (PARTITION BY name ORDER BY volume DESC) AS rn
  FROM stocks_raw
  WHERE volume IS NOT NULL
    AND name IS NOT NULL
) t
WHERE rn = 1
ORDER BY volume DESC;

-- ============================================
-- ВИТРИНА 3: Квартальная динамика роста цен
-- ============================================
-- Используемые конструкции: WINDOW (LAG), PARTITION BY, ORDER BY, WHERE
-- Описание: Витрина демонстрирует динамику изменения цены закрытия по кварталам
-- для каждой компании. Используя оконные функции, рассчитывается процентное изменение
-- цены относительно предыдущего квартала, что позволяет отслеживать тренды роста или падения.
--
-- Тезисы:
-- 1. Используется оконная функция LAG() для получения значения предыдущего периода
-- 2. PARTITION BY name обеспечивает расчеты в рамках каждой компании
-- 3. ORDER BY date гарантирует правильную последовательность временных рядов
-- 4. Рассчитывается процентное изменение цены между кварталами
-- 5. Витрина помогает выявить сезонные паттерны и тренды роста/падения
-- 6. Может использоваться для прогнозирования будущей динамики цен
-- 7. Позволяет сравнивать квартальную производительность различных компаний

CREATE TABLE IF NOT EXISTS quarterly_growth AS
SELECT
  name,
  year,
  quarter,
  avg_close,
  prev_avg_close,
  ROUND(
    ((avg_close - prev_avg_close) / prev_avg_close) * 100, 2
  ) AS growth_pct
FROM (
  SELECT
    name,
    substr(date, 1, 4) AS year,
    CASE 
      WHEN CAST(substr(date, 6, 2) AS INT) IN (1,2,3) THEN 1
      WHEN CAST(substr(date, 6, 2) AS INT) IN (4,5,6) THEN 2
      WHEN CAST(substr(date, 6, 2) AS INT) IN (7,8,9) THEN 3
      ELSE 4
    END AS quarter,
    AVG(close) AS avg_close,
    LAG(AVG(close), 1) OVER (
      PARTITION BY name 
      ORDER BY substr(date, 1, 4), 
        CASE 
          WHEN CAST(substr(date, 6, 2) AS INT) IN (1,2,3) THEN 1
          WHEN CAST(substr(date, 6, 2) AS INT) IN (4,5,6) THEN 2
          WHEN CAST(substr(date, 6, 2) AS INT) IN (7,8,9) THEN 3
          ELSE 4
        END
    ) AS prev_avg_close
  FROM stocks_raw
  WHERE close IS NOT NULL
    AND date IS NOT NULL
    AND name IS NOT NULL
    AND length(date) >= 7
  GROUP BY name, substr(date, 1, 4), 
    CASE 
      WHEN CAST(substr(date, 6, 2) AS INT) IN (1,2,3) THEN 1
      WHEN CAST(substr(date, 6, 2) AS INT) IN (4,5,6) THEN 2
      WHEN CAST(substr(date, 6, 2) AS INT) IN (7,8,9) THEN 3
      ELSE 4
    END
) t
WHERE prev_avg_close IS NOT NULL
ORDER BY name, year, quarter;

-- ============================================
-- ВИТРИНА 4: ТОП-5 компаний по среднему объему торгов
-- ============================================
-- Используемые конструкции: GROUP BY, HAVING, AVG, ORDER BY, COUNT
-- Описание: Витрина определяет пять компаний с наибольшим средним дневным объемом торгов.
-- Используется HAVING для фильтрации результатов после агрегации, что позволяет
-- исключить компании с недостаточным количеством данных или аномальными значениями.
--
-- Тезисы:
-- 1. Используется GROUP BY для агрегации данных по компаниям
-- 2. HAVING применяется для фильтрации после агрегации (исключение NULL и малых объемов)
-- 3. COUNT(*) используется для проверки достаточности данных по каждой компании
-- 4. ORDER BY avg_volume DESC сортирует компании по убыванию среднего объема
-- 5. LIMIT 5 ограничивает результат пятью компаниями
-- 6. Витрина помогает выявить наиболее ликвидные акции на рынке
-- 7. Может использоваться для анализа инвестиционной привлекательности компаний

CREATE TABLE IF NOT EXISTS top5_by_volume AS
SELECT
  name,
  ROUND(AVG(volume), 0) AS avg_volume,
  COUNT(*) AS trading_days,
  MIN(volume) AS min_volume,
  MAX(volume) AS max_volume
FROM stocks_raw
WHERE volume IS NOT NULL
  AND name IS NOT NULL
GROUP BY name
HAVING AVG(volume) IS NOT NULL
  AND COUNT(*) >= 100
ORDER BY avg_volume DESC
LIMIT 5;

-- ============================================
-- ВИТРИНА 5: Сравнение акций с высокой и низкой волатильностью
-- ============================================
-- Используемые конструкции: UNION ALL, GROUP BY, HAVING, STDDEV, WHERE
-- Описание: Витрина объединяет данные о компаниях с высокой и низкой волатильностью цен,
-- используя UNION ALL. Волатильность рассчитывается как стандартное отклонение цен закрытия.
-- Это позволяет разделить компании на две категории для сравнительного анализа.
--
-- Тезисы:
-- 1. Используется UNION ALL для объединения двух наборов данных
-- 2. STDDEV(close) рассчитывает стандартное отклонение как меру волатильности
-- 3. HAVING применяется для разделения компаний на категории по уровню волатильности
-- 4. Первый SELECT выбирает компании с высокой волатильностью (> порогового значения)
-- 5. Второй SELECT выбирает компании с низкой волатильностью (<= порогового значения)
-- 6. Витрина помогает инвесторам выбрать акции в соответствии с их риск-профилем
-- 7. Может использоваться для построения диверсифицированного портфеля

CREATE TABLE IF NOT EXISTS volatility_comparison AS
SELECT 
  name, 
  'HIGH' AS volatility_type, 
  ROUND(STDDEV(close), 2) AS volatility,
  ROUND(AVG(close), 2) AS avg_close,
  COUNT(*) AS records_count
FROM stocks_raw
WHERE close IS NOT NULL
  AND name IS NOT NULL
GROUP BY name
HAVING STDDEV(close) > 10
  AND COUNT(*) >= 50

UNION ALL

SELECT 
  name, 
  'LOW' AS volatility_type, 
  ROUND(STDDEV(close), 2) AS volatility,
  ROUND(AVG(close), 2) AS avg_close,
  COUNT(*) AS records_count
FROM stocks_raw
WHERE close IS NOT NULL
  AND name IS NOT NULL
GROUP BY name
HAVING STDDEV(close) <= 10
  AND COUNT(*) >= 50

ORDER BY volatility_type, volatility DESC;

-- ============================================
-- ВИТРИНА 6: Месячная статистика с JOIN для сравнения
-- ============================================
-- Используемые конструкции: GROUP BY, JOIN, WHERE, COUNT, ORDER BY
-- Описание: Витрина создает месячную статистику по ценам закрытия и объему торгов,
-- а затем использует JOIN для объединения с данными о средних ценах по компаниям.
-- Это позволяет сравнивать месячные показатели с общими средними значениями.
--
-- Тезисы:
-- 1. Используется GROUP BY для агрегации данных по компании и месяцу
-- 2. SUBSTR(date, 1, 7) извлекает год и месяц из даты для группировки
-- 3. JOIN объединяет месячную статистику с общими средними показателями
-- 4. WHERE используется для фильтрации данных перед агрегацией
-- 5. COUNT(*) подсчитывает количество торговых дней в каждом месяце
-- 6. Витрина помогает выявить сезонные паттерны в торговле акциями
-- 7. Позволяет сравнивать месячные показатели с долгосрочными средними значениями

CREATE TABLE IF NOT EXISTS monthly_summary_with_avg AS
SELECT
  ms.name,
  ms.month,
  ms.avg_close AS monthly_avg_close,
  ms.max_close,
  ms.min_close,
  ms.avg_volume AS monthly_avg_volume,
  ms.trading_days,
  ac.avg_close AS overall_avg_close,
  ROUND(
    ((ms.avg_close - ac.avg_close) / ac.avg_close) * 100, 2
  ) AS deviation_from_avg_pct
FROM (
  SELECT
    name,
    SUBSTR(date, 1, 7) AS month,
    ROUND(AVG(close), 2) AS avg_close,
    MAX(close) AS max_close,
    MIN(close) AS min_close,
    ROUND(AVG(volume), 0) AS avg_volume,
    COUNT(*) AS trading_days
  FROM stocks_raw
  WHERE close IS NOT NULL
    AND volume IS NOT NULL
    AND name IS NOT NULL
    AND date IS NOT NULL
  GROUP BY name, SUBSTR(date, 1, 7)
) ms
JOIN (
  SELECT
    name,
    ROUND(AVG(close), 2) AS avg_close
  FROM stocks_raw
  WHERE close IS NOT NULL
    AND name IS NOT NULL
  GROUP BY name
) ac ON ms.name = ac.name
ORDER BY ms.name, ms.month;

