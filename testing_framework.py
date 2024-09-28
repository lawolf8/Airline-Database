import pytest
import pyodbc
from typing import Any

class DatabaseTest:
    """Base class for database operations and setup for tests."""
    
    def __init__(self, server: str, database: str, username: str, password: str):
        connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
        self.cnxn = pyodbc.connect(connection_string)
        self.cursor = self.cnxn.cursor()

    def setup(self):
        """Setup function to prepare database for each test."""
        self.cursor.execute("DELETE FROM flights WHERE flight_id = 123;")
        self.cursor.execute("DELETE FROM planes WHERE plane_id = 321;")
        self.cursor.execute("DELETE FROM tickets WHERE ticket_id = 456;")
        self.cursor.execute("DELETE FROM customers WHERE customer_id = 1;")
        self.cnxn.commit()

    def teardown(self):
        """Teardown function to clean up after each test."""
        self.cursor.execute("DELETE FROM flights WHERE flight_id = 123;")
        self.cursor.execute("DELETE FROM planes WHERE plane_id = 321;")
        self.cursor.execute("DELETE FROM tickets WHERE ticket_id = 456;")
        self.cursor.execute("DELETE FROM customers WHERE customer_id = 1;")
        self.cnxn.commit()

class TestDatabaseOperations(DatabaseTest):
    """Class to perform specific database tests."""

    def test_flight_date_restriction(self):
        with pytest.raises(pyodbc.Error) as excinfo:
            self.cursor.execute("INSERT INTO flights (flight_id, date) VALUES (123, '2021-01-01');")
            self.cnxn.commit()
        assert 'Flight dates must be between 2016 and 2019' in str(excinfo.value)

    def test_planes_modification_restriction(self):
        with pytest.raises(pyodbc.Error) as excinfo:
            self.cursor.execute("UPDATE planes SET model = 'NewModel' WHERE plane_id = 321;")
            self.cnxn.commit()
        assert 'modification, or deletion of rows not allowed' in str(excinfo.value)

    def test_ticket_price_update_restriction(self):
        try:
            self.cursor.execute("UPDATE tickets SET final_price = 100 WHERE ticket_id = 456;")
            self.cnxn.commit()
        except pyodbc.Error as e:
            assert 'Final price cannot deviate more than 20%' in str(e)

    def test_customer_name_length_restriction(self):
        with pytest.raises(pyodbc.Error) as excinfo:
            self.cursor.execute("INSERT INTO customers (customer_id, first_name, last_name) VALUES (1, 'ExtremelyLongFirstNameThatShouldFail', 'Doe');")
            self.cnxn.commit()
        assert 'Input or update of first_name values is restricted' in str(excinfo.value)

    def test_audit_insertion_for_planes(self):
        self.cursor.execute("INSERT INTO planes (plane_id, brand, model) VALUES (321, 'Boeing', '747');")
        self.cnxn.commit()
        self.cursor.execute("SELECT aud_operation FROM TB_audit WHERE aud_table = 'planes' AND aud_identifier_id = '321';")
        result = self.cursor.fetchone()
        assert result[0] == 'INSERT', "Audit log should record an INSERT operation"

    def test_constraint_and_trigger_cleanup(self):
        self.cursor.execute("SELECT COUNT(*) FROM sys.triggers WHERE name LIKE 'Restricted_%';")
        trigger_count_before_cleanup = self.cursor.fetchone()[0]
        self.cursor.execute("DROP TRIGGER Restricted_Edit_On_Planes_Trigger;")
        self.cnxn.commit()
        self.cursor.execute("SELECT COUNT(*) FROM sys.triggers WHERE name LIKE 'Restricted_%';")
        trigger_count_after_cleanup = self.cursor.fetchone()[0]
        assert trigger_count_before_cleanup - 1 == trigger_count_after_cleanup, "Trigger cleanup not working as expected"

if __name__ == "__main__":
    pytest.main()
