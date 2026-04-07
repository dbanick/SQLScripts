USE AdventureWorks;
GO
SELECT name, create_date, modify_date
FROM sys.objects
WHERE type = 'P'
AND name = 'uspUpdateEmployeeHireInfo'
GO