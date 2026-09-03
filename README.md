# New Mexico Capital Outlay Analysis

This project analyzes New Mexico capital outlay appropriations using SQL Server and Power BI.

The goal is to transform semi-structured annual capital outlay reports into a normalized relational database that supports repeatable validation, analysis, and reporting.

## Project Scope

Initial scope:

- Legislative years 2021–2026
- Projects associated with Las Cruces, New Mexico
- Sponsor-level appropriations
- Project, agency, fund, and legislative-service data
- SQL Server for storage, normalization, and validation
- Power BI for analysis and visualization

## Project Goals

This project is intended to demonstrate:

- relational database design
- data normalization
- SQL Server development
- staging and data-quality validation
- repeatable data-loading processes
- analytical data modeling
- Power BI reporting
- Git-based version control and documentation

## Data Source

Source data comes from publicly available New Mexico legislative capital outlay reports.

The original source files are kept locally and are not stored in this repository. Source references and retrieval information will be documented as the project develops.

## Repository Structure

```text
data/
    raw/          Local source files; not tracked in Git
    processed/    Generated/intermediate data; not tracked in Git

docs/             Data model, data dictionary, and project documentation

powerbi/          Power BI documentation and related assets

sql/              SQL Server database, staging, loading, and validation scripts