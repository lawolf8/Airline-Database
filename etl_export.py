import pandas as pd
import requests
from sqlalchemy import create_engine
from typing import Callable, Any

class DataExtractor:
    def __init__(self, source: str, source_type: str = 'csv'):
        self.source = source
        self.source_type = source_type
    
    def extract_data(self) -> pd.DataFrame:
        if self.source_type == 'csv':
            return pd.read_csv(self.source)
        elif self.source_type == 'api':
            response = requests.get(self.source)
            return pd.DataFrame(response.json())  # Adjust as per the JSON structure

class DataTransformer:
    @staticmethod
    def transform_flights(data: pd.DataFrame) -> pd.DataFrame:
        data['date'] = pd.to_datetime(data['date'], errors='coerce')
        return data[data['date'].dt.year.between(2016, 2019)]
    
    @staticmethod
    def transform_planes(data: pd.DataFrame) -> pd.DataFrame:
        data['fabrication_date'] = pd.to_datetime(data['fabrication_date'])
        data['first_use_date'] = pd.to_datetime(data['first_use_date'])
        return data

    @staticmethod
    def transform_tickets(data: pd.DataFrame) -> pd.DataFrame:
        data['purchase_date'] = pd.to_datetime(data['purchase_date'])
        return data

    @staticmethod
    def transform_customers(data: pd.DataFrame) -> pd.DataFrame:
        data['first_name'] = data['first_name'].str.slice(0, 50)
        data['last_name'] = data['last_name'].str.slice(0, 50)
        return data

class DataLoader:
    def __init__(self, database_url: str):
        self.database_url = database_url
    
    def load_data(self, data: pd.DataFrame, table_name: str):
        engine = create_engine(self.database_url)
        data.to_sql(table_name, con=engine, if_exists='append', index=False)

class ETLProcess:
    def __init__(self, source: str, table_name: str, transformer_func: Callable[[pd.DataFrame], pd.DataFrame], database_url: str, source_type: str = 'csv'):
        self.extractor = DataExtractor(source, source_type)
        self.transformer_func = transformer_func
        self.loader = DataLoader(database_url)
        self.table_name = table_name

    def run(self):
        data = self.extractor.extract_data()
        transformed_data = self.transformer_func(data)
        self.loader.load_data(transformed_data, self.table_name)

if __name__ == "__main__":
    database_url = 'mssql+pyodbc://username:password@server/database?driver=ODBC+Driver+17+for+SQL+Server'
    etl_flights = ETLProcess('data/flights.csv', 'flights', DataTransformer.transform_flights, database_url)
    etl_flights.run()
    # Additional ETL processes for other tables can be similarly defined and executed.
