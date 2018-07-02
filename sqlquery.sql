SELECT
r2.nome,
r2.sobreposicao_geojson,
r2.pontos_geojson,
r2.proporcao,
ROUND(r3.pessoas_residentes * r2.proporcao) AS pessoas_residentes,
ROUND(r3.homens_residentes * r2.proporcao) AS homens_residentes,
ROUND(r3.mulheres_residentes * r2.proporcao) AS mulheres_residentes,
ROUND(r3.criancas_residentes * r2.proporcao) AS criancas_residentes,
ROUND(r3.jovens_residentes * r2.proporcao) AS jovens_residentes,
ROUND(r3.adultos_residentes * r2.proporcao) AS adultos_residentes,
ROUND(r3.idosos_residentes * r2.proporcao) AS idosos_residentes
FROM (
SELECT
r1.id_bairro,
r1.nome,
ST_AsGeoJSON(r1.sobreposicao) AS sobreposicao_geojson,
ST_AsGeoJSON(r1.ponto) AS pontos_geojson,
r1.area_sobreposicao / r1.area_bairro AS proporcao
FROM (
SELECT
b.id_bairro,
b.nome,
ST_Area(ST_Union(Geometry(ST_Transform(b.geom, 4326)))) AS area_bairro,
ST_Area(ST_Union(Geometry(ST_Intersection(Geography(ST_Transform(b.geom,
4326)), ST_Buffer(Geography(p.geom), {1}))))) AS area_sobreposicao,
ST_Union(Geometry(ST_Intersection(Geography(ST_Transform(b.geom, 4326)),
ST_Buffer(Geography(p.geom), {1})))) AS sobreposicao,
ST_Union(Geometry(Geography(p.geom))) as ponto
FROM bdg.bairros b, bdg.stops p
WHERE p.stop_id IN (SELECT stop_id FROM bdg.stop_times WHERE trip_id IN
(SELECT trip_id FROM bdg.trips WHERE route_id IN (SELECT route_id FROM
bdg.routes WHERE route_short_name = &#39;{0}&#39;)))
AND ST_Intersects(Geography(ST_Transform(b.geom, 4326)),
ST_Buffer(Geography(p.geom), {1}))
GROUP BY b.id_bairro, b.nome
) r1
) r2,
(
SELECT
c.id_bairro,
SUM(c.v014) AS pessoas_residentes,
SUM(c.v015) AS homens_residentes,
SUM(c.v016) AS mulheres_residentes,
SUM(c.V032 + c.V033 + c.V034 + c.V035 + c.V036 + c.V037 + c.V038 +
c.V039 + c.V040 + c.V041 + c.V042 + c.V043 + c.V044 + c.V045 + c.V046 +
c.V047) AS criancas_residentes,
SUM(c.V048 + c.V049 + c.V050 + c.V051 + c.V052 + c.V053 + c.V054 +
c.V055 + c.V056 + c.V057) AS jovens_residentes,
SUM(c.V058 + c.V059 + c.V060 + c.V061 + c.V062 + c.V063) AS
adultos_residentes,
SUM(c.V064 + c.V065 + c.V066 + c.V067 + c.V068 + c.V069 + c.V070 +
c.V071 + c.V072) AS idosos_residentes
FROM bdg.dados_censitarios c
GROUP BY c.id_bairro
) r3
WHERE r2.id_bairro = r3.id_bairro
ORDER BY r2.nome;
