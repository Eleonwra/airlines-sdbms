import pandas as pd
import os

def load_csv(data_dir, filename, subfolder= None, has_header=None):
    path = os.path.join(data_dir, subfolder, filename) if subfolder else os.path.join(data_dir, filename)
    if not os.path.exists(path):
        raise FileNotFoundError(f"Cannot find file at: {path}")
    return pd.read_csv(path, header=has_header, na_values=['\\N'])

def process_airports(data_dir, countries_filter_df):
    """Cleans airport data and filters by valid countries."""
    df = load_csv(data_dir, 'airports.csv')
    df = df[[df.columns[4], df.columns[1], df.columns[3], df.columns[6], df.columns[7], df.columns[8]]]
    df.columns = ['Airport_ID', 'Name', 'Country', 'Latitude', 'Longtitude', 'Altitude']
    df = df.dropna()
    mask = df["Country"].isin(countries_filter_df["Country_ID"])
    return df.loc[mask]

def process_routes(data_dir, valid_airports_df):
    """Cleans routes and ensures both start/end airports exist in the DB."""
    df = load_csv(data_dir, 'routes.csv')
    df = df[[df.columns[2], df.columns[4]]]
    df['Route_ID'] = df[2] + "-" + df[4]
    df.columns = ['Airport_ID_start', 'Airport_ID_end', 'Route_ID']
    unique_routes = df.drop_duplicates()
    mask = (unique_routes["Airport_ID_start"].isin(valid_airports_df["Airport_ID"])) & \
           (unique_routes["Airport_ID_end"].isin(valid_airports_df["Airport_ID"]))
    return unique_routes.loc[mask]

def process_airlines(data_dir):
    df = load_csv(data_dir, 'airlines.csv')
    df_active = df[df[df.columns[7]] == 'Y'].copy()
    df = df[[df.columns[0], df.columns[1], df.columns[4]]].copy() #id name icao
    df.columns = ['Airline_ID', 'Name', 'ICAO']
    df =df.drop_duplicates(subset=['ICAO'])
    df['Airline_ID'] = pd.to_numeric(df['Airline_ID'], errors='coerce')
    df = df[df['ICAO'].str.match(r'^[A-Z0-9]{3}$', na=False)]
    return df.dropna().drop_duplicates(subset=["Airline_ID"])

def process_uses(data_dir, airlines_df, routes_df):
    """Creates the junction table between Airlines and Routes."""
    df = load_csv(data_dir, 'routes.csv')
    df = df[[df.columns[1], df.columns[2], df.columns[4]]].copy()
    df['Route_ID'] = df[df.columns[1]] + "-" + df[df.columns[2]]
    df.columns = ['Airline_ID', 'Source', 'Dest', 'Route_ID']
    df['Airline_ID'] = pd.to_numeric(df['Airline_ID'], errors='coerce')
    df_merged = pd.merge(df, airlines_df[['Airline_ID', 'ICAO']], on='Airline_ID')
    mask = df_merged["Route_ID"].isin(routes_df["Route_ID"])
    df_final = df_merged[mask].copy()
    df_final['Airline_ID'] = df_final['ICAO'] 
    return df_final[['Airline_ID', 'Route_ID']].drop_duplicates()

script_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.join(script_dir, '..', 'data')
raw_dir = os.path.join(data_dir, 'raw')
countries_ref = pd.read_csv(os.path.join(data_dir, 'spatial', 'countries.csv'))

clean_airports = process_airports(raw_dir, countries_ref)
clean_routes = process_routes(raw_dir, clean_airports)
clean_airlines = process_airlines(raw_dir)
clean_uses = process_uses(raw_dir, clean_airlines, clean_routes)

clean_airlines['Airport_ID'] = clean_airlines['ICAO']
final_airlines =  clean_airlines[['Airport_ID','Name']]

processed_dir = os.path.join(data_dir, 'processed')
if not os.path.exists(processed_dir):
    os.makedirs(processed_dir)

clean_airports.to_csv(os.path.join(processed_dir, 'airports.csv'), index=False)
clean_routes.to_csv(os.path.join(processed_dir, 'routes.csv'), index=False)
final_airlines.to_csv(os.path.join(processed_dir, 'airlines.csv'), index=False)
clean_uses.to_csv(os.path.join(processed_dir, 'uses.csv'), index=False)