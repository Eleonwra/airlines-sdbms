-- Extensions
CREATE EXTENSION postgis;

-- 2. Parent Tables (No Foreign Keys)

-- Table: Airline
CREATE TABLE public."Airline" (
    "Airline_ID" CHAR(3) PRIMARY KEY,
    "Name" VARCHAR(100) NOT NULL
);

-- Table: Country (Spatial)
CREATE TABLE public."Country" (
    "Country_ID" VARCHAR(35) PRIMARY KEY,
    "GDP_MD" BIGINT, --Gross Domestic Product
    "GDP_YEAR" CHAR(4),
    "geom" public.geometry(MultiPolygon, 4326)
);

-- 3. Tables with Foreign Keys

-- Table: Airport (Spatial)
CREATE TABLE public."Airport" (
    "Airport_ID" CHAR(3) PRIMARY KEY,
    "Name" VARCHAR(100) NOT NULL,
    "Country_ID" VARCHAR(35) NOT NULL, 
    "geom" public.geometry(PointZM, 4326),
    CONSTRAINT fk_country 
        FOREIGN KEY ("Country_ID") 
        REFERENCES public."Country" ("Country_ID")
);

-- Table: Route (Spatial)
CREATE TABLE public."Route" (
    "Route_ID" CHAR(7) PRIMARY KEY,
    "Airport_ID_start" CHAR(3) NOT NULL,
    "Airport_ID_end" CHAR(3) NOT NULL,
    "geom" public.geometry(LineString, 4326),
    
    CONSTRAINT fk_route_start 
        FOREIGN KEY ("Airport_ID_start") 
        REFERENCES public."Airport" ("Airport_ID"),
        
    CONSTRAINT fk_route_end 
        FOREIGN KEY ("Airport_ID_end") 
        REFERENCES public."Airport" ("Airport_ID")
);

-- Table: Flight
CREATE TABLE public."Flight" (
    "Flight_ID" VARCHAR(20) PRIMARY KEY,
    "Departure_Time" TIMESTAMPZ, 
    "Arrival_Time" TIMESTAMPZ,   
    "Route_ID" CHAR(7) NOT NULL, 
    
    CONSTRAINT fk_route
        FOREIGN KEY ("Route_ID") 
        REFERENCES public."Route"("Route_ID")
);

-- Table: Ticket
CREATE TYPE flight_class AS ENUM ('Economy', 'Business', 'First Class');
CREATE TABLE public."Ticket" (
    "Ticket_ID" CHAR(14) PRIMARY KEY,
    "No_seat" SERIAL,
    "Class" flight_class NOT NULL, 
    "Flight_ID" VARCHAR(20) NOT NULL,
    
    CONSTRAINT fk_flight
        FOREIGN KEY ("Flight_ID") 
        REFERENCES public."Flight"("Flight_ID")
);

-- Table: Payment
CREATE TYPE payment_method AS ENUM ('Cash', 'Card');
CREATE TABLE public."Payment" (
    "Payment_ID" SMALLINT PRIMARY KEY,
    "Ticket_ID" CHAR(14) NOT NULL,
    "Date" DATE,
    "Price" NUMERIC(10,2),
    "Method" payment_method NOT NULL,
    CONSTRAINT fk_ticket 
        FOREIGN KEY ("Ticket_ID") 
        REFERENCES public."Ticket" ("Ticket_ID")
);

-- Table: Passenger
CREATE TABLE public."Passenger" (
    "Passenger_ID" SMALLINT PRIMARY KEY,
    "Full_Name" VARCHAR(30),
    "Phone" VARCHAR(20),
    "Age" SMALLINT,
    "Country_ID" VARCHAR(35),
    "Ticket_ID" CHAR(14) NOT NULL,
    FOREIGN KEY ("Ticket_ID") REFERENCES public."Ticket"("Ticket_ID"),
    FOREIGN KEY ("Country_ID") REFERENCES public."Country"("Country_ID"),
    CONSTRAINT check_age_range 
        CHECK ("Age" >= 0 AND "Age" < 110)
);

-- Table: Uses (Relationship between Airline and Route)
CREATE TABLE public."Uses" (
    "Airline_ID" CHAR(3),
    "Route_ID" CHAR(7),
    PRIMARY KEY ("Airline_ID", "Route_ID"),
    FOREIGN KEY ("Airline_ID") REFERENCES public."Airline"("Airline_ID"),
    FOREIGN KEY ("Route_ID") REFERENCES public."Route"("Route_ID")
);

-- Table: has_hub (Relationship between Airline and Airport)
CREATE TABLE public."has_hub" (
    "Airline_ID" CHAR(3),
    "Airport_ID" CHAR(3),
    "Hub_Type" VARCHAR(50) DEFAULT 'Main',
    CONSTRAINT fk_airline FOREIGN KEY ("Airline_ID") REFERENCES public."Airline"("Airline_ID") ON DELETE CASCADE,
    CONSTRAINT fk_airport FOREIGN KEY ("Airport_ID") REFERENCES public."Airport"("Airport_ID") ON DELETE CASCADE,
    PRIMARY KEY ("Airline_ID", "Airport_ID")
);