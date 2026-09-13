#create data
CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,7),
    geolocation_lng DECIMAL(10,7),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);
CREATE TABLE orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

CREATE TABLE reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT
);

CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100)
);
CREATE TABLE sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);
CREATE TABLE category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);



LOAD DATA LOCAL INFILE "D:\\olist_sales\\product_category_name_translation.csv"
INTO TABLE category_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

##################################################
#category_translation table (check dublicates)
SELECT product_category_name_english, COUNT(*) AS count
FROM category_translation
GROUP BY product_category_name_english
HAVING COUNT(*) > 1;

#check nulls
select * from category_translation
where product_category_name is null or product_category_name_english is null;

#check whether each product has it's translation in translation tabel and the opposite
SELECT DISTINCT ct.product_category_name
FROM category_translation ct
LEFT JOIN products p
    ON ct.product_category_name = p.product_category_name
WHERE p.product_category_name IS NULL;
     
SELECT distinct p.product_category_name
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL;
  
  #count to check if theey are dummy data  or not
  select count(product_category_name),product_category_name from products
  where product_category_name like "portateis_cozinha_e_preparadores_de_alimentos" or product_category_name like "pc_gamer"
  group by product_category_name;
  

#insert them
INSERT INTO category_translation
    (product_category_name, product_category_name_english)
VALUES
    ('pc_gamer', 'gaming_pc'),
    ('portateis_cozinha_e_preparadores_de_alimentos',
     'kitchen_and_food_preparers');
     
	################################################################
     #product table (check duplicates)alter
     select product_id , count(*) as total from products
     group by product_id
     having count(*) >1
     ;
     
     #null and empty
	 select * from products
     where product_category_name is null or product_id is null;
     
     select * from products
     where product_category_name="" or product_id="";
     
	# is every product_id in items exist in product?
     select o.product_id from order_items as o
     left join products as p
     on o.product_id=p.product_id
     where o.product_id is not null
     and p.product_id is null;
     #################################################
     
     SHOW FULL COLUMNS FROM geolocation;
     SELECT 
    'São Paulo' = 'Sao Paulo' AS is_same;
    
ALTER TABLE geolocation
ADD COLUMN geolocation_city_clean VARCHAR(100);

UPDATE geolocation
SET geolocation_city_clean = geolocation_city;

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'á', 'a');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'à', 'a');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'â', 'a');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'ã', 'a');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'é', 'e');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'ê', 'e');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'í', 'i');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'ó', 'o');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'ô', 'o');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'õ', 'o');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'ú', 'u');

UPDATE geolocation
SET geolocation_city_clean = REPLACE(geolocation_city_clean, 'ç', 'c');
select * from geolocation;


ALTER TABLE geolocation
ADD COLUMN row_num int;

insert into geolocation
select *,  ROW_NUMBER() OVER(
partition by 
geolocation_zip_code_prefix,
geolocation_lat,
geolocation_lng,
geolocation_city_clean,
geolocation_state) AS row_num
from geolocation; 

alter table geolocation
drop column row_num; 

CREATE TABLE geolocation_check AS
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY
               geolocation_zip_code_prefix,
               geolocation_lat,
               geolocation_lng,
               geolocation_city_clean,
               geolocation_state
       ) AS row_num
FROM geolocation;

SELECT COUNT(*) AS duplicate_rows
FROM geolocation_check
WHERE row_num > 1;
;

SELECT COUNT(*) FROM geolocation_check;

UPDATE geolocation_check
SET geolocation_city_clean = 'santa barbara d oeste'
WHERE geolocation_city_clean IN (
    'santa barbara d''oeste',
    'santa barbara d´oeste',
    'santa barbara doeste',
    'santa barbara d`oeste'
);

SELECT geolocation_city, geolocation_city_clean
FROM geolocation
WHERE geolocation_city_clean LIKE 'santa barbara%';

SELECT COUNT(*) AS rows_to_remove
FROM geolocation_check
WHERE row_num > 1;

