use Bank_churn;
-- Change the datatype 'bank_doj' to DATE 
SET SQL_SAFE_UPDATES = 0;

UPDATE customerinfo
SET bank_doj = STR_TO_DATE(bank_doj, '%d/%m/%Y');

-- Change the column type from VARCHAR to DATE
ALTER TABLE customerinfo
MODIFY COLUMN Bank_DOJ DATE;
#________________________________________________________________________________________________#
OBJECTIVE 1
SELECT 
    c.GeographyID,
    g.geographylocation,
    ROUND(SUM(ch.Balance), 2) AS Total_balance,
    ROUND(AVG(ch.Balance), 2) AS Average_balance,
    ROUND(MAX(ch.Balance), 2) AS Max_balance,
    ROUND(MIN(ch.Balance), 2) AS MIN_balance
FROM
    customerinfo c
        INNER JOIN
    geography g ON c.GeographyID = g.GeographyID
        LEFT JOIN
    Bank_churn ch ON c.CustomerId = ch.CustomerId
GROUP BY c.GeographyID , g.GeographyLocation;


-- OBJECTIVE 2) top 5 customers with the highest Estimated Salary in the last quarter of the year
SELECT 
    CustomerId, Surname, EstimatedSalary Highest_salary
FROM
    customerinfo
WHERE
    QUARTER(bank_doj) = 4
ORDER BY highest_salary DESC
LIMIT 5;
#________________________________________________________________________________________________#
-- OBJECTIVE 3) average number of products used by customers who have a credit card 
SELECT 
    AVG(NumOfProducts) avg_num_product_with_creditcard
FROM
    Bank_churn
WHERE
    HasCrCard = 1;
#________________________________________________________________________________________________#    
-- OBJECTIVE 4) churn rate by gender for the most recent year in the dataset;   
with
 most_recent_year AS (
select max(year(bank_doj)) recent_year from customerinfo) 

SELECT 
    gen.GenderCategory,
    (SUM(ch.Exited) / COUNT(*)) * 100.00 AS Churn_rate
FROM
    CustomerInfo c
        INNER JOIN
    Gender gen ON c.GenderID = gen.GenderID
        INNER JOIN
    Bank_Churn ch ON c.CustomerID = ch.CustomerID
WHERE
    YEAR(bank_doj) = (SELECT * FROM most_recent_year)
GROUP BY gen.GenderCategory;	
#________________________________________________________________________________________________#
-- OBJECTIVE 5) average credit score of customers who have exited and those who remain.

SELECT 
    ex.ExitCategory, AVG(ch.CreditScore) AS avg_credit_score
FROM
    Bank_churn ch
        INNER JOIN
    exitcustomer ex ON ch.Exited = ex.ExitID
GROUP BY ex.ExitCategory; 
#________________________________________________________________________________________________#

-- OBJECTIVE 6) gender has a higher average estimated salary.
WITH 
     ActiveAccounts AS(
SELECT CustomerId, COUNT(*) as ActiveAccounts
FROM bank_churn
WHERE IsActiveMember = 1
GROUP BY CustomerId
)
SELECT CASE when c.GenderID = 1 THEN "Male" else "Female" END AS Gender,
count(aa.CustomerID) AS ActiveAccounts, AVG(c.EstimatedSalary) AS AvgSalary
FROM customerinfo c
LEFT JOIN ActiveAccounts aa on c.CustomerID = aa.CustomerID
GROUP BY Gender
ORDER BY AvgSalary DESC;

