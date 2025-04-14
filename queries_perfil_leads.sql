--1: Gênero dos leads
-- Colunas: gênero, leads
SELECT
    CASE
        WHEN i.gender = 'male' THEN 'homens'
        WHEN i.gender = 'female' THEN 'mulheres'
    END AS genero,
    COUNT(*) AS leads_count
FROM
    sales.customers AS c
LEFT JOIN
    temp_tables.ibge_genders AS i ON LOWER(c.first_name) = LOWER(i.first_name)
GROUP BY
    i.gender;


--2: Status profissional dos leads
-- Colunas: status profissional, leads (%)
WITH total_customers AS (
    SELECT COUNT(*) AS total
    FROM sales.customers
)
SELECT
    CASE
        WHEN professional_status = 'freelancer' THEN 'freelancer'
        WHEN professional_status = 'retired' THEN 'aposentado(a)'
        WHEN professional_status = 'clt' THEN 'clt'
        WHEN professional_status = 'self_employed' THEN 'autonomo(a)'
        WHEN professional_status = 'other' THEN 'outro'
        WHEN professional_status = 'businessman' THEN 'empresario(a)'
        WHEN professional_status = 'civil_servant' THEN 'funcionario(a) publico(a)'
        WHEN professional_status = 'student' THEN 'estudante'
    END AS status_profissional,
    COUNT(*) AS leads_count,
    COUNT(*)::FLOAT / total AS leads_percentage
FROM
    sales.customers, total_customers
GROUP BY
    professional_status, total
ORDER BY
    leads_count DESC;



--3: Faixa etária dos leads
-- Colunas: faixa etária, leads (%)
WITH total_customers AS (
    SELECT COUNT(*) AS total
    FROM sales.customers
)
SELECT
    CASE
        WHEN DATE_PART('year', AGE(birth_date)) < 20 THEN '0-20'
        WHEN DATE_PART('year', AGE(birth_date)) < 40 THEN '20-40'
        WHEN DATE_PART('year', AGE(birth_date)) < 60 THEN '40-60'
        WHEN DATE_PART('year', AGE(birth_date)) < 80 THEN '60-80'
        ELSE '80+'
    END AS faixa_etaria,
    COUNT(*) AS leads_count,
    COUNT(*)::FLOAT / total AS leads_percentage
FROM
    sales.customers, total_customers
GROUP BY
    faixa_etaria, total
ORDER BY
    faixa_etaria;



--4: Faixa salarial dos leads
-- Colunas: faixa salarial, leads count, leads (%), ordem
WITH total_customers AS (
    SELECT COUNT(*) AS total
    FROM sales.customers
)
SELECT
    CASE
        WHEN income < 5000 THEN '0-5000'
        WHEN income < 10000 THEN '5000-10000'
        WHEN income < 15000 THEN '10000-15000'
        WHEN income < 20000 THEN '15000-20000'
        ELSE '20000+'
    END AS faixa_salarial,
    COUNT(*) AS leads_count,
    COUNT(*)::FLOAT / total AS leads_percentage,
    CASE
        WHEN income < 5000 THEN 1
        WHEN income < 10000 THEN 2
        WHEN income < 15000 THEN 3
        WHEN income < 20000 THEN 4
        ELSE 5
    END AS ordem
FROM
    sales.customers, total_customers
GROUP BY
    faixa_salarial, ordem, total
ORDER BY
    ordem DESC;


-- 5: faixa de score dos leads
-- Colunas: faixa score, leads count, leads (%), ordem
WITH total_customers AS (
    SELECT COUNT(*) AS total
    FROM sales.customers
)
SELECT
    CASE
        WHEN score < 300 THEN 'Baixo'
        WHEN score < 500 THEN 'Medio'
        WHEN score < 700 THEN 'Bom'
        WHEN score >= 700 THEN 'Excelente'
        ELSE 'Nao classificado'
    END AS faixa_score,
    COUNT(*) AS leads_count,
    COUNT(*)::FLOAT / total AS leads_percentage
FROM
    sales.customers, total_customers
GROUP BY
    faixa_score, total
ORDER BY
    leads_count DESC;


--6: Classificação dos veículos visitados
-- Colunas: classificação do veículo, veículos visitados
-- Regra de negócio: Veículos novos tem até 2 anos e seminovos acima de 2 anos
WITH classificacao_veiculos AS (
    SELECT
        EXTRACT('year' FROM fun.visit_page_date) - pro.model_year::INT AS idade_veiculo,
        CASE
            WHEN EXTRACT('year' FROM fun.visit_page_date) - pro.model_year::INT <= 2 THEN 'novo'
            ELSE 'seminovo'
        END AS classificacao_veiculo
    FROM
        sales.funnel AS fun
    LEFT JOIN
        sales.products AS pro ON fun.product_id = pro.product_id
)
SELECT
    classificacao_veiculo,
    COUNT(*) AS veiculos_visitados_count
FROM
    classificacao_veiculos
GROUP BY
    classificacao_veiculo;

