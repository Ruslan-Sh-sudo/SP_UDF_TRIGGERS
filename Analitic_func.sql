    /*
    Задание 1
    Найти сумму продаж за месяц по каждому продукту, 
    проданному в январе-2013 года. 
    Вывести итоговый список продуктов без первых и последних 10% списка, 
    используя следующие таблицы:
    Sales.SalesOrderHeader
    Sales.SalesOrderDetail
    Production.Product
    */

    SELECT DISTINCT name,
       SUM (unitprice) OVER (PARTITION BY name) AS sumtotal
      FROM (
    SELECT name, unitprice FROM(
    SELECT pr.name, dateprice.unitprice, CUME_DIST() OVER (ORDER BY dateprice.unitprice) AS cume_dist
      FROM Production.Product pr
 LEFT JOIN (SELECT sd.productid, sh.orderdate, sd.unitprice
      FROM Sales.SalesOrderHeader sh
 LEFT JOIN Sales.SalesOrderDetail sd
        ON sh.salesorderid = sd.salesorderid
     WHERE sh.orderdate BETWEEN '2013-01-01' AND '2013-01-31') AS dateprice
        ON pr.productid = dateprice.productid
     WHERE dateprice.orderdate IS NOT NULL
  ORDER BY pr.name) AS jan_sold
     WHERE cume_dist BETWEEN 0.1 AND 0.9) AS sorted_sells;



      /*
      Задание 2
      Найти самые дешевые продукты в каждой субкатегории продуктов.
      Использовать таблицу Production.Product.
      */  

    SELECT DISTINCT name, 
       MIN (listprice) 
      OVER (PARTITION BY name) as listprice 
      FROM production.product WHERE listprice > 0 ORDER BY name;



      /*
      Задание 3
      Найти вторую по величине цену для горных велосипедов, 
      используя таблицу Production.Product
      */

    SELECT DISTINCT NTH_VALUE(listprice, 2) OVER() AS listprice FROM
   (SELECT DISTINCT listprice 
      FROM production.product 
     WHERE name LIKE 'Mountain-%' order by listprice desc) AS listprice;



      /*
      Задание 4
      Посчитать продажи за 2013 год в разрезе категорий(“YoY метрика”):  
      (продажи - продажи за прошлый год) продажи
      используя таблицы:
      Sales.SalesOrderHeader
      Sales.SalesOrderDetail
      Production.Product
      Production.ProductSubcategory
      Production.ProductCategory  
      */

SELECT category, current_sales, (current_sales - prev_year_sales) / current_sales AS YoY
  FROM (
SELECT EXTRACT (YEAR FROM (soh.orderdate)) AS year_of_order,
       cat.name AS category,
   SUM (sod.linetotal) AS current_sales,
   LAG (SUM (sod.linetotal)) OVER (ORDER BY cat.name, EXTRACT (YEAR FROM(soh.orderdate))) AS prev_year_sales
  FROM sales.salesorderheader soh
 INNER JOIN sales.salesorderdetail sod
    ON soh.salesorderid = sod.salesorderid
 INNER JOIN production.product pr
    ON sod.productid = pr.productid
 INNER JOIN production.productsubcategory psub
    ON pr.productsubcategoryid = psub.productsubcategoryid
 INNER JOIN production.productcategory cat
    ON psub.productcategoryid = cat.productcategoryid
 WHERE soh.orderdate >= '2012-01-01' 
   AND soh.orderdate < '2014-01-01'
 GROUP BY year_of_order, cat.name) AS main
 WHERE year_of_order = 2013;



       /*
       Задание 5
       Найти сумму максимальную заказа за каждый день января 2013, используя таблицы:
       Sales.SalesOrderHeader
       Sales.SalesOrderDetail 
       */

SELECT DISTINCT orderdate, MAX(linetotal) 
  OVER (PARTITION BY orderdate)
  FROM (
SELECT orderdate, linetotal
  FROM (sales.salesorderheader soh
 INNER JOIN sales.salesorderdetail sod
    ON soh.salesorderid = sod.salesorderid)
 WHERE orderdate >= '2013-01-01'
   AND orderdate < '2013-02-01') AS jan_sells
 ORDER BY orderdate;



        /*
        Задание 6
        Найти товар, который чаще всего продавался в каждой из субкатегорий в январе 2013, используя таблицы:
        Sales.SalesOrderHeader
        Sales.SalesOrderDetail
        Production.Product
        Production.ProductSubcategory
        */
SELECT DISTINCT psub.name, 
 FIRST_VALUE (pr.name) OVER (PARTITION BY psub.name ORDER BY COUNT (*) DESC)
  FROM sales.salesorderheader soh
 INNER JOIN sales.salesorderdetail sod
    ON soh.salesorderid = sod.salesorderid
 INNER JOIN production.product pr
    ON sod.productid = pr.productid
 INNER JOIN production.productsubcategory psub
    ON pr.productsubcategoryid = psub.productsubcategoryid
 WHERE soh.orderdate >= '2013-01-01' AND
       soh.orderdate < '2013-02-01'
 GROUP BY psub.name, pr.name
 ORDER BY psub.name;
