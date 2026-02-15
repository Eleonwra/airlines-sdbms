## Project Overview
This project is a Relational and Geospatial Database designed to model a static simulation of global air transport infrastructure by integrating real-world spatial and non-spatial flight data with manually generated transactional records.

## Project Workflow
- **Conceptual Design**: Created the ER Model to define entities
- **Logical Design**: Mapped the ER model to a Relational Schema with Primary/Foreign Keys and normalization.
- **Physical Implementation**: Built the database in PostgreSQL with PostGIS for spatial data types.
- **ETL & Data Population**: Executed a custom preprocessing workflow using **Python** and **QGIS** to clean, extract, and transform raw datasets into an ER-compliant format before importing them into the database.
- **Data Querying**: Executed both relational and spatial SQL queries

## Tools 
- **PostgreSQL & PostGIS**: Core database engine used for relational data and spatial geometry processing.
- **pgAdmin 4**: Primary interface for database management.
- **QGIS:** The "Spatial Engine" used for importing shapefile data
- **Mapshaper:** The final visualization and optimization tool, used to inspect the final spatial output for web-readiness.

## 🔗 Data Sources

* ✈️ **[OpenFlights](https://github.com/jpatokal/openflights/tree/master/data)**: 
  * Files: `airports.dat`, `airlines.dat`, `routes.dat`
  
* 🌍 **[Natural Earth](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/)**: 
  * File: `ne_10m_admin_0_countries.shp`

* 👤 **Artificial Data**: 
  * Manually generated.
  * Entities: `Passengers`, `Tickets`, `Payments`, and `Flights`.
 
 ## License & Attribution
- **Data License**
The airline, airport and route datasets used in this project are made available under the [Open Database License (ODbL) v1.0](https://github.com/jpatokal/openflights/blob/master/data/LICENSE). Any derivative databases created from this data are also subject to the ODbL.

- **Software License**
All original code, SQL scripts, and documentation in this repository are licensed under the MIT License. You are free to use, copy, and modify the code for any purpose, provided the original copyright notice is included.
