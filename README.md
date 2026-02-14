# airlines_sdbms

## Project Workflow

- **Conceptual Design**: Created the ER Model to define entities
- **Logical Design**: Mapped the ER model to a Relational Schema with Primary/Foreign Keys and normalization.
- **Physical Implementation**: Built the database in PostgreSQL with PostGIS for spatial data types.
- **ETL & Data Population**: Cleaned raw data via Python, imported CSVs and Shapefiles, and added manual artificial data.
- **Data Querying**: Executed both relational and spatial SQL queries

### 🔗 Data Sources

* ✈️ **[OpenFlights](https://github.com/jpatokal/openflights/tree/master/data)**: 
  * Files: `airports.dat`, `airlines.dat`, `routes.dat`
  
* 🌍 **[Natural Earth](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/)**: 
  * File: `ne_10m_admin_0_countries.shp`

* 👤 **Artificial Data**: 
  * Manually generated.
  * Entities: `Passengers`, `Tickets`, `Payments`, and `Flights`.
