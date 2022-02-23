  /*
  Выбрать названия и количество групп из таблицы HumanResources.Department
  */

  SELECT groupname, COUNT(*) AS quantity
    FROM humanresources.department
GROUP BY groupname;

 /*
  Найти максимальную ставку для каждого сотрудника из таблиц HumanResources.EmployeePayHistory, 
  HumanResources.Employee
 */

  SELECT e.jobtitle, MAX(ep.rate) AS highest_rate
    FROM humanresources.employee e
    JOIN humanresources.employeepayhistory ep
	    ON e.businessentityid = ep.businessentityid
GROUP BY e.jobtitle;

 /*
  Выбрать минимальную цену единицы товара по подкатегориям 
  (названия из таблицы PRODUCTION.PRODUCTSUBCATEGORY, минимальная цена из таблицы SALES.SALESORDERDETAIL) 
  используя таблицы:
  Sales.SalesOrderHeader, 
  Sales.SalesOrderDetail, 
  Production.Product, 
  Production.ProductSubcategory
 */

   SELECT psub.name, MIN(unitprice) AS min_group_price
     FROM (
   SELECT name, unitprice, productsubcategoryid
     FROM sales.salesorderdetail sd
     JOIN production.product pr
       ON pr.productid = sd.productid
          ) AS pricelist
     JOIN production.productsubcategory psub
       ON psub.productsubcategoryid = pricelist.productsubcategoryid
 GROUP BY psub.name;

 /*
  Вычислить название и количество подкатегорий товара в каждой категории, 
  используя таблицы: 
  Production.ProductCategory, 
  Production.ProductSubcategory
 */

  SELECT psub.name, COUNT(pr.name) AS subcategories
    FROM production.productsubcategory psub
    JOIN production.product pr
      ON psub.productsubcategoryid = pr.productsubcategoryid
GROUP BY psub.name;

 /*
  Вывести среднюю сумму заказа по подкатегориям товаров, 
  используя таблицы: 
  Sales.SalesOrderHeader, 
  Sales.SalesOrderDetail, 
  Production.Product, 
  Production.ProductSubcategory
 */

  SELECT psub.name, AVG(totaldue) AS avg_subcat_sum
    FROM (SELECT name, totaldue, productsubcategoryid
            FROM (
          SELECT totaldue, productid
            FROM sales.salesorderheader soh
            JOIN sales.salesorderdetail sd
              ON soh.salesorderid = sd.salesorderid
                 ) AS totaldue
            JOIN production.product pr
              ON pr.productid = totaldue.productid) AS totaldue_subcat_id
    JOIN production.productsubcategory psub
      ON psub.productsubcategoryid = totaldue_subcat_id.productsubcategoryid
GROUP BY psub.name;

 /*
 Найти ID сотрудника с максимальным рейтом и дату назначения рейта, 
 используя таблицу HumanResources.EmployeePayHistory
 */

SELECT businessentityid, ratechangedate 
  FROM HumanResources.EmployeePayHistory
 WHERE rate = (
     SELECT MAX(rate) 
       FROM HumanResources.EmployeePayHistory
              );