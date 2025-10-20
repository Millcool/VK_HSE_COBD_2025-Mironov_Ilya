Все задачи выполняются в скрипте run_hw.sh
Я запускаю его с помощью команды
docker exec -it hadoop-master bash -lc "bash /opt/hadoop/run_hw.sh"

Первые 3 выполняются подряд и довольно быстро.

Задача №4 - проверка что все выполнилось:
docker exec -it hadoop-master bash -lc 'hdfs dfs -cat /tmp/wordcount_shadow/part-r-00000 | sed -n "1,200p"'

Вывод команды:
Big     1
Hadoop  2
MapReduce       1
YARN    1
clear   1
data    3
data.   2
examples        1
examples;       1
love    1
loves   1
small   2

Задание №5

Считывает результат и выводит количество слов Innsmouth

Вывод: 3