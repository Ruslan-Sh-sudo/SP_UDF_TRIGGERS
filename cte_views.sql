  CREATE VIEW vPerson 
      AS SELECT p.title, p.firstname, p.lastname, e.emailaddress
    FROM person.person p
    JOIN person.emailaddress e
      ON (p.businessentityid = e.businessentityid)
ORDER BY p.title;

  WITH person_data AS (
SELECT p.businessentityid, p.firstname, p.lastname, ph.phonenumber
  FROM person.person p
  JOIN person.personphone ph 
    ON p.businessentityid = ph.businessentityid
     )
SELECT e.businessentityid, firstname, lastname, phonenumber, e.jobtitle, e.nationalidnumber
  FROM person_data pd
  JOIN humanresources.employee e
    ON e.businessentityid = pd.businessentityid;