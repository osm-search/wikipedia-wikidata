cat <<END | psql $DATABASE_NAME
SELECT
  C.relname as name,
  C.relkind,
  T.spcname AS tablespace,
  pg_size_pretty(sum(pg_relation_size(C.oid))) AS "total_size"
FROM pg_class C
LEFT JOIN pg_namespace  N ON (N.oid = C.relnamespace)
LEFT JOIN pg_tablespace T ON (T.oid = C.reltablespace)
WHERE
   C.relkind != 'v' AND
   C.relname NOT LIKE 'pg_%' AND C.relname NOT LIKE 'sql_%'
GROUP BY C.relname, C.relkind, tablespace
-- ORDER BY sum(pg_relation_size(C.oid)) DESC;
ORDER BY name;
END


cat <<END | psql $DATABASE_NAME
SELECT
  pg_size_pretty(sum(pg_relation_size(C.oid))) AS "total_size"
FROM pg_class C
LEFT JOIN pg_namespace  N ON (N.oid = C.relnamespace)
LEFT JOIN pg_tablespace T ON (T.oid = C.reltablespace)
WHERE
   C.relkind != 'v' AND
   C.relname NOT LIKE 'pg_%' AND C.relname NOT LIKE 'sql_%';
END
