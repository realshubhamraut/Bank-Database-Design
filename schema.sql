--Definitions
-- This entity will keep information about each person that interacts with the bank, either as a customer, an employee, or any other role.
CREATE TABLE IF NOT EXISTS `People` (
    `id` INT AUTO_INCREMENT,
    `firstName` VARCHAR(150) NOT NULL,
    `lastName` VARCHAR(150) NOT NULL,
    `DateOfBirth` DATE NOT NULL,
    `PhoneNumber` CHAR(11) NOT NULL,
    `Email` VARCHAR(150),
    `Address` VARCHAR(250) NOT NULL,

    PRIMARY KEY(`id`)
);

-- This entity will keep basic information about the different branches or offices of the bank.
CREATE TABLE IF NOT EXISTS `Branches` (
    `id` INT AUTO_INCREMENT,
    `branchName` VARCHAR(150) NOT NULL UNIQUE,
    `branchCode` VARCHAR(10) NOT NULL UNIQUE,
    `Address` VARCHAR(250) NOT NULL,
    `PhoneNumber` VARCHAR(11) NOT NULL,

    PRIMARY KEY(`id`)
);

-- This entity will store information about the persons that are also bank employees. 
CREATE TABLE IF NOT EXISTS `Employees` (
    `id` INT AUTO_INCREMENT,
    `personId` INT,
    `branchId` INT,
    `position` VARCHAR(30) NOT NULL,

    PRIMARY KEY(`id`),
    FOREIGN KEY(`personId`) REFERENCES `People`(`id`),
    FOREIGN KEY(`branchId`) REFERENCES `Branches`(`id`)
);

-- This entity will store information about the persons that are also bank customers. 
CREATE TABLE IF NOT EXISTS `Customers` (
    `id` INT AUTO_INCREMENT,
    `personId` INT,
    `customerType` ENUM('regular', 'premium') NOT NULL DEFAULT `regular`,

    PRIMARY KEY(`id`),
    FOREIGN KEY(`personId`) REFERENCES `People`(`id`)
);


-- This entity keeps information about the different accounts each customer or group of customers can have in the bank.
CREATE TABLE IF NOT EXISTS `Accounts` (
    `id` INT AUTO_INCREMENT,
    `branchId` INT,
    `accountType` ENUM('saving', 'checking', 'credit') NOT NULL,
    `accountNumber` VARCHAR(30) NOT NULL,
    `currentBalance` DECIMAL(10, 2) NOT NULL,
    `createdAt` DATE NOT NULL,
    `closedAt` DATE,
    `accountStatus` ENUM('active', 'suspended', 'closed') NOT NULL,

    PRIMARY KEY(`id`),
    FOREIGN KEY(`branchId`) REFERENCES `Branches`(`id`)
);

-- This entity will store owners of each account because each account may have one or more owner
CREATE TABLE IF NOT EXISTS `AccountOwnerships` (
    `id` INT AUTO_INCREMENT,
    `accountId` INT,
    `ownerId` INT,

    PRIMARY KEY(`id`),
    FOREIGN KEY(`accountId`) REFERENCES `Accounts`(`id`),
    FOREIGN KEY(`ownerId`) REFERENCES `Customers`(`id`)
);

-- This entity keeps information about the different loans that the bank grants to customers.
CREATE TABLE IF NOT EXISTS `Loans` (
    `id` INT AUTO_INCREMENT,
    `customerId` INT,
    `loanType` ENUM('personal', 'mortgage', 'auto') NOT NULL,
    `loanAmount` DECIMAL(10, 2) NOT NULL CHECK(`loanAmount` > 0),
    `interestrate` DECIMAL(10, 2) NOT NULL CHECK(`interestRate` > 0),
    `term` SMALLINT NOT NULL,
    `startDate` DATE NOT NULL,
    `endDate` DATE NOT NULL,
    `status` ENUM('active', 'canceled', 'closed') NOT NULL DEFAULT `active`,

    PRIMARY KEY(`id`),
    FOREIGN KEY(`customerId`) REFERENCES `Customers`(`id`)
);

-- Loans usually have a scheduled number of payments that include both principal and interest.
CREATE TABLE IF NOT EXISTS `LoanPayments` (
    `id` INT AUTO_INCREMENT,
    `loanId` INT,
    `scheduledPaymentDate` DATE NOT NULL,
    `paymentAmount` DECIMAL(10, 2) NOT NULL,
    `principalAmount` DECIMAL(10, 2) NOT NULL,
    `interestAmount` DECIMAL(10, 2) NOT NULL,
    `paidAmount` DECIMAL(10, 2) NOT NULL,
    `PaidDate` DATE NOT NULL,

    PRIMARY KEY(`id`),
    FOREIGN KEY(`loanId`) REFERENCES `Loans`(`id`)
);

-- Each operation performed in a bank is usually represented by one transaction or multiple transactions.
CREATE TABLE IF NOT EXISTS `Transactions` (
    `id` INT AUTO_INCREMENT,
    `accountId` INT,
    `transactionType` ENUM('deposit', 'withdrawal' ) NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL CHECK(`amount` > 0),
    `transactionDate` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY(`id`),
    FOREIGN KEY(`accountId`) REFERENCES `Accounts`(`id`)
);