#________________________________________________________________________________________________#
    
  -- OBJECTIVE  7) customers based on their credit score and identify the segment with the highest exit rate   
    WITH 
	Credit_segment AS (
SELECT 
		CASE 
			WHEN CreditScore >=800 THEN 'Excellent'
			WHEN CreditScore BETWEEN 740 AND 800 THEN 'Very good'
			WHEN CreditScore BETWEEN 670 AND 740 THEN 'Good'
			WHEN CreditScore BETWEEN 580 AND 670 THEN 'Fair'
			Else 'Poor' 
		END AS Credit_Score_segment,
		CASE 
			WHEN CreditScore >=800 THEN '>= 800 score'
			WHEN CreditScore BETWEEN 740 AND 800 THEN '740-799 score'
			WHEN CreditScore BETWEEN 670 AND 740 THEN '670-739 score'
			WHEN CreditScore BETWEEN 580 AND 670 THEN '580-669 score'
			Else '< 580 score' 
		END AS Credit_Score_range,        
		(SUM(Exited)/COUNT(*))*100.00 AS Exit_rate
FROM bank_churn
GROUP BY 1,2)
SELECT * 
FROM Credit_segment
ORDER BY
    CASE Credit_Score_segment
        WHEN 'Excellent' THEN 1
        WHEN 'Very good' THEN 2
        WHEN 'Good' THEN 3
        WHEN 'Fair' THEN 4
        WHEN 'Poor' THEN 5
    END;
  #________________________________________________________________________________________________#  
   
 -- OBJECTIVE  8) geographic region has the highest number of active customers with a tenure greater than 5 years 
  SELECT 
    g.GeographyLocation,
    SUM(ch.IsActiveMember) Total_active_customer
FROM
    customerinfo c
        INNER JOIN
   Bank_churn ch ON c.CustomerId = ch.CustomerId
        INNER JOIN
    geography g ON g.GeographyID = c.GeographyID
WHERE
    ch.Tenure > 5
GROUP BY 1
ORDER BY Total_active_customer DESC;
#________________________________________________________________________________________________#

-- OBJECTIVE  10) customers who have exited, what is the most common number of products they have used 
 
SELECT NumOfProducts, COUNT(DISTINCT CustomerId) AS NumCustomers
FROM Bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY NumCustomers DESC
LIMIT 1;
#________________________________________________________________________________________________#
-- Objective 11
SELECT 
	YEAR(bank_doj) Year,
    COUNT(DISTINCT CustomerId) Total_customer
FROM customerinfo
GROUP BY YEAR(bank_doj)
ORDER BY Total_customer DESC;


SELECT 
    MONTH(bank_doj) Month,
    COUNT(DISTINCT CustomerId) Total_customer
FROM
    customerinfo
GROUP BY MONTH(bank_doj)
ORDER BY Total_customer DESC;   

#Combine 
SELECT 
	DISTINCT YEAR(bank_doj) Year,
    Month(bank_doj) Month,
    COUNT(CustomerId) OVER(PARTITION BY Month(bank_doj)) Monthly_Total_customer,
    COUNT(CustomerId) OVER(PARTITION BY YEAR(bank_doj)) Yearly_Total_customer
FROM customerinfo
ORDER BY Yearly_Total_customer DESC,Monthly_Total_customer DESC;
#________________________________________________________________________________________________#

-- OBJECTIVE 12) the relationship between the number of products and the account balance for customers who have exited

SELECT NumOfProducts,
    ROUND(AVG(Balance), 2) AS AvgBalance,
    COUNT(DISTINCT CustomerId) AS NumofCustomers
FROM Bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY AvgBalance DESC; 
#__________________________________________________________________________________________________#

-- OBJECTIVE  15) write a query to find out the gender-wise average income of males and females in each geography id. 
-- Also, rank the gender according to the average value;

SELECT  g.GeographyLocation,
        gen.GenderCategory Gender,
        ROUND(AVG(c.EstimatedSalary),2) AS AvgIncome,
        DENSE_RANK() OVER (PARTITION BY g.GeographyLocation ORDER BY AVG(c.EstimatedSalary) DESC) AS GenderRank
    FROM customerinfo c
	INNER JOIN gender gen
    ON c.GenderID=gen.GenderID
    INNER JOIN geography g
    ON c.GeographyID=g.GeographyID
    GROUP BY g.GeographyLocation, gen.GenderCategory;
 #____________________________________________________________________________________________________________________#;
 
 -- OBJECTIVE 16) 
    SELECT
          CASE WHEN Age BETWEEN 18 AND 30 THEN 'Adult'
	      WHEN Age BETWEEN 31 AND 50 THEN 'Middle-Aged'
          ELSE 'Old-Aged'
          END AS age_brackets,
