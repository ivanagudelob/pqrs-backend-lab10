# PQRS System Database Summary

## Project Overview

This project implements a comprehensive database schema for a PQRS (Peticiones, Quejas, Reclamos y Sugerencias) system designed for municipal or governmental use. The system allows citizens to submit requests, complaints, claims, and suggestions while providing government staff with tools to manage and respond to these submissions efficiently.

## Technologies Used

- **Database**: PostgreSQL with Supabase
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage (for file attachments)
- **Security**: Row Level Security (RLS) policies
- **Extensions**: uuid-ossp, pgcrypto

## Key Features

### Core Functionality
- **Multi-type Requests**: Support for peticiones (requests), quejas (complaints), reclamos (claims), and sugerencias (suggestions)
- **User Management**: Role-based access control with ciudadano, funcionario, administrador, and super_admin roles
- **Categorization**: Organized request categories for better management
- **Department Assignment**: Route requests to appropriate government departments
- **File Attachments**: Support for multiple file attachments per request
- **Response System**: Two-way communication between citizens and staff
- **Status Tracking**: Complete audit trail of request status changes

### Automated Features
- **Request Numbering**: Automatic generation of unique request numbers (PQRS-YYYY-XXXXXX format)
- **Due Date Calculation**: Automatic due date setting based on request type
- **Status Logging**: Automatic logging of all status changes
- **Timestamp Management**: Automatic updated_at field maintenance
- **User Registration**: Automatic profile creation for new authenticated users

### Security Features
- **Row Level Security**: Comprehensive RLS policies ensuring data privacy
- **Role-based Access**: Different access levels for different user types
- **Data Isolation**: Citizens can only access their own data
- **Staff Permissions**: Controlled access for government staff
- **Admin Controls**: Full system management capabilities for administrators

## Database Schema

### Main Tables
1. **users** - Extended user profiles with government-specific fields
2. **categories** - Request categorization system
3. **departments** - Government departments handling requests
4. **requests** - Main PQRS requests with full metadata
5. **request_attachments** - File attachment management
6. **request_responses** - Communication thread for each request
7. **request_status_history** - Complete audit trail
8. **notifications** - System notifications for users
9. **system_settings** - Configurable system parameters

### Custom Types
- **request_type**: peticion, queja, reclamo, sugerencia
- **request_status**: pendiente, en_proceso, resuelto, cerrado, rechazado
- **priority_level**: baja, media, alta, urgente
- **user_role**: ciudadano, funcionario, administrador, super_admin

## Migration Structure

The database schema is organized into three migration files:

1. **001_initial_schema.sql**
   - Creates all tables, custom types, and relationships
   - Implements automated functions and triggers
   - Sets up performance indexes

2. **002_rls_policies.sql**
   - Implements comprehensive Row Level Security
   - Creates helper functions for role checking
   - Sets up granular access permissions

3. **003_seed_data.sql**
   - Inserts default categories and departments
   - Creates system configuration settings
   - Provides sample data generation functions

## Default Configuration

### Categories
- Servicios Públicos (Public Services)
- Atención al Ciudadano (Citizen Service)
- Infraestructura (Infrastructure)
- Seguridad (Security)
- Medio Ambiente (Environment)
- Salud (Health)
- Educación (Education)
- Transporte (Transportation)
- Trámites y Documentos (Procedures and Documents)
- Otros (Others)

### Departments
- Secretaría General
- Servicios Públicos
- Infraestructura y Obras
- Seguridad y Convivencia
- Medio Ambiente
- Salud
- Educación
- Movilidad
- Atención al Ciudadano

### System Settings
- File upload limits and allowed types
- Response time configurations
- Contact information
- System branding and configuration
- Feature toggles for notifications and anonymous requests

## Performance Optimizations

- **Strategic Indexing**: Indexes on frequently queried columns
- **Efficient Queries**: Optimized for common access patterns
- **Relationship Management**: Proper foreign key relationships with appropriate cascade rules
- **Data Types**: Appropriate data types for optimal storage and performance

## Security Considerations

- **Data Privacy**: RLS ensures users can only access appropriate data
- **Input Validation**: Database-level constraints and checks
- **Audit Trail**: Complete logging of all status changes
- **Role Separation**: Clear separation of citizen and staff capabilities
- **File Security**: Secure file attachment handling through Supabase Storage

## Scalability Features

- **UUID Primary Keys**: Distributed-friendly identifiers
- **Partitioning Ready**: Schema designed for future partitioning if needed
- **Index Strategy**: Comprehensive indexing for query performance
- **Efficient Relationships**: Optimized foreign key relationships

## Compliance and Governance

- **Audit Trail**: Complete history of all request changes
- **Data Retention**: Configurable through system settings
- **Privacy Controls**: Built-in privacy features for sensitive data
- **Reporting Ready**: Schema optimized for reporting and analytics

## Dependencies

- PostgreSQL 12+
- Supabase platform
- uuid-ossp extension
- pgcrypto extension

## Next Steps

1. Deploy migrations to Supabase instance
2. Configure Supabase Storage buckets for file attachments
3. Set up authentication providers
4. Configure email templates for notifications
5. Implement frontend application
6. Set up monitoring and backup procedures

This database schema provides a solid foundation for a comprehensive PQRS system that can handle the needs of municipal governments while ensuring security, performance, and scalability.