CREATE TABLE IF NOT EXISTS `Transfers` (
    `id` INT AUTO_INCREMENT,
    `originAccountId` INT,
    `destinationAccountId` INT,
    `amount` DECIMAL(10, 2) NOT NULL CHECK(`amount` > 0),
    `occurenceTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY(`id`),
    FOREIGN KEY(`originAccountId`) REFERENCES `Accounts`(`id`),
    FOREIGN KEY(`destinationAccountId`) REFERENCES `Accounts`(`id`)
);

-- Views

-- loan of each account
CREATE VIEW `personLoan` AS 
SELECT 
    `People`.`firstName`,
    `People`.`lastName`,
    `loanType`,
    `loanAmount`,
    `interestrate`,
    `term`,
    `status`
FROM `Loans` 
INNER JOIN `Customers` ON `Customers`.`id` = `Loans`.`customerId`
INNER JOIN `People` ON `Customers`.`personId` = `People`.`id`;

-- deposits transactions for each account
CREATE VIEW `accountDeposits` AS
SELECT 
    `Accounts`.`accountNumber`,
    `Accounts`.`currentBalance`,
    `amount`,
    `transactionDate`
FROM `Transactions`
INNER JOIN `Accounts` ON `Transactions`.`accountId` = `Accounts`.`id`;


-- employees of each branch
CREATE VIEW `branchEmployees` AS
SELECT
    `Branches`.`branchCode`,
    `Employees`.`position`,
    `People`.`firstName`,
    `People`.`lastName`
FROM `Employees`
INNER JOIN `Branches` ON `Branches`.`id` = `Employees`.`branchId`
INNER JOIN `People` ON `People`.`id` = `Employees`.`personId`;

-- accounts of each branch
CREATE VIEW `accountsOfEachBranch` AS
SELECT 
    `Branches`.`branchName`,
    `Branches`.branchCode,
    `Accounts`.`id`
FROM `Branches`
INNER JOIN `Accounts` ON `Accounts`.`branchId` = `Branches`.`id`;

-- Triggers
DELIMITER //
CREATE TRIGGER `update_account_balance_after_update`
AFTER UPDATE ON `Transactions`
FOR EACH ROW
BEGIN
  -- Calculate the difference between the old and new transaction amounts
  DECLARE `amount_diff` DECIMAL(10, 2);
  SET `amount_diff` = NEW.`amount` - OLD.`amount`;
  
  -- Update the account balance based on the amount difference
  UPDATE `Accounts`
  SET `currentBalance` = `currentBalance` + `amount_diff`
  WHERE `id` = NEW.`accountId`;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER `prevent_delete_customer_with_active_accounts`
BEFORE DELETE ON `Customers`
FOR EACH ROW
BEGIN
  -- Check if the customer has any active accounts
  IF EXISTS (
    SELECT 1
    FROM `Accounts`
    WHERE `customerId` = OLD.`id` AND `accountStatus` = 'active'
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET `MESSAGE_TEXT` = 'Cannot delete customer with active accounts';
  END IF;
END //
DELIMITER;


DELIMITER //
CREATE TRIGGER `enforce_maximum_loan_amount`
BEFORE INSERT ON `Loans`
FOR EACH ROW
BEGIN
  -- Check if the loan amount exceeds the maximum allowed amount
  IF NEW.`amount` > 100000 THEN
    SIGNAL SQLSTATE '45000'
    SET `MESSAGE_TEXT` = 'Loan amount exceeds maximum allowed amount';
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER `prevent_delete_customer_with_active_accounts`
BEFORE DELETE ON `Customers`
FOR EACH ROW
BEGIN
  -- Declare a variable to store the count of active accounts
  DECLARE `active_account_count` INT;
  
  -- Check if the customer has any active accounts
  SELECT COUNT(*) INTO active_account_count
  FROM `Accounts`
  WHERE `customerId` = OLD.`id` AND `accountStatus` = 'active';
  
  -- Raise an error if any active accounts are found
  IF `active_account_count` > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot delete customer with active accounts';
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER `update_account_balance_after_update`
AFTER UPDATE ON `Transactions`
FOR EACH ROW
BEGIN
  -- Calculate the difference between the old and new transaction amounts
  DECLARE `amount_diff` DECIMAL(10, 2);
  SET `amount_diff` = NEW.`amount` - OLD.`amount`;
  
  -- Update the account balance based on the amount difference
  UPDATE `Accounts`
  SET `currentBalance` = `currentBalance` + `amount_diff`
  WHERE `id` = NEW.`accountId`;
END //
DELIMITER ;

-- Optimization
CREATE INDEX `first_name_idx` ON `People` (`firstName`);
CREATE INDEX `branch_name_idx` ON `Branches` (`branchName`);
CREATE INDEX `account_number_idx` ON `Accounts` (`accountNumber`);
CREATE INDEX `loan_type_idx` ON `Loans` (`loanType`);