AVG(Tenure) AS avg_tenure
FROM  customerinfo c
JOIN bank_churn b 
ON c.CustomerId = b.CustomerId
WHERE b.Exited = 1
GROUP BY age_brackets
ORDER BY age_brackets;
#________________________________________________________________________________________________________#
-- Objective 18
SELECT 
    ROUND((COUNT(*) * SUM(EstimatedSalary * CreditScore) - SUM(EstimatedSalary) * SUM(CreditScore)) / 
    SQRT((COUNT(*) * SUM(EstimatedSalary * EstimatedSalary) - POW(SUM(EstimatedSalary), 2)) * 
    (COUNT(*) * SUM(CreditScore * CreditScore) - POW(SUM(CreditScore), 2))),4) AS Correlation_Salary_CreditScore
FROM 
    customerinfo c
    join Bank_churn ch on c.customerid=ch.CustomerId;
 #________________________________________________________________________________________________________#   
    
-- - --  OBJECTIVE 20 
WITH 
     info AS (
     SELECT
     CASE WHEN c.Age BETWEEN 18 AND 30 THEN 'Adult'
     WHEN c.Age BETWEEN 31 AND 50 THEN 'Middle-Aged'
     ELSE 'Old-Aged'
     END AS age_brackets,
	count(c.CustomerId) AS HasCreditCard
    FROM customerinfo c JOIN bank_churn b ON c.CustomerId=b.CustomerId
    WHERE HasCrCard = 1
    GROUP BY age_brackets)
SELECT *
FROM info
WHERE HasCreditCard < (SELECT AVG(HasCreditCard) FROM info);


--  OBJECTIVE 21) Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
SELECT g.GeographyLocation, COUNT(b.CustomerId) AS num_exited, AVG(b.CustomerId) AS avg_balance
FROM bank_churn b
JOIN customerinfo c ON b.CustomerId = c.CustomerId
JOIN geography g ON c.GeographyID = g.GeographyID
WHERE b.Exited = 1
GROUP BY g.GeographyLocation
ORDER BY Count(b.CustomerId)desc;


-- OBJECTIVE 23) Without using “Join”, Retrieving  “ExitCategory” 
SELECT 
	Exited,
    (SELECT ExitCategory FROM exitcustomer WHERE exitcustomer.ExitID = Bank_churn.Exited) ExitCategory,
    COUNT(DISTINCT CustomerId) Total_customer
FROM Bank_churn
GROUP BY 1,2;

-- OBJECTIVE 25) Write the query to get the customer IDs, their last name,  customers whose surname ends with “on”
 
SELECT 
	c.CustomerId,
    c.Surname 'Last Name',
    ac.ActiveCategory
FROM customerinfo c
INNER JOIN bank_churn ch ON c.CustomerId = ch.CustomerId
INNER JOIN activecustomer ac ON ch.IsActiveMember=ac.ActiveID
WHERE LOWER(c.Surname) LIKE '%on';

-- Subjective 9
SELECT 
    CASE
        WHEN Balance BETWEEN 0 AND 50000 THEN 'Very Low'
        WHEN Balance BETWEEN 50001 AND 100000 THEN 'Low'
        WHEN Balance BETWEEN 100001 AND 150000 THEN 'Medium'
        WHEN Balance BETWEEN 150001 AND 200000 THEN 'High'
        ELSE 'Very High'
    END AS BalanceRange,
    CASE
        WHEN age BETWEEN 18 AND 40 THEN 'Adult'
        WHEN Balance BETWEEN 41 AND 60 THEN 'Middle aged'
        ELSE 'Old'
    END AS age_bucket,
    COUNT(DISTINCT Bank_churn.CustomerId) AS NumberOfCustomers
FROM Bank_churn
JOIN customerinfo ON Bank_churn.CustomerId=customerinfo.CustomerId
GROUP BY BalanceRange,age_bucket
ORDER BY 
	CASE BalanceRange
    WHEN '0-50,000' THEN 1
    WHEN '50,001-100,000' THEN 2
    WHEN '100,001-150,000' THEN 3
    WHEN '150,001-200,000' THEN 4
    ELSE 5 END ;


-- Subjective 14

ALTER TABLE bank_churn
RENAME COLUMN HasCrCard TO Has_creditcard;


