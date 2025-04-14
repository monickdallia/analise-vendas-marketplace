--1:séries temporais de leads, vendas e receita, com taxa de conversão e ticket médio.
WITH
	monthly_leads AS (
	    SELECT
	        DATE_TRUNC('month', visit_page_date)::DATE AS visit_page_month,
	        COUNT(*) AS visit_page_count
	    FROM sales.funnel
	    GROUP BY visit_page_month
	),
	monthly_payments AS (
	    SELECT
	        DATE_TRUNC('month', fn.paid_date)::DATE AS payment_month,
	        COUNT(fn.paid_date) AS paid_count,
	        SUM(pr.price * (1 + fn.discount)) AS receita
	    FROM sales.funnel fn
	    LEFT JOIN sales.products pr ON fn.product_id = pr.product_id
	    WHERE fn.paid_date IS NOT NULL
	    GROUP BY payment_month
)
SELECT
    monthly_leads.visit_page_month AS "mes",
    monthly_leads.visit_page_count AS "leads",
    COALESCE(monthly_payments.paid_count, 0) AS "vendas",
    ROUND(COALESCE(monthly_payments.receita, 0)/1000, 3) AS "receita",
    ROUND((COALESCE(monthly_payments.paid_count, 0)::FLOAT / NULLIF(monthly_leads.visit_page_count, 0))::NUMERIC, 2) AS "conversao %",
    ROUND((COALESCE(monthly_payments.receita / NULLIF(monthly_payments.paid_count, 0), 0)/1000)::NUMERIC, 3) AS "ticket_medio_k"
FROM
    monthly_leads
LEFT JOIN
    monthly_payments
ON
    monthly_leads.visit_page_month = monthly_payments.payment_month;


--2: TOP 5 lojas nos últimos 3 meses
SELECT
    s.store_name AS loja,
    COUNT(f.paid_date) AS qt_vendas,
    ROUND(SUM(p.price * (1 + f.discount))/1000, 2) AS receita_k
FROM sales.stores s
LEFT JOIN sales.funnel f ON s.store_id = f.store_id
LEFT JOIN sales.products p ON f.product_id = p.product_id
WHERE f.paid_date BETWEEN '2021-06-01' AND '2021-08-31'
GROUP BY s.store_name
ORDER BY qt_vendas DESC
LIMIT 5;


--3: TOP 5 Estados que mais venderam nos últimos 3 meses
SELECT
    'Brazil' AS país,
    cus.state AS estado,
    COUNT(f.paid_date) AS "vendas"
FROM sales.funnel AS f
LEFT JOIN sales.customers AS cus
    ON f.customer_id = cus.customer_id
WHERE f.paid_date BETWEEN '2021-06-01' AND '2021-08-31'
GROUP BY país, estado
ORDER BY "vendas" DESC
LIMIT 5;


--5: TOP 5 Marcas que mais venderam nos últimos 3 meses
SELECT
    p.brand AS marca,
    COUNT(f.paid_date) AS "vendas (#)"
FROM sales.funnel AS f
LEFT JOIN sales.products AS p
    ON f.product_id = p.product_id
WHERE f.paid_date BETWEEN '2021-06-01' AND '2021-08-31'
GROUP BY marca
ORDER BY "vendas (#)" DESC
LIMIT 5;
 
  
--6: análise do funil de vendas
SELECT
  COUNT(*) FILTER (WHERE f.visit_page_date IS NOT NULL) AS visitas,
  COUNT(*) FILTER (WHERE f.add_to_cart_date IS NOT NULL) AS adicionaram_ao_carrinho,
  COUNT(*) FILTER (WHERE f.start_checkout_date IS NOT NULL) AS iniciaram_checkout,
  COUNT(*) FILTER (WHERE f.paid_date IS NOT NULL) AS compras,
  ROUND(COUNT(*) FILTER (WHERE f.add_to_cart_date IS NOT NULL)::DECIMAL / 
        NULLIF(COUNT(*) FILTER (WHERE f.visit_page_date IS NOT NULL), 0), 2) AS taxa_carrinho,
  ROUND(COUNT(*) FILTER (WHERE f.start_checkout_date IS NOT NULL)::DECIMAL / 
        NULLIF(COUNT(*) FILTER (WHERE f.add_to_cart_date IS NOT NULL), 0), 2) AS taxa_checkout,
  ROUND(COUNT(*) FILTER (WHERE f.paid_date IS NOT NULL)::DECIMAL / 
        NULLIF(COUNT(*) FILTER (WHERE f.start_checkout_date IS NOT NULL), 0), 2) AS taxa_compra
FROM sales.funnel AS f;
