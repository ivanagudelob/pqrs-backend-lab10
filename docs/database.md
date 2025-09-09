# Database Schema Documentation

## Overview

This document describes the PostgreSQL/Supabase database schema for the PQRS (Peticiones, Quejas, Reclamos y Sugerencias) system. The schema is designed to handle citizen requests, complaints, claims, and suggestions in a municipal or governmental context.

## Database Structure

### Core Tables

#### 1. users
Extends Supabase's `auth.users` table with additional profile information.

```sql
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    document_type VARCHAR(20) NOT NULL DEFAULT 'cedula',
    document_number VARCHAR(50) NOT NULL UNIQUE,
    address TEXT,
    city VARCHAR(100),
    department VARCHAR(100),
    role user_role NOT NULL DEFAULT 'ciudadano',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Roles:**
- `ciudadano`: Regular citizen users
- `funcionario`: Government staff members
- `administrador`: System administrators
- `super_admin`: Super administrators with full access

#### 2. categories
Organizes requests into different categories for better management.

```sql
CREATE TABLE public.categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    color VARCHAR(7) DEFAULT '#6B7280',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Default Categories:**
- Servicios Públicos
- Atención al Ciudadano
- Infraestructura
- Seguridad
- Medio Ambiente
- Salud
- Educación
- Transporte
- Trámites y Documentos
- Otros

#### 3. departments
Government departments responsible for handling different types of requests.

```sql
CREATE TABLE public.departments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    email VARCHAR(255),
    phone VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. requests
Main table storing all PQRS requests.

```sql
CREATE TABLE public.requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    request_number VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL,
    
    type request_type NOT NULL,
    subject VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    priority priority_level NOT NULL DEFAULT 'media',
    status request_status NOT NULL DEFAULT 'pendiente',
    
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_date TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    is_anonymous BOOLEAN NOT NULL DEFAULT false,
    requires_response BOOLEAN NOT NULL DEFAULT true,
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Request Types:**
- `peticion`: Formal request for information or action
- `queja`: Complaint about service quality
- `reclamo`: Claim about rights violation
- `sugerencia`: Suggestion for improvement

**Status Values:**
- `pendiente`: Newly submitted, awaiting review
- `en_proceso`: Being processed by assigned department
- `resuelto`: Resolved and response provided
- `cerrado`: Closed (resolved and confirmed by user)
- `rechazado`: Rejected (invalid or inappropriate)

**Priority Levels:**
- `baja`: Low priority (30 days response time)
- `media`: Medium priority (15 days response time)
- `alta`: High priority (10 days response time)
- `urgente`: Urgent (5 days response time)

#### 5. request_attachments
File attachments associated with requests.