DELETE FROM geolocation_check
WHERE row_num > 1;
#######################################
#seller
select s.seller_city from geolocation as g
right join sellers as s 
on s.seller_city=g.geolocation_city_clean
where s.seller_city is not null
and g.geolocation_city is null;

/*lages - sc
balenario camboriu
ferraz de  vasconcelos
auriflama/sp
sao paulo / sao paulo
vicente de carvalho
sao pauo
bahia
cascavael
santa barbara d´oeste
04482255
novo hamburgo, rio grande do sul, brasil
floranopolis
sao  jose dos pinhais
cariacica / es
sao miguel d'oeste
brasilia df
mogi das cruses
sao paulo - sp
sbc/sp
arraial d'ajuda (porto seguro)
santo andre/sao paulo
s jose do rio preto
sp / sp
juzeiro do norte
santa catarina
maua/sao paulo
sao bernardo do capo
mogi das cruzes / sp
rio de janeiro 
io de janeiro
sao jose dos pinhas
barbacena/ minas gerais
paincandu
portoferreira
sao paulo - sp
belo horizont
andira-pr
sao paulo sp
rio de janeiro / rio de janeiro
sando andre
angra dos reis rj
sao  paulo
pinhais/pr
ao bernardo do campo
castro pires
sbc
garulhos
ribeirao preto / sao paulo
sao jose do rio pret
sao paluo
ji parana
carapicuiba / sao paulo
centro
vendas@creditparts.com.br
sao paulop
santa barbara d´oeste
minas gerais
scao jose do rio pardo
aguas claras df
ribeirao pretp
sao sebastiao da grama/sp
robeirao preto
tabao da serra
sao paulo - sp
jacarei / sao paulo
riberao preto*/

UPDATE sellers
SET seller_city = CASE seller_city

    WHEN 'lages - sc' THEN 'lages'
    WHEN 'balenario camboriu' THEN 'balneario camboriu'
    WHEN 'ferraz de  vasconcelos' THEN 'ferraz de vasconcelos'
    WHEN 'auriflama/sp' THEN 'auriflama'
    WHEN 'sao paulo / sao paulo' THEN 'sao paulo'
    WHEN 'sao pauo' THEN 'sao paulo'
    WHEN 'bahia' THEN NULL
    WHEN 'cascavael' THEN 'cascavel'
    WHEN 'santa barbara d´oeste' THEN 'santa barbara d oeste'
    WHEN '04482255' THEN NULL
    WHEN 'novo hamburgo, rio grande do sul, brasil' THEN 'novo hamburgo'
    WHEN 'floranopolis' THEN 'florianopolis'
    WHEN 'sao  jose dos pinhais' THEN 'sao jose dos pinhais'
    WHEN 'cariacica / es' THEN 'cariacica'
    WHEN 'sao miguel d''oeste' THEN 'sao miguel d oeste'
    WHEN 'brasilia df' THEN 'brasilia'
    WHEN 'mogi das cruses' THEN 'mogi das cruzes'
    WHEN 'sao paulo - sp' THEN 'sao paulo'
    WHEN 'sbc/sp' THEN 'sao bernardo do campo'
    WHEN 'arraial d''ajuda (porto seguro)' THEN 'porto seguro'
    WHEN 'santo andre/sao paulo' THEN 'santo andre'
    WHEN 's jose do rio preto' THEN 'sao jose do rio preto'
    WHEN 'sp / sp' THEN 'sp'
    WHEN 'juzeiro do norte' THEN 'juazeiro do norte'
    WHEN 'santa catarina' THEN NULL
    WHEN 'maua/sao paulo' THEN 'maua'
    WHEN 'sao bernardo do capo' THEN 'sao bernardo do campo'
    WHEN 'mogi das cruzes / sp' THEN 'mogi das cruzes'
    WHEN 'rio de janeiro ' THEN 'rio de janeiro'
    WHEN 'io de janeiro' THEN 'rio de janeiro'
    WHEN 'sao jose dos pinhas' THEN 'sao jose dos pinhais'
    WHEN 'barbacena/ minas gerais' THEN 'barbacena'
    WHEN 'paincandu' THEN 'paicandu'
    WHEN 'portoferreira' THEN 'porto ferreira'
    WHEN 'belo horizont' THEN 'belo horizonte'
    WHEN 'andira-pr' THEN 'andira'
    WHEN 'sao paulo sp' THEN 'sao paulo'
    WHEN 'rio de janeiro / rio de janeiro' THEN 'rio de janeiro'
    WHEN 'sando andre' THEN 'santo andre'
    WHEN 'angra dos reis rj' THEN 'angra dos reis'
    WHEN 'sao  paulo' THEN 'sao paulo'
    WHEN 'pinhais/pr' THEN 'pinhais'
    WHEN 'ao bernardo do campo' THEN 'sao bernardo do campo'
    WHEN 'sbc' THEN 'sao bernardo do campo'
    WHEN 'garulhos' THEN 'guarulhos'
    WHEN 'ribeirao preto / sao paulo' THEN 'ribeirao preto'
    WHEN 'sao jose do rio pret' THEN 'sao jose do rio preto'
    WHEN 'sao paluo' THEN 'sao paulo'
    WHEN 'ji parana' THEN 'ji parana'
    WHEN 'carapicuiba / sao paulo' THEN 'carapicuiba'
    WHEN 'centro' THEN NULL
    WHEN 'vendas@creditparts.com.br' THEN NULL
    WHEN 'sao paulop' THEN 'sao paulo'
    WHEN 'minas gerais' THEN NULL
    WHEN 'scao jose do rio pardo' THEN 'sao jose do rio pardo'
    WHEN 'aguas claras df' THEN 'aguas claras'
    WHEN 'ribeirao pretp' THEN 'ribeirao preto'
    WHEN 'sao sebastiao da grama/sp' THEN 'sao sebastiao da grama'
    WHEN 'robeirao preto' THEN 'ribeirao preto'
    WHEN 'tabao da serra' THEN 'tabao da serra'
    WHEN 'jacarei / sao paulo' THEN 'jacarei'
    WHEN 'riberao preto*/' THEN 'ribeirao preto'

    ELSE seller_city
