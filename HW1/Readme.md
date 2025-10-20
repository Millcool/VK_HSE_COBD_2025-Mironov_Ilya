Тут применил немного красоты от GPT, чтобы было удобнее читать, если вдруг нужен именно мой не редактированный текст, то он в Readme.md


# 🧮 Отчёт по ДЗ №1 — Анализ больших данных (Hadoop + YARN + MapReduce)

## 📘 Общая информация

**Студент:** *Илья Миронов*  
**Предмет:** Анализ больших данных  
**Цель работы:** Развернуть локальный кластер Hadoop, выполнить базовые операции с HDFS и реализовать MapReduce-задачу WordCount через YARN.  

---

## ⚙️ 1. Запуск окружения

### 1.1. Подготовка и сборка Docker-контейнера

Контейнер на базе `ubuntu:22.04` содержит:
- Hadoop 3.3.6  
- OpenJDK 11  
- SSH для внутренних скриптов  
- Преднастроенные конфигурации HDFS и YARN  

Сборка контейнера выполняется:
```bash
docker-compose up -d --build
```

После сборки и запуска все сервисы стартуют автоматически:
- NameNode  
- DataNode  
- SecondaryNameNode  
- ResourceManager  
- NodeManager  

Проверка:
```bash
docker exec -it hadoop-master bash -lc "jps -l"
```

---

## 🧩 2. Выполнение скрипта заданий

Все задачи реализованы в скрипте [`run_hw.sh`](opt/hadoop/run_hw.sh).  
Он выполняется в контейнере командой:

```bash
docker exec -it hadoop-master bash -lc "bash /opt/hadoop/run_hw.sh"
```

### Задачи:

| № | Задание | Результат |
|---|----------|------------|
| 1 | Создание каталога `/createme` в HDFS | ✅ Создан или уже существовал |
| 2 | Удаление каталога `/delme` | ✅ Удалён, если был |
| 3 | Создание непустого файла `/nonnull.txt` | ✅ Создан |
| 4 | Выполнение MapReduce WordCount через YARN | ✅ Успешно |
| 5 | Подсчёт вхождений слова `Innsmouth` и запись в `/whataboutinnsmouth.txt` | ✅ Результат: **3** |

---

## 📊 3. Проверка выполнения

### Проверка результатов WordCount
```bash
docker exec -it hadoop-master bash -lc 'hdfs dfs -cat /tmp/wordcount_shadow/part-r-00000 | sed -n "1,200p"'
```

**Вывод:**
```
Big 1
Hadoop 2
MapReduce 1
YARN 1
clear 1
data 3
data. 2
examples 1
examples; 1
love 1
loves 1
small 2
```

### Проверка итогового файла
```bash
docker exec -it hadoop-master bash -lc "hdfs dfs -cat /whataboutinnsmouth.txt"
```

**Результат:**
```
3
```

---

## 🔗 4. Схема обработки данных (Data Flow)

```mermaid
flowchart TD
    A[Файл shadow.txt на хосте] -->|копируется в volume /data| B[Контейнер Hadoop Master]
    B -->|загрузка в HDFS| C[/shadow.txt в HDFS/]
    C -->|MapReduce WordCount| D[(YARN ResourceManager)]
    D -->|формирует результат| E[/tmp/wordcount_shadow/part-r-00000/]
    E -->|awk фильтрует слово "Innsmouth"| F[/whataboutinnsmouth.txt/]
    F -->|результат = 3| G[Вывод пользователю]
```

---

## 🧠 5. Что делает скрипт `run_hw.sh`

1. Запускает SSH и сервисы Hadoop (если не запущены).  
2. Создаёт и проверяет базовые файлы и каталоги в HDFS.  
3. Загружает `shadow.txt` (из `/data`) в HDFS.  
4. Запускает MapReduce-задачу `wordcount` через YARN:
   - вход: `/shadow.txt`  
   - выход: `/tmp/wordcount_shadow`  
5. Извлекает количество вхождений слова `Innsmouth` из результата (`part-r-00000`)  
   и записывает его в `/whataboutinnsmouth.txt`.

---

## 🧾 6. Пример консольного вывода

```
[OK] /createme создана (или уже существовала).
[OK] /delme удалена (если была).
[OK] /nonnull.txt создан.
[INFO] Загрузка /data/shadow.txt в HDFS как /shadow.txt
2025-10-20 20:43:03,080 INFO mapreduce.Job: The url to track the job: http://master:8088/proxy/application_1760992973693_0001/
...
[OK] WordCount завершён. Результат: /tmp/wordcount_shadow
3
```

---

## 🧩 7. Структура проекта

```
dz1/
│
├── Dockerfile
├── docker-compose.yml
├── conf/
├── run_hw.sh
├── Readme.md
├── README.md
├── entrypoint.sh
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── yarn-site.xml
│   ├── mapred-site.xml
│   └── hadoop-env.sh
├── data/
│   └── shadow.txt

```

---

## 🏁 Итог

✅ Все компоненты Hadoop успешно развернуты в Docker.  
✅ MapReduce-задача WordCount выполнена через YARN.  
✅ Подсчитано количество вхождений слова **Innsmouth = 3**.  
✅ Все результаты доступны в HDFS.