```sql
CREATE TABLE public.request_attachments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    request_id UUID REFERENCES public.requests(id) ON DELETE CASCADE NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    uploaded_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 6. request_responses
Comments and responses to requests from both citizens and staff.

```sql
CREATE TABLE public.request_responses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    request_id UUID REFERENCES public.requests(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    is_internal BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 7. request_status_history
Audit trail for request status changes.

```sql
CREATE TABLE public.request_status_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    request_id UUID REFERENCES public.requests(id) ON DELETE CASCADE NOT NULL,
    previous_status request_status,
    new_status request_status NOT NULL,
    changed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 8. notifications
System notifications for users.

```sql
CREATE TABLE public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    request_id UUID REFERENCES public.requests(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'info',
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 9. system_settings
Configurable system settings.

```sql
CREATE TABLE public.system_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    key VARCHAR(100) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Automated Features

### 1. Request Number Generation
Automatic generation of unique request numbers in format: `PQRS-YYYY-XXXXXX`

```sql
CREATE OR REPLACE FUNCTION generate_request_number()
RETURNS TRIGGER AS $$
DECLARE
    year_part VARCHAR(4);
    sequence_part VARCHAR(6);
BEGIN
    year_part := EXTRACT(YEAR FROM NOW())::VARCHAR;
    
    SELECT LPAD((COUNT(*) + 1)::VARCHAR, 6, '0') INTO sequence_part
    FROM public.requests 
    WHERE EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW());
    
    NEW.request_number := 'PQRS-' || year_part || '-' || sequence_part;
    RETURN NEW;
END;
$$ language 'plpgsql';
```

### 2. Automatic Due Date Setting
Sets due dates based on request type:
- Petición, Queja, Reclamo: 15 days
- Sugerencia: 30 days

### 3. Status Change Logging
Automatically logs all status changes for audit purposes.

### 4. Updated Timestamp Triggers
Automatically updates `updated_at` fields when records are modified.

## Row Level Security (RLS)

### Security Model
- **Citizens**: Can only access their own requests and related data
- **Staff (funcionario)**: Can access all requests assigned to them or their department
- **Administrators**: Full access to manage system data
- **Super Administrators**: Complete system access including user management

### Key Policies

#### Users Table
- Users can view and update their own profile
- Staff can view all user profiles
- Only admins can create new users
- Only super admins can delete users

#### Requests Table
- Users can view their own requests
- Staff can view requests assigned to them or their department
- Authenticated users can create requests
- Users can update their own pending requests
- Staff can update any request they have access to

#### Attachments and Responses
- Access follows the same pattern as the parent request
- Internal responses are only visible to staff

## Indexes

Performance indexes are created on frequently queried columns:

```sql
-- Request indexes
CREATE INDEX idx_requests_user_id ON public.requests(user_id);
CREATE INDEX idx_requests_status ON public.requests(status);
CREATE INDEX idx_requests_type ON public.requests(type);
CREATE INDEX idx_requests_category_id ON public.requests(category_id);
CREATE INDEX idx_requests_department_id ON public.requests(department_id);
CREATE INDEX idx_requests_assigned_to ON public.requests(assigned_to);
CREATE INDEX idx_requests_submitted_at ON public.requests(submitted_at);
CREATE INDEX idx_requests_request_number ON public.requests(request_number);

-- Related table indexes
CREATE INDEX idx_request_responses_request_id ON public.request_responses(request_id);
CREATE INDEX idx_request_attachments_request_id ON public.request_attachments(request_id);
CREATE INDEX idx_request_status_history_request_id ON public.request_status_history(request_id);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
```

## Migration Files

1. **001_initial_schema.sql**: Creates all tables, types, functions, and triggers
2. **002_rls_policies.sql**: Implements Row Level Security policies
3. **003_seed_data.sql**: Inserts default categories, departments, and system settings

## Usage Examples

### Creating a New Request
```sql
INSERT INTO public.requests (
    user_id, category_id, department_id, type, subject, description, priority
) VALUES (
    'user-uuid-here',
    'category-uuid-here',
    'department-uuid-here',
    'peticion',
    'Request subject',
    'Detailed description of the request',
    'media'
);
```

### Querying User Requests
```sql
SELECT 
    r.request_number,
    r.subject,
    r.type,
    r.status,
    r.priority,
    r.submitted_at,
    r.due_date,
    c.name as category_name,
    d.name as department_name
FROM public.requests r
LEFT JOIN public.categories c ON r.category_id = c.id
LEFT JOIN public.departments d ON r.department_id = d.id
WHERE r.user_id = 'user-uuid-here'
ORDER BY r.submitted_at DESC;
```

### Getting Request with Responses
```sql
SELECT 
    r.*,
    json_agg(
        json_build_object(
            'id', rr.id,
            'message', rr.message,
            'user_name', u.full_name,
            'is_internal', rr.is_internal,
            'created_at', rr.created_at
        ) ORDER BY rr.created_at
    ) as responses
FROM public.requests r
LEFT JOIN public.request_responses rr ON r.id = rr.request_id
LEFT JOIN public.users u ON rr.user_id = u.id
WHERE r.id = 'request-uuid-here'
GROUP BY r.id;
```

## Best Practices

1. **Always use RLS**: Ensure Row Level Security is enabled and properly configured
2. **Validate input**: Use application-level validation in addition to database constraints
3. **Handle file uploads**: Store files in Supabase Storage and reference paths in the database
4. **Monitor performance**: Use the provided indexes and monitor query performance
5. **Audit trail**: Leverage the status history table for compliance and debugging
6. **Notifications**: Implement proper notification logic for status changes
7. **Backup strategy**: Implement regular backups of the database
8. **Environment separation**: Use separate databases for development, staging, and production
