# app.py - Python Flask Web Application for Council Tax Rebate Sign-up

from flask import Flask, render_template, request, redirect, url_for, flash
import os
import pyodbc # For connecting to SQL Server
import logging
from azure.identity import DefaultAzureCredential # For Managed Identity
import struct # Required for Always Encrypted if you implement it fully

# --- Configuration ---
# Get DB connection string from environment variables injected by App Service
# In production, this would come from Azure App Service App Settings referencing Key Vault secrets.
# Example format expected:
# "Server=tcp:<YOUR_SQL_SERVER_FQDN>,1433;Database=<YOUR_SQL_DATABASE_NAME>;UID=<SQL_ADMIN_USERNAME>;PWD=<SQL_ADMIN_PASSWORD>;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
DB_CONNECTION_STRING = os.environ.get("DB_CONNECTION_STRING")

# Basic logging setup
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
# IMPORTANT: In a real application, replace this with a strong, randomly generated secret key
# and manage it securely (e.g., via Key Vault and App Settings).
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "super_secret_dev_key_change_me_in_prod")

# --- Database Connection Helper ---
def get_db_connection():
    """
    Establishes a connection to the Azure SQL Database.
    Uses pyodbc.
    """
    if not DB_CONNECTION_STRING:
        logger.error("DB_CONNECTION_STRING environment variable not set.")
        raise ValueError("Database connection string not configured.")

    try:
        # Use pyodbc to connect to the SQL Server
        # Ensure appropriate ODBC driver is available on App Service (e.g., ODBC Driver 17 for SQL Server)
        cnxn = pyodbc.connect(DB_CONNECTION_STRING)
        logger.info("Successfully connected to the database.")
        return cnxn
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        logger.error(f"Database connection error: {sqlstate} - {ex.args[1]}")
        raise

# --- Routes ---

@app.route('/')
def index():
    """
    Renders the sign-up form page.
    """
    return render_template('signup.html')

@app.route('/submit', methods=['POST'])
def submit_rebate_signup():
    """
    Handles the form submission for rebate sign-up.
    Performs basic validation and stores data in the database.
    """
    if request.method == 'POST':
        # Retrieve form data
        council_tax_account_number = request.form['council_tax_account_number'].strip()
        first_name = request.form['first_name'].strip()
        last_name = request.form['last_name'].strip()
        postcode = request.form['postcode'].strip()
        email = request.form['email'].strip()
        phone_number = request.form['phone_number'].strip()
        bank_account_number = request.form['bank_account_number'].strip()
        sort_code = request.form['sort_code'].strip()

        # --- Basic Server-Side Validation ---
        errors = []
        if not all([council_tax_account_number, first_name, last_name, postcode, email, bank_account_number, sort_code]):
            errors.append("All required fields must be filled.")
        if not 5 <= len(postcode) <= 8: # Basic UK postcode length check
            errors.append("Invalid postcode format.")
        if "@" not in email or "." not in email:
            errors.append("Invalid email format.")
        if not bank_account_number.isdigit() or len(bank_account_number) < 8:
            errors.append("Bank Account Number must be numeric and at least 8 digits.")
        if not sort_code.isdigit() or len(sort_code) != 6:
            errors.append("Sort Code must be 6 digits and numeric.")

        if errors:
            for error in errors:
                flash(error, 'error') # Display errors to the user
            logger.warning(f"Validation errors on submission for {email}: {errors}")
            return render_template('signup.html', form_data=request.form)

        # --- Database Interaction ---
        conn = None
        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            # Check for existing Council Tax Account Number or Email (basic fraud prevention)
            cursor.execute("SELECT ResidentID FROM Residents WHERE CouncilTaxAccountNumber = ? OR Email = ?",
                           (council_tax_account_number, email))
            existing_resident = cursor.fetchone()

            if existing_resident:
                flash("A sign-up for this Council Tax Account Number or Email already exists.", 'error')
                logger.warning(f"Duplicate sign-up attempt for account: {council_tax_account_number}, email: {email}")
                return render_template('signup.html', form_data=request.form)

            # Insert new resident data
            insert_query = """
            INSERT INTO Residents (
                CouncilTaxAccountNumber, FirstName, LastName, Postcode, Email, PhoneNumber,
                BankAccountNumber, SortCode
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """
            cursor.execute(insert_query,
                           council_tax_account_number, first_name, last_name, postcode, email, phone_number,
                           bank_account_number, sort_code) # For prod, use Always Encrypted for Bank/Sort Code
            conn.commit()

            flash("Successfully signed up for the Council Tax Rebate! We will process your application shortly.", 'success')
            logger.info(f"New rebate sign-up: {council_tax_account_number}, {email}")
            return redirect(url_for('index')) # Redirect to a clean form or success page

        except pyodbc.Error as ex:
            sqlstate = ex.args[0]
            logger.error(f"Database operation error: {sqlstate} - {ex.args[1]}")
            flash("An error occurred during submission. Please try again.", 'error')
            if conn:
                conn.rollback() # Rollback in case of error
            return render_template('signup.html', form_data=request.form)
        except Exception as e:
            logger.error(f"An unexpected error occurred: {e}", exc_info=True)
            flash("An unexpected error occurred. Please try again.", 'error')
            if conn:
                conn.rollback()
            return render_template('signup.html', form_data=request.form)
        finally:
            if conn:
                conn.close()

    # If not a POST request, redirect to index
    return redirect(url_for('index'))

if __name__ == '__main__':
    # When running locally, you might set the DB_CONNECTION_STRING here for testing,
    # or via your environment. In App Service, it's injected.
    # Example for local testing (replace with your actual local DB details or a test connection):
    # os.environ['DB_CONNECTION_STRING'] = "Driver={ODBC Driver 17 for SQL Server};Server=localhost,1433;Database=sqldb-rebate-data;UID=sa;PWD=your_local_sa_password;"
    # os.environ['FLASK_SECRET_KEY'] = 'dev_local_secret'
    
    # Ensure the ODBC driver is installed on your local machine for pyodbc
    # For Windows: https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server
    # For Linux/macOS: Use brew/apt/yum or follow Microsoft docs

    app.run(debug=True) # debug=True is for development only. Set FLASK_ENV=production in App Service.