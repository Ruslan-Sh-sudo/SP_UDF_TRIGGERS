/* Завдання 1 
   Зная электронную почту сотрудника нужно получить
   его и имя и фамилию, а также его возраст.
*/

CREATE OR REPLACE FUNCTION shlyahov.get_info_by_email_task1(email character varying(100))
RETURNS varchar AS $$
SELECT firstname || ' ' || lastname || ' - ' || (date_part('year', current_date) - date_part('year', birthdate))
FROM person.person pp
INNER JOIN humanresources.employee hremp
ON pp.businessentityid = hremp.businessentityid
INNER JOIN person.emailaddress pmail
ON hremp.businessentityid = pmail.businessentityid
WHERE email = emailaddress;
$$ LANGUAGE SQL;


/* Завдання 2 
   Создать хранимую процедуру для обновления столбца make_flag 
   в таблице <your_lastname>.product, по столбцу name. 
   Замечание: Если для заданного продукта значение флага совпадает,
   вывести на экран  замечание “<YOUR_COMMENT_1>”. 
   Eсли такого продукта нет в таблице вывести “<YOUR_COMMENT_2>”.
*/

CREATE OR REPLACE PROCEDURE shlyahov.change_flag_func_task2 (pr_name varchar, make_flag boolean) 
LANGUAGE PLPGSQL
AS 
$$
DECLARE 
prd varchar;
flgvalue boolean;

BEGIN
   SELECT 
      INTO prd, flgvalue pr.name, pr.makeflag
   FROM shlyahov.product pr
      WHERE pr.name = pr_name;
      
   IF prd = pr_name AND flgvalue = make_flag
      THEN RAISE NOTICE 'This name exists but the flag is already in this position';
   END IF;
   
   IF prd is NULL
      THEN RAISE NOTICE 'This name does not exist in database. Check if the input is correct';
   END IF;
   
   IF prd = pr_name AND flgvalue != make_flag
      THEN UPDATE shlyahov.product SET makeflag = NOT makeflag;
   END IF;
END;
$$;


/* Завдання 3
   Создать хранимую процедуру для получения отчетов, которые записываются в таблицы.
ежедневные -  <your_lastname>.sales_report_total_daily 
месячные -  <your_lastname>.sales_report_total_monthly 
годовые -  <your_lastname>.sales_report_total_yearly
*/

CREATE OR REPLACE PROCEDURE shlyahov.get_d_m_y_report_task3(years_amount int) 
LANGUAGE PLPGSQL
AS
$$

DECLARE 

diff_years interval = years_amount::varchar || ' years';
last_year timestamp;

BEGIN 

TRUNCATE TABLE shlyahov.sales_report_total_daily;
TRUNCATE TABLE shlyahov.sales_report_total_monthly;
TRUNCATE TABLE shlyahov.sales_report_total_yearly;

SELECT DATE_TRUNC('year', (MIN(orderdate) + diff_years))
INTO last_year
FROM sales.salesorderheader;

INSERT INTO shlyahov.sales_report_total_daily
   (
      date_report,
      online_order_flag,
      sum_total,
      avg_total,
      qty_orders
   )
   
   SELECT DATE_TRUNC('day', orderdate) daily_sales,
         onlineorderflag,
         SUM(totaldue),
         AVG(totaldue),
         COUNT(*)
   FROM sales.salesorderheader
   WHERE DATE_TRUNC('day', orderdate) < last_year
   GROUP BY daily_sales, onlineorderflag
   ORDER BY daily_sales;
   
INSERT INTO shlyahov.sales_report_total_monthly
   (
      date_report,
      online_order_flag,
      sum_total,
      avg_total,
      qty_orders
   )
   
   SELECT DATE_TRUNC('month', orderdate) monthly_sales,
         onlineorderflag,
         SUM(totaldue),
         AVG(totaldue),
         COUNT(*)
   FROM sales.salesorderheader
   WHERE DATE_TRUNC('month', orderdate) < last_year
   GROUP BY monthly_sales, onlineorderflag
   ORDER BY monthly_sales;
    
INSERT INTO shlyahov.sales_report_total_yearly
   (
      date_report,
      online_order_flag,
      sum_total,
      avg_total,
      qty_orders
   )
   
   SELECT DATE_TRUNC('year', orderdate) yearly_sales,
         onlineorderflag,
         SUM(totaldue),
         AVG(totaldue),
         COUNT(*)
   FROM sales.salesorderheader
   WHERE DATE_TRUNC('year', orderdate) < last_year
   GROUP BY yearly_sales, onlineorderflag
   ORDER BY yearly_sales;
   
