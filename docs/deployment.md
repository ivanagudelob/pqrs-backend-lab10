# PQRS System Deployment Guide

## Prerequisites

- Supabase account and project
- PostgreSQL 12+ (if self-hosting)
- Node.js 18+ (for local development)
- Git

## Supabase Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Choose your organization and project name
3. Select a database password
4. Choose your region (closest to your users)
5. Wait for project initialization

### 2. Database Configuration

#### Enable Required Extensions

In the Supabase SQL Editor, run:

```sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

#### Run Migrations

Execute the migration files in order:

1. **Initial Schema**
   ```sql
   -- Copy and paste contents of supabase/migrations/001_initial_schema.sql
   ```

2. **RLS Policies**
   ```sql
   -- Copy and paste contents of supabase/migrations/002_rls_policies.sql
   ```

3. **Seed Data**
   ```sql
   -- Copy and paste contents of supabase/migrations/003_seed_data.sql
   ```

### 3. Storage Configuration

#### Create Storage Buckets

In Supabase Dashboard > Storage:

1. Create a bucket named `request-attachments`
2. Set bucket to **Private** (files will be accessed through RLS)
3. Configure RLS policies for the bucket:

```sql
-- Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload files" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'request-attachments' 
    AND auth.role() = 'authenticated'
);

-- Users can view files from their own requests
CREATE POLICY "Users can view own request files" ON storage.objects
FOR SELECT USING (
    bucket_id = 'request-attachments' 
    AND EXISTS (
        SELECT 1 FROM public.request_attachments ra
        JOIN public.requests r ON ra.request_id = r.id
        WHERE ra.file_path = name
        AND (r.user_id = auth.uid() OR is_staff(auth.uid()) OR r.assigned_to = auth.uid())
    )
);

-- Users can delete their own uploaded files
CREATE POLICY "Users can delete own files" ON storage.objects
FOR DELETE USING (
    bucket_id = 'request-attachments' 
    AND EXISTS (
        SELECT 1 FROM public.request_attachments ra
        WHERE ra.file_path = name
        AND ra.uploaded_by = auth.uid()
    )
);
```

### 4. Authentication Configuration

#### Configure Auth Providers

In Supabase Dashboard > Authentication > Providers:

1. **Email**: Enable email authentication
2. **Google** (optional): Configure Google OAuth
3. **Facebook** (optional): Configure Facebook OAuth

#### Email Templates

Customize email templates in Authentication > Email Templates:

- **Confirm signup**: Welcome message with account confirmation
- **Magic Link**: For passwordless login
- **Change Email Address**: Email change confirmation
- **Reset Password**: Password reset instructions

#### Auth Settings

In Authentication > Settings:

- **Site URL**: Set to your frontend application URL
- **Redirect URLs**: Add your application's callback URLs
- **JWT expiry**: Set appropriate session length (default: 1 hour)
- **Refresh token rotation**: Enable for better security

## Environment Variables

### Backend Environment Variables

Create a `.env` file in your backend project:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Database Configuration (if using direct connection)
DATABASE_URL=postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres

# Application Configuration
NODE_ENV=production
PORT=3000
CORS_ORIGIN=https://your-frontend-domain.com

# File Upload Configuration
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=pdf,doc,docx,jpg,jpeg,png,gif,txt
MAX_FILES_PER_REQUEST=5

# Email Configuration (if using custom SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
FROM_EMAIL=noreply@your-domain.com

# Notification Configuration
ENABLE_EMAIL_NOTIFICATIONS=true
ENABLE_SMS_NOTIFICATIONS=false
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=+1234567890

# Security Configuration
JWT_SECRET=your-jwt-secret
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logging Configuration
LOG_LEVEL=info
LOG_FILE=logs/app.log
```

### Frontend Environment Variables

Create a `.env.local` file in your frontend project:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Application Configuration
NEXT_PUBLIC_APP_NAME=Sistema PQRS Municipal
NEXT_PUBLIC_APP_VERSION=1.0.0
NEXT_PUBLIC_API_URL=https://your-backend-api.com

# Feature Flags
NEXT_PUBLIC_ENABLE_ANONYMOUS_REQUESTS=true
NEXT_PUBLIC_ENABLE_FILE_UPLOADS=true
NEXT_PUBLIC_MAX_FILE_SIZE=10485760
NEXT_PUBLIC_ALLOWED_FILE_TYPES=pdf,doc,docx,jpg,jpeg,png,gif,txt

# Google Analytics (optional)
NEXT_PUBLIC_GA_TRACKING_ID=GA_MEASUREMENT_ID

