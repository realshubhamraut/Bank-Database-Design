INSERT INTO Branches (branchName, branchCode, Address, PhoneNumber)
VALUES ('Main Branch', 'MB001', '456 Park Ave', '9876543210');

INSERT INTO Branches (branchName, branchCode, Address, PhoneNumber)
VALUES ('Main Branch', 'MB001', '456 Park Ave', '9876543210');

INSERT INTO Employees (personId, branchId, position)
VALUES (1, 1, 'Manager');

INSERT INTO Customers (personId, customerType)
VALUES (2, 'regular');

INSERT INTO Accounts (branchId, accountType, accountNumber, currentBalance, createdAt, accountStatus)
VALUES (1, 'checking', '1234567890', 1000.00, '2023-12-01', 'active');

SELECT * FROM People;

SELECT * FROM Branches;

SELECT E.id, P.firstName, P.lastName, B.branchName, B.branchCode, E.position
FROM Employees E
INNER JOIN People P ON E.personId = P.id
INNER JOIN Branches B ON E.branchId = B.id;

SELECT C.id, P.firstName, P.lastName, C.customerType
FROM Customers C
INNER JOIN People P ON C.personId = P.id;

SELECT A.id, B.branchName, B.branchCode, A.accountType, A.accountNumber, A.currentBalance
FROM Accounts A
INNER JOIN Branches B ON A.branchId = B.id;

SELECT C.id, P.firstName, P.lastName, B.branchName, B.branchCode, A.accountType, A.accountNumber, A.currentBalance
FROM Customers C
INNER JOIN People P ON C.personId = P.id
INNER JOIN Accounts A ON C.id = A.customerId
INNER JOIN Branches B ON A.branchId = B.id;

SELECT B.branchName, COUNT(A.id) AS totalAccounts
FROM Branches B
LEFT JOIN Accounts A ON B.id = A.branchId
GROUP BY B.branchName;

SELECT P.firstName, P.lastName
FROM Employees E
INNER JOIN People P ON E.personId = P.id
GROUP BY P.firstName, P.lastName
HAVING COUNT(DISTINCT E.branchId) > 1;

SELECT B.branchName, C.id, P.firstName, P.lastName, A.currentBalance
FROM Branches B
INNER JOIN Accounts A ON B.id = A.branchId
INNER JOIN Customers C ON A.customerId = C.id
INNER JOIN People P ON C.personId = P.id
WHERE A.currentBalance = (
  SELECT MAX(currentBalance)
  FROM Accounts
  WHERE branchId = B.id
)
ORDER BY B.branchName;

SELECT C.id, P.firstName, P.lastName, A.accountNumber, A.currentBalance
FROM Customers C
INNER JOIN People P ON C.personId = P.id
INNER JOIN Accounts A ON C.id = A.customerId
WHERE A.currentBalance > (
  SELECT AVG(currentBalance)
  FROM Accounts
)
ORDER BY A.currentBalance DESC;

SELECT C.id, P.firstName, P.lastName, A.accountNumber, A.currentBalance
FROM Customers C
INNER JOIN People P ON C.personId = P.id
INNER JOIN Accounts A ON C.id = A.customerId
WHERE A.currentBalance > (
  SELECT AVG(currentBalance)
  FROM Accounts
)
ORDER BY A.currentBalance DESC;

UPDATE People
SET PhoneNumber = '9876543210'
WHERE id = 1;

UPDATE Branches
SET Address = '789 Elm St'
WHERE id = 1;

UPDATE Employees
SET position = 'Supervisor'
WHERE id = 1;

UPDATE Accounts
SET currentBalance = 1500.00
WHERE id = 1;

DELETE FROM People
WHERE id = 1;

DELETE FROM Branches
WHERE id = 1;

DELETE FROM Employees
WHERE id = 1;

DELETE FROM Customers
WHERE id = 1;

DELETE FROM Customers
WHERE id = 1;

DELETE FROM Accounts
WHERE id = 1;
