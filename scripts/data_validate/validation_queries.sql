-- Module 8 live PostgreSQL validation queries.
-- Run against both source and target after restore and compare outputs.

SELECT 'owners' AS table_name, COUNT(*) AS row_count FROM owners
UNION ALL SELECT 'pets', COUNT(*) FROM pets
UNION ALL SELECT 'visits', COUNT(*) FROM visits
UNION ALL SELECT 'vets', COUNT(*) FROM vets
UNION ALL SELECT 'specialties', COUNT(*) FROM specialties
UNION ALL SELECT 'types', COUNT(*) FROM types
UNION ALL SELECT 'vet_specialties', COUNT(*) FROM vet_specialties
ORDER BY table_name;

SELECT 'owners' AS table_name, md5(string_agg(id || ':' || first_name || ':' || last_name || ':' || city, '|' ORDER BY id)) AS checksum FROM owners
UNION ALL SELECT 'pets', md5(string_agg(id || ':' || name || ':' || birth_date || ':' || type_id || ':' || owner_id, '|' ORDER BY id)) FROM pets
UNION ALL SELECT 'visits', md5(string_agg(id || ':' || pet_id || ':' || visit_date || ':' || description, '|' ORDER BY id)) FROM visits
UNION ALL SELECT 'vets', md5(string_agg(id || ':' || first_name || ':' || last_name, '|' ORDER BY id)) FROM vets
ORDER BY table_name;

SELECT 'pets_without_owner' AS check_name, COUNT(*) AS failures
FROM pets p
WHERE p.owner_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM owners o WHERE o.id = p.owner_id)
UNION ALL
SELECT 'pets_without_type', COUNT(*)
FROM pets p
WHERE NOT EXISTS (SELECT 1 FROM types t WHERE t.id = p.type_id)
UNION ALL
SELECT 'visits_without_pet', COUNT(*)
FROM visits v
WHERE v.pet_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pets p WHERE p.id = v.pet_id)
UNION ALL
SELECT 'vet_specialties_without_vet', COUNT(*)
FROM vet_specialties vs
WHERE NOT EXISTS (SELECT 1 FROM vets v WHERE v.id = vs.vet_id)
UNION ALL
SELECT 'vet_specialties_without_specialty', COUNT(*)
FROM vet_specialties vs
WHERE NOT EXISTS (SELECT 1 FROM specialties s WHERE s.id = vs.specialty_id);

SELECT 'owners_id_seq' AS sequence_name, MAX(id) AS max_id FROM owners
UNION ALL SELECT 'pets_id_seq', MAX(id) FROM pets
UNION ALL SELECT 'visits_id_seq', MAX(id) FROM visits
UNION ALL SELECT 'vets_id_seq', MAX(id) FROM vets
UNION ALL SELECT 'specialties_id_seq', MAX(id) FROM specialties
UNION ALL SELECT 'types_id_seq', MAX(id) FROM types;