# Contact Information
NEXT_PUBLIC_CONTACT_EMAIL=pqrs@alcaldia.gov.co
NEXT_PUBLIC_CONTACT_PHONE=+57 1 234 5600
NEXT_PUBLIC_OFFICE_ADDRESS=Calle 123 #45-67, Ciudad, Colombia
```

## Deployment Options

### Option 1: Vercel (Frontend) + Supabase (Backend)

#### Frontend Deployment (Vercel)

1. Connect your GitHub repository to Vercel
2. Configure environment variables in Vercel dashboard
3. Deploy automatically on push to main branch

#### Backend API (if needed)

If you need custom API endpoints, deploy to:
- **Vercel Functions**: For serverless functions
- **Railway**: For full Node.js applications
- **Heroku**: Traditional platform-as-a-service
- **DigitalOcean App Platform**: Modern app deployment

### Option 2: Self-Hosted

#### Docker Deployment

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: pqrs_system
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: your-password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./supabase/migrations:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://postgres:your-password@postgres:5432/pqrs_system
      NODE_ENV: production
    ports:
      - "3000:3000"
    depends_on:
      - postgres

  frontend:
    build: ./frontend
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:3000
    ports:
      - "3001:3000"
    depends_on:
      - backend

volumes:
  postgres_data:
```

Run with:
```bash
docker-compose up -d
```

## Initial Setup

### 1. Create Admin User

After deployment, create your first admin user:

1. Sign up through the frontend application
2. In Supabase SQL Editor, run:

```sql
-- Update the user role to super_admin
UPDATE public.users 
SET role = 'super_admin' 
WHERE email = 'your-admin-email@domain.com';
```

### 2. Configure System Settings

Update system settings through the admin interface or SQL:

```sql
-- Update system configuration
UPDATE public.system_settings 
SET value = 'Your Municipality Name' 
WHERE key = 'system_name';

UPDATE public.system_settings 
SET value = 'contact@your-municipality.gov.co' 
WHERE key = 'contact_email';

UPDATE public.system_settings 
SET value = '+57 1 234 5600' 
WHERE key = 'contact_phone';

UPDATE public.system_settings 
SET value = 'Your Office Address' 
WHERE key = 'office_address';
```

### 3. Create Sample Data (Optional)

For testing purposes, create sample requests:

```sql
-- Create sample requests for a user
SELECT create_sample_requests_for_user('user-uuid-here');
```

## Monitoring and Maintenance

### Database Monitoring

Monitor your database through:
- **Supabase Dashboard**: Built-in monitoring and logs
- **PostgreSQL Stats**: Query performance and usage statistics
- **Custom Monitoring**: Set up alerts for high usage or errors

### Backup Strategy

#### Supabase Automatic Backups
- Supabase Pro plans include automatic daily backups
- Point-in-time recovery available
- Manual backup downloads available

#### Custom Backup Script
```bash
#!/bin/bash
# backup-database.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="pqrs_backup_$DATE.sql"

pg_dump "$DATABASE_URL" > "$BACKUP_FILE"
gzip "$BACKUP_FILE"

# Upload to cloud storage (AWS S3, Google Cloud, etc.)
aws s3 cp "$BACKUP_FILE.gz" s3://your-backup-bucket/
```

### Performance Optimization

1. **Monitor Query Performance**
   ```sql
   -- Check slow queries
   SELECT query, mean_time, calls 
   FROM pg_stat_statements 
   ORDER BY mean_time DESC 
   LIMIT 10;
   ```

2. **Index Optimization**
   ```sql
   -- Check index usage
   SELECT schemaname, tablename, attname, n_distinct, correlation 
   FROM pg_stats 
   WHERE schemaname = 'public';
   ```

3. **Connection Pooling**
   - Use PgBouncer for connection pooling
   - Configure appropriate pool sizes
   - Monitor connection usage

## Security Checklist

- [ ] RLS policies are enabled on all tables
- [ ] Service role key is kept secure and not exposed
- [ ] HTTPS is enforced for all connections
- [ ] File upload limits are configured
- [ ] Rate limiting is implemented
- [ ] Input validation is in place
- [ ] Regular security updates are applied
- [ ] Database backups are encrypted
- [ ] Access logs are monitored
- [ ] Two-factor authentication is enabled for admin accounts

## Troubleshooting

### Common Issues

1. **RLS Policy Errors**
   - Check if user is authenticated
   - Verify policy conditions
   - Test with service role for debugging

2. **File Upload Issues**
   - Verify storage bucket configuration
   - Check file size and type restrictions
   - Ensure proper RLS policies on storage

3. **Performance Issues**
   - Check query execution plans
   - Verify indexes are being used
   - Monitor connection pool usage

4. **Authentication Problems**
   - Verify JWT configuration
   - Check redirect URLs
   - Ensure email templates are configured

### Support Resources

- **Supabase Documentation**: [docs.supabase.com](https://docs.supabase.com)
- **PostgreSQL Documentation**: [postgresql.org/docs](https://postgresql.org/docs)
- **Community Support**: Supabase Discord and GitHub discussions

## Scaling Considerations

### Database Scaling
- **Read Replicas**: For read-heavy workloads
- **Connection Pooling**: PgBouncer or similar
- **Partitioning**: For large datasets
- **Archiving**: Move old requests to archive tables

### Application Scaling
- **CDN**: For static assets and file downloads
- **Caching**: Redis for session and query caching
- **Load Balancing**: Multiple application instances
- **Microservices**: Split functionality as needed

### Monitoring at Scale
- **APM Tools**: Application Performance Monitoring
- **Log Aggregation**: Centralized logging
- **Alerting**: Automated alerts for issues
- **Metrics**: Custom business metrics tracking
