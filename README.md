# OrderDW Sales Analytics

A MySQL-based Sales Data Warehouse project built using a star schema design. This project includes the full schema setup, ETL stored procedures, sample data, and analytical queries for reporting purposes.

---

## 📊 Project Overview

**OrderDW** is a dimensional data warehouse designed to support analytical queries on sales data. It includes:

- Star schema with dimension and fact tables
- Stored procedures for ETL (Extract, Transform, Load)
- Triggers and audit logs for change tracking
- Sample data for testing
- Views for simplified reporting
- Predefined analytical queries

---

## 🧱 Schema Design

The data warehouse follows a star schema:

- **Fact Table:**
  - `FactOrderLines`: Central table storing order line measures
- **Dimension Tables:**
  - `DimDate`: Date attributes
  - `DimCustomer`: Customer info
  - `DimProduct`: Product catalog
  - `DimLocation`: Shipping locations
  - `DimShipper`: Shipping providers

---

## ⚙️ Setup & Execution Order

Execute the SQL files in this order:

1. `01_dw_schema_and_audit.sql`  
   ⤷ Creates database schema, dimension/fact tables, and audit log with triggers.

2. `02_etl_procedures_and_views.sql`  
   ⤷ Defines stored procedures for populating dimensions and fact tables. Also includes a reporting view.

3. `03_sample_data_population.sql`  
   ⤷ Inserts mock data into all dimension and fact tables.

4. `04_procedure_call_examples.sql`  
   ⤷ Example usage of stored procedures for ETL-like operations.

5. `05_sample_reporting_queries.sql`  
   ⤷ Ready-to-run queries for analysis: sales trends, top products, customer segmentation, etc.

---

## 🔍 Features

- **ETL-ready procedures** to support data loading and surrogate key management
- **Audit triggers** to log inserts into the fact table
- **Reusable views** for simplified reporting
- **Sample queries** covering:
  - Sales over time
  - Product performance
  - Customer segmentation
  - Regional trends

---

## 🚀 Getting Started

### Prerequisites
- MySQL 8.0+
- SQL client or IDE (e.g., MySQL Workbench, DBeaver)

### Run the Scripts
```bash
# Example using CLI
mysql -u root -p < 01_dw_schema_and_audit.sql
mysql -u root -p < 02_etl_procedures_and_views.sql
mysql -u root -p < 03_sample_data_population.sql
mysql -u root -p < 04_procedure_call_examples.sql
mysql -u root -p < 05_sample_reporting_queries.sql
