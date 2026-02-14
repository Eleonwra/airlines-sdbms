# airlines_sdbms

## Project Workflow

- **Conceptual Design (ER Model)**
- **Logical Design (Relational Mapping)**: Converted the ER model into a Relational Schema, defining Primary Keys, Foreign Keys, and ensuring data normalization.
- **Physical Implementation (PostgreSQL/PostGIS)**:
- **ETL & Data Population**: Cleaned raw data using Python, imported it into the schema, and manually synthesized artificial data.
- **Data Querying**:


### 🔗 Data Sources

* ✈️ **[OpenFlights](https://github.com/jpatokal/openflights/tree/master/data)**: 
  * Files: `airports.dat`, `airlines.dat`, `routes.dat`
  
* 🌍 **[Natural Earth](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/)**: 
  * File: `ne_10m_admin_0_countries.shp`

* 👤 **Artificial Data**: 
  * Manually generated.
  * Entities: `Passengers`, `Tickets`, `Payments`, and `Flights`.