END;

UPDATE sellers
SET seller_city = CASE seller_city

    WHEN 'rio de janeiro io de janeiro'
        THEN 'rio de janeiro'

    WHEN 'santa barbara d''oeste'
        THEN 'santa barbara d oeste'

    WHEN 'riberao preto'
        THEN 'ribeirao preto'

    ELSE seller_city

END;

UPDATE geolocation
SET geolocation_city_clean = 'rio de janeiro'
WHERE REPLACE(TRIM(geolocation_city_clean), ' ', '') 
LIKE '%riodejaneiroriodejaneiro%';

UPDATE geolocation
SET geolocation_city_clean = 'rio de janeiro'
WHERE TRIM(geolocation_city_clean)
LIKE 'rio de janeiro, rio de janeiro, brasil%';

      
      select distinct geolocation_city_clean from geolocation
where geolocation_city like "sao bernardo do campo";
#s jose do rio preto

select count(distinct seller_id) from sellers; # no duplicates
# 
select * from sellers;

select * from geolocation_check
where geolocation_zip_code_prefix=37165;

select * from sellers
where seller_zip_code_prefix=37165;


update sellers
set seller_city='campo do meio'
where seller_zip_code_prefix=37165;
######################################################
# customer
SELECT DISTINCT c.customer_city
FROM customers AS c
WHERE c.customer_city IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM geolocation AS g
      WHERE g.geolocation_city_clean = c.customer_city
  );
  
  
/*
nucleo residencial pilar
glaura
nossa senhora do remedio
maioba
monnerat
bom jesus do querendo
cipo-guacu
sao francisco do humaita
cuite velho
angelo frechiani
domiciano ribeiro
bemposta
palmeirinha
polo petroquimico de triunfo
mampituba
passagem
sao vitor
sao sebastiao da serra
mussurepe
caldas do jorro
estevao de araujo
aribice
doce grande
piacu
colonia jordaozinho
missi
itabi
perola independente
taboquinhas
bora
humildes
ibitioca
alto sao joao
sambaiba
jaguarembe
santo eduardo
major porto
conceicao do formoso
guinda
poco de pedra
sao clemente
pinhotiba
ajapi
guariroba
jaua
sao miguel do cambui
pitanga de estrada
palmital de minas
sao sebastiao do paraiba
siriji*/

