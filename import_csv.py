import csv
import psycopg2
from unidecode import unidecode


connection = psycopg2.connect(dbname='bdg', user='bdg', password='To3FCseT9A', host='guilhermeoliveira.eti.br')
cursor = connection.cursor()
cursor.execute('SELECT nome, id_bairro FROM bdg.bairros b ORDER BY nome;')

neighborhood_to_id_map = {}
for name, id_neighborhood in cursor.fetchall():
    neighborhood_to_id_map[unidecode(name).lower()] = id_neighborhood

cursor.close()
connection.close()

with open('censobh.csv', newline='', encoding='utf8') as csv_file:
    census_csv = csv.reader(csv_file, delimiter=',', quotechar="'")
    census_data = list(census_csv)

header = census_data[0]
found_neighborhood_set = set()
not_found_neighborhood_set = set()
queries_list = []

for row in census_data[1:]:
    try:
        neighborhood_name = unidecode(row[1]).lower()
        row[1] = neighborhood_to_id_map[neighborhood_name]
        found_neighborhood_set.add(neighborhood_name)

        select_query = 'SELECT '
        cols = []
        for i in range(len(row)):
            if i == 2 or i == 3:
                value = row[i] if row[i] else '-'
                cols.append("CAST('{}' AS varchar(100)) AS {}".format(value, header[i]))
            else:
                value = row[i] if row[i] else 0
                cols.append('{} AS {}'.format(value, header[i]))
        select_query += ', '.join(cols)
        queries_list.append(select_query)
    except KeyError:
        not_found_neighborhood_set.add(row[1])

with open('output.sql', 'w') as sql_file:
    sql_file.write('DROP TABLE IF EXISTS bdg.dados_censitarios;\n')
    sql_file.write('CREATE TABLE bdg.dados_censitarios AS ({});\n'.format(' UNION\n'.join(queries_list)))

# display unmatched neighborhoods
tmp = list(set(neighborhood_to_id_map.keys()) - found_neighborhood_set)
tmp.sort()
print(tmp)
print(len(tmp))

tmp = list(not_found_neighborhood_set)
tmp.sort()
print(tmp)
print(len(tmp))