END;
$$;



/* Завдання 4
Создать пользовательскую функцию для определения лучших 
сотрудников продавшего товаров на большую сумму за отчетный период.
Учитываются только оффлайн заказы.
*/

CREATE OR REPLACE FUNCTION shlyahov.best_three_workers_task4(start_date date, end_date date)
RETURNS TABLE (
   employeeid int,
   firstname varchar(50),
   lastname varchar(50),
   rank int)
AS
$$
BEGIN 

IF start_date > end_date 
THEN RAISE EXCEPTION 'Start date can not be higher than end date';

ELSE RETURN QUERY WITH sort_table AS (
   SELECT p.businessentityid, p.firstname, p.lastname, SUM(soh.subtotal) sales, soh.orderdate
    FROM person.person p
    INNER JOIN sales.salesorderheader soh ON p.businessentityid = soh.salespersonid
    GROUP BY p.businessentityid, p.firstname, p.lastname, soh.onlineorderflag, soh.orderdate
    HAVING soh.onlineorderflag = 'false' AND (soh.orderdate BETWEEN start_date AND end_date))

SELECT * FROM (  
SELECT sort_table.businessentityid, sort_table.firstname :: varchar(50), sort_table.lastname :: varchar(50),
RANK() OVER (ORDER BY SUM(sales) DESC) :: int AS Rating
FROM sort_table
GROUP BY sort_table.businessentityid, sort_table.firstname, sort_table.lastname) AS t1
WHERE Rating < 4;
END IF;
END;
$$
LANGUAGE PLPGSQL;



/* Завдання 5
Создать функцию триггера и триггер для оформления заказа и добавления его в таблицы <your_lastname>.salesorderheader 
и <your_lastname>.salesorderdetail (триггер для этой таблицы с действиями(update,delete,insert)).
Менеджер добавляет товар в таблицу <your_lastname>.salesorderdetail после добавления каждого нового товара или удалении из этой таблицы, 
общая информация должна вставляться, удаляться или обновляться 
(обновляется только столбец totaldue = sum(totaline from <your_lastname>.salesorderdetail)) в таблице <your_lastname>.salesorderheader.
Если значение столбца totaline изменилось или строка была удалена нужно  
добавить или отнять это значение в totaldue. При удаления всех данных для одного заказа <your_lastname>.salesorderdetail. 
нужно удалить все данные в таблице <your_lastname>.salesorderheader для этого заказа.
*/

CREATE TRIGGER update_totaldue
AFTER UPDATE OR DELETE OR INSERT 
ON shlyahov.salesorderdetail FOR EACH ROW
EXECUTE FUNCTION manager_func();

CREATE OR REPLACE FUNCTION shlyahov.manager_func()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS
$$

DECLARE 
soh_id integer;
totaldue_diff numeric;

BEGIN

   IF TG_OP = 'DELETE' THEN
      UPDATE shlyahov.salesorderheader
      SET totaldue = totaldue - OLD.linetotal
      WHERE salesorderheader.salesorderid = OLD.salesorderid;
   
      SELECT totaldue INTO totaldue_diff
      FROM shlyahov.salesorderheader
      WHERE salesorderheader.salesorderid = OLD.salesorderid;
   
      IF totaldue_diff = 0.0 THEN
            DELETE FROM shlyahov.salesorderheader 
            WHERE salesorderheader.salesorderid = OLD.salesorderid;
      END IF;

   ELSIF TG_OP = 'UPDATE' THEN
      UPDATE shlyahov.salesorderheader 
      SET totaldue = totaldue - OLD.linetotal + NEW.linetotal
      WHERE salesorderheader.salesorderid = NEW.salesorderid;
   
   ELSIF TG_OP = 'INSERT' THEN 
      SELECT salesorderid INTO soh_id
      FROM shlyahov.salesorderheader
      WHERE salesorderheader.salesorderid = NEW.salesorderid;
   
      IF NOT FOUND THEN
         INSERT INTO shlyahov.salesorderheader
            (salesorderid, 
            orderdate, 
            customerid, 
            salespersonid, 
            creditcardid, 
            totaldue)
         VALUES 
            (NEW.salesorderid, 
            NEW.modifieddate, 
            NEW.customerid, 
            NEW.salespersonid, 
            NEW.creditcardid, 
            NEW.linetotal);
      ELSE 
         UPDATE shlyahov.salesorderheader 
         SET totaldue = totaldue + NEW.linetotal
         WHERE salesorderheader.salesorderid = NEW.salesorderid;
      END IF;
   END IF;
RETURN NULL;
END;
$$;