select distinct geolocation_city_clean from geolocation_check;

SELECT
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,
    g.geolocation_city_clean,
    COUNT(*) AS total
FROM customers c
JOIN geolocation g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
   AND c.customer_state = g.geolocation_state
WHERE c.customer_city IN (
    'nucleo residencial pilar',
    'glaura',
    'nossa senhora do remedio',
    'maioba',
    'monnerat',
    'bom jesus do querendo',
    'cipo-guacu',
    'sao francisco do humaita',
    'cuite velho',
    'angelo frechiani',
    'domiciano ribeiro',
    'bemposta',
    'palmeirinha',
    'polo petroquimico de triunfo',
    'mampituba',
    'passagem',
    'sao vitor',
    'sao sebastiao da serra',
    'mussurepe',
    'caldas do jorro',
    'estevao de araujo',
    'aribice',
    'doce grande',
    'piacu',
    'colonia jordaozinho',
    'missi',
    'itabi',
    'perola independente',
    'taboquinhas',
    'bora',
    'humildes',
    'ibitioca',
    'alto sao joao',
    'sambaiba',
    'jaguarembe',
    'santo eduardo',
    'major porto',
    'conceicao do formoso',
    'guinda',
    'poco de pedra',
    'sao clemente',
    'pinhotiba',
    'ajapi',
    'guariroba',
    'jaua',
    'sao miguel do cambui',
    'pitanga de estrada',
    'palmital de minas',
    'sao sebastiao do paraiba',
    'siriji'
)
GROUP BY
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,
    g.geolocation_city_clean
ORDER BY
    c.customer_state,
    c.customer_city;
    
UPDATE customers
SET customer_city= CASE

    WHEN customer_city = 'caldas do jorro'
        AND customer_state = 'BA'
        THEN 'tucano'

    WHEN customer_city = 'nucleo residencial pilar'
        AND customer_state = 'BA'
        THEN 'jaguarari'

    WHEN customer_city = 'taboquinhas'
        AND customer_state = 'BA'
        THEN 'itacare'

    WHEN customer_city = 'piacu'
        AND customer_state = 'ES'
        THEN 'muniz freire'

    WHEN customer_city = 'mussurepe'
        AND customer_state = 'RJ'
        THEN 'campos dos goytacazes'

    WHEN customer_city = 'ajapi'
        AND customer_state = 'SP'
        THEN 'rio claro'

    WHEN customer_city = 'guariroba'
        AND customer_state = 'SP'
        THEN 'taquaritinga'

    ELSE customer_city

END;


SELECT
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,
    g.geolocation_city_clean,
    COUNT(*) AS total
FROM customers c
LEFT JOIN geolocation g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
   AND c.customer_state = g.geolocation_state
WHERE c.customer_city IN (
    'sao sebastiao da serra',
    'estevao de araujo',
    'aribice',
    'doce grande',
    'colonia jordaozinho',
    'missi',
    'itabi',
    'perola independente',
    'bora',
    'humildes',
    'ibitioca',
    'alto sao joao',
    'sambaiba',
    'jaguarembe',
    'santo eduardo',
    'major porto',
    'conceicao do formoso',
    'guinda',
    'poco de pedra',
    'sao clemente',
    'pinhotiba',
    'jaua',
    'sao miguel do cambui',
    'pitanga de estrada',
    'palmital de minas',
    'sao sebastiao do paraiba',
    'siriji'
)
GROUP BY
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,
    g.geolocation_city_clean
ORDER BY
    c.customer_state,
    c.customer_city;
    
    
    UPDATE customers
