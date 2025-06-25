-- schema.sql - SQL Commands to set up the database table for Council Tax Rebate sign-ups

-- Create the database (Terraform already creates it, but good to show)
-- CREATE DATABASE [sqldb-rebate-data];
-- GO

-- Use the newly created database
USE [sqldb-rebate-data];
GO

-- Create table to store resident sign-up information
-- IMPORTANT: For highly sensitive data like BankAccountNumber and SortCode,
-- consider Azure SQL's Always Encrypted feature for client-side encryption.
-- The current NVARCHAR(MAX) approach below relies on TDE (Transparent Data Encryption) at rest
-- and in-transit encryption (TLS), which are standard for Azure SQL.
-- For production-grade security, Always Encrypted is a strong recommendation.

CREATE TABLE Residents (
    ResidentID INT IDENTITY(1,1) PRIMARY KEY,
    CouncilTaxAccountNumber NVARCHAR(50) NOT NULL UNIQUE, -- Ensures one sign-up per account
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Postcode NVARCHAR(20) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE, -- For communication, unique per resident
    PhoneNumber NVARCHAR(50),
    BankAccountNumber NVARCHAR(MAX) NOT NULL, -- Stored as string, consider Always Encrypted for client-side encryption
    SortCode NVARCHAR(MAX) NOT NULL,          -- Stored as string, consider Always Encrypted for client-side encryption
    SignupDate DATETIME DEFAULT GETDATE(),
    RebateStatus NVARCHAR(50) DEFAULT 'Pending', -- e.g., 'Pending', 'Verified', 'Paid', 'Declined'
    VerificationAttemptCount INT DEFAULT 0,
    LastVerificationAttempt DATETIME,
    LastModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Create an index on Postcode for faster lookups (e.g., for verification)
CREATE INDEX IX_Residents_Postcode ON Residents (Postcode);
GO

-- Create a stored procedure (optional, but good practice for abstractions)
-- For demonstration, we'll keep the Flask app simple with direct queries,
-- but in a real app, you'd use stored procedures for complex logic.
/*
CREATE PROCEDURE AddResidentRebate
    @CouncilTaxAccountNumber NVARCHAR(50),
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @Postcode NVARCHAR(20),
    @Email NVARCHAR(255),
    @PhoneNumber NVARCHAR(50),
    @BankAccountNumber NVARCHAR(MAX),
    @SortCode NVARCHAR(MAX)
AS
BEGIN
    INSERT INTO Residents (
        CouncilTaxAccountNumber, FirstName, LastName, Postcode, Email, PhoneNumber,
        BankAccountNumber, SortCode
    ) VALUES (
        @CouncilTaxAccountNumber, @FirstName, @LastName, @Postcode, @Email, @PhoneNumber,
        @BankAccountNumber, @SortCode
    );
END;
GO
*/
