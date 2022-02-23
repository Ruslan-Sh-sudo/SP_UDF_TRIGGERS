  SELECT groupname, COUNT(*) AS quantity
    FROM humanresources.department
GROUP BY groupname;

  SELECT e.jobtitle, MAX(ep.rate) AS highest_rate
    FROM humanresources.employee e
    JOIN humanresources.employeepayhistory ep
	    ON e.businessentityid = ep.businessentityid
GROUP BY e.jobtitle;

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

  SELECT psub.name, COUNT(pr.name) AS subcategories
    FROM production.productsubcategory psub
    JOIN production.product pr
      ON psub.productsubcategoryid = pr.productsubcategoryid
GROUP BY psub.name;

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

SELECT businessentityid, ratechangedate 
  FROM HumanResources.EmployeePayHistory
 WHERE rate = (
     SELECT MAX(rate) 
       FROM HumanResources.EmployeePayHistory
              );