SET customer_city = CASE

    WHEN customer_city = 'estevao de araujo'
        AND customer_state = 'MG'
        THEN 'araponga'

    WHEN customer_city = 'guinda'
        AND customer_state = 'MG'
        THEN 'diamantina'

    WHEN customer_city = 'major porto'
        AND customer_state = 'MG'
        THEN 'patos de minas'

    WHEN customer_city = 'palmital de minas'
        AND customer_state = 'MG'
        THEN 'cabeceira grande'

    WHEN customer_city = 'pinhotiba'
        AND customer_state = 'MG'
        THEN 'eugenopolis'

    WHEN customer_city = 'doce grande'
        AND customer_state = 'PR'
        THEN 'quitandinha'

    WHEN customer_city = 'perola independente'
        AND customer_state = 'PR'
        THEN 'maripa'

    WHEN customer_city = 'alto sao joao'
        AND customer_state = 'PR'
        THEN 'roncador'

    WHEN customer_city = 'siriji'
        AND customer_state = 'PE'
        THEN 'sao vicente ferrer'

    WHEN customer_city = 'poco de pedra'
        AND customer_state = 'RN'
        THEN 'sao goncalo do amarante'

    WHEN customer_city = 'bora'
        AND customer_state = 'SP'
        THEN 'bora'

    WHEN customer_city = 'sao sebastiao da serra'
        AND customer_state = 'SP'
        THEN 'sao sebastiao da serra'

    ELSE customer_city
END;

SELECT
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,
    g.geolocation_city_clean,
    COUNT(*) AS total
FROM customers c
LEFT JOIN geolocation g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
   AND c.customer_state = g.geolocation_state
WHERE c.customer_city IN (
    'glaura',
    'nossa senhora do remedio',
    'maioba',
    'monnerat',
    'santa barbara d''oeste',
    'bom jesus do querendo',
    'cipo-guacu',
    'sao francisco do humaita',
    'cuite velho',
    'angelo frechiani',
    'domiciano ribeiro',
    'bemposta',
    'palmeirinha',
    'polo petroquimico de triunfo',
    'mampituba',
    'passagem',
    'sao vitor',
    'sao sebastiao da serra',
    'aribice',
    'colonia jordaozinho',
    'missi',
    'itabi',
    'bora',
    'humildes',
    'ibitioca',
    'sambaiba',
    'jaguarembe',
    'santo eduardo',
    'conceicao do formoso',
    'sao clemente',
    'jaua',
    'sao miguel do cambui',
    'pitanga de estrada',
    'sao sebastiao do paraiba'
)
GROUP BY
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,
    g.geolocation_city_clean
ORDER BY
    c.customer_state,
    c.customer_city;
    
    
    UPDATE customers
SET customer_city = CASE

    WHEN customer_city = 'glaura'
        AND customer_state = 'MG'
        THEN 'ouro preto'

    WHEN customer_city = 'nossa senhora do remedio'
        AND customer_state = 'SP'
        THEN 'salesopolis'

    WHEN customer_city = 'monnerat'
        AND customer_state = 'RJ'
        THEN 'duas barras'

    WHEN customer_city = 'santa barbara d''oeste'
        AND customer_state = 'SP'
        THEN 'santa barbara d oeste'

    WHEN customer_city = 'bom jesus do querendo'
        AND customer_state = 'RJ'
        THEN 'natividade'

    WHEN customer_city = 'cipo-guacu'
        AND customer_state = 'SP'
        THEN 'embu-guacu'

    WHEN customer_city = 'sao francisco do humaita'
        AND customer_state = 'MG'
        THEN 'mutum'

    WHEN customer_city = 'cuite velho'
        AND customer_state = 'MG'
        THEN 'conselheiro pena'

    WHEN customer_city = 'angelo frechiani'
        AND customer_state = 'ES'
        THEN 'colatina'

    WHEN customer_city = 'domiciano ribeiro'
        AND customer_state = 'GO'
        THEN 'ipameri'

    WHEN customer_city = 'bemposta'
        AND customer_state = 'RJ'
        THEN 'tres rios'

    WHEN customer_city = 'palmeirinha'
        AND customer_state = 'PR'
        THEN 'guarapuava'

    WHEN customer_city = 'polo petroquimico de triunfo'
        AND customer_state = 'RS'
        THEN 'triunfo'

    WHEN customer_city = 'passagem'
        AND customer_state = 'PB'
        THEN 'passagem'

    WHEN customer_city = 'sao vitor'
        AND customer_state = 'MG'
        THEN 'governador valadares'

    WHEN customer_city = 'itabi'
        AND customer_state = 'SE'
        THEN 'itabi'

    WHEN customer_city = 'bora'
        AND customer_state = 'SP'
        THEN 'bora'

    WHEN customer_city = 'sambaiba'
        AND customer_state = 'MA'
        THEN 'sambaiba'

    WHEN customer_city = 'mampituba'
        AND customer_state = 'RS'
        THEN 'mampituba'

    WHEN customer_city = 'ibitioca'
        AND customer_state = 'RJ'
        THEN 'campos dos goytacazes'

    WHEN customer_city = 'jaguarembe'
        AND customer_state = 'RJ'
        THEN 'itaocara'

    WHEN customer_city = 'santo eduardo'
        AND customer_state = 'RJ'
        THEN 'campos dos goytacazes'

    WHEN customer_city = 'conceicao do formoso'
        AND customer_state = 'MG'
        THEN 'santos dumont'

    WHEN customer_city = 'pitanga de estrada'
        AND customer_state = 'PB'
        THEN 'mamanguape'

    WHEN customer_city = 'sao sebastiao da serra'
        AND customer_state = 'SP'
        THEN 'brotas'

    ELSE customer_city
END;

SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(customer_unique_id IS NULL) AS null_customer_unique_id,
    SUM(customer_zip_code_prefix IS NULL) AS null_zip,
    SUM(customer_city IS NULL) AS null_city,
    SUM(customer_state IS NULL) AS null_state
FROM customers;
#################################################
# reviews
select * from reviews;

SELECT DISTINCT r.order_id
FROM reviews as r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE r.order_id IS not NULL
and 
o.order_id is null;


DELETE FROM reviews
WHERE order_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM orders
      WHERE orders.order_id = reviews.order_id
  );
  
  
select * from reviews;
select count(*) from reviews;

delete from reviews
where order_id is null ;

SELECT *
FROM reviews
WHERE review_score < 1
   OR review_score > 5;
   
   CREATE TABLE reviews_order AS
SELECT
    order_id,
    COUNT(*) AS review_count,
    AVG(review_score) AS avg_review_score,
    MIN(review_score) AS min_review_score,
    MAX(review_score) AS max_review_score,
    COUNT(CASE WHEN review_score = 5 THEN 1 END) AS five_star_reviews,
    COUNT(CASE WHEN review_score <= 2 THEN 1 END) AS negative_reviews
FROM reviews
WHERE order_id IS NOT NULL
GROUP BY order_id;
DESCRIBE reviews;
DESCRIBE reviews_order;

SELECT review_score, COUNT(*) AS count1
FROM reviews
GROUP BY review_score
ORDER BY count1 desc;  #most reviews are 5 stars

select* from reviews_order
order by review_count desc;

###################################################
select * from orders;
##############################
select * from order_items;

select * FROM order_items
WHERE seller_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM sellers
      WHERE sellers.seller_id = order_items.seller_id
  );
  
  CREATE TABLE dim_geolocation_clean AS
SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat)  AS geolocation_lat,
    AVG(geolocation_lng)  AS geolocation_lng,
    MAX(geolocation_city_clean)  AS geolocation_city,
    MAX(geolocation_state) AS geolocation_state
FROM geolocation_check
GROUP BY geolocation_zip_code_prefix;


CREATE TABLE reviews_order_new AS
SELECT
    order_id,
    AVG(review_score) AS avg_review_score,
    MAX(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS has_negative_review
FROM reviews
WHERE order_id IS NOT NULL
GROUP BY order_id;

select count(order_id)from orders
where order_estimated_delivery_date like "%2018%"
;