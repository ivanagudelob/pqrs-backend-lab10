-- Seed Data for PQRS System
-- Migration: 003_seed_data.sql

-- Insert default categories
INSERT INTO public.categories (id, name, description, color) VALUES
    (uuid_generate_v4(), 'Servicios Públicos', 'Peticiones relacionadas con servicios públicos básicos', '#3B82F6'),
    (uuid_generate_v4(), 'Atención al Ciudadano', 'Quejas sobre atención recibida en oficinas públicas', '#EF4444'),
    (uuid_generate_v4(), 'Infraestructura', 'Reclamos sobre estado de vías, parques y espacios públicos', '#F59E0B'),
    (uuid_generate_v4(), 'Seguridad', 'Peticiones relacionadas con seguridad ciudadana', '#DC2626'),
    (uuid_generate_v4(), 'Medio Ambiente', 'Sugerencias y quejas ambientales', '#10B981'),
    (uuid_generate_v4(), 'Salud', 'Peticiones relacionadas con servicios de salud', '#8B5CF6'),
    (uuid_generate_v4(), 'Educación', 'Peticiones sobre servicios educativos', '#06B6D4'),
    (uuid_generate_v4(), 'Transporte', 'Quejas y sugerencias sobre transporte público', '#F97316'),
    (uuid_generate_v4(), 'Trámites y Documentos', 'Reclamos sobre procesos administrativos', '#6366F1'),
    (uuid_generate_v4(), 'Otros', 'Otras peticiones no clasificadas', '#6B7280');

-- Insert default departments
INSERT INTO public.departments (id, name, description, email, phone) VALUES
    (uuid_generate_v4(), 'Secretaría General', 'Departamento encargado de la coordinación general', 'secretaria@alcaldia.gov.co', '+57 1 234 5678'),
    (uuid_generate_v4(), 'Servicios Públicos', 'Departamento de servicios públicos domiciliarios', 'servicios@alcaldia.gov.co', '+57 1 234 5679'),
    (uuid_generate_v4(), 'Infraestructura y Obras', 'Departamento de obras públicas e infraestructura', 'obras@alcaldia.gov.co', '+57 1 234 5680'),
    (uuid_generate_v4(), 'Seguridad y Convivencia', 'Departamento de seguridad ciudadana', 'seguridad@alcaldia.gov.co', '+57 1 234 5681'),
    (uuid_generate_v4(), 'Medio Ambiente', 'Departamento de gestión ambiental', 'ambiente@alcaldia.gov.co', '+57 1 234 5682'),
    (uuid_generate_v4(), 'Salud', 'Departamento de salud pública', 'salud@alcaldia.gov.co', '+57 1 234 5683'),
    (uuid_generate_v4(), 'Educación', 'Departamento de educación municipal', 'educacion@alcaldia.gov.co', '+57 1 234 5684'),
    (uuid_generate_v4(), 'Movilidad', 'Departamento de tránsito y transporte', 'movilidad@alcaldia.gov.co', '+57 1 234 5685'),
    (uuid_generate_v4(), 'Atención al Ciudadano', 'Oficina de atención al ciudadano', 'atencion@alcaldia.gov.co', '+57 1 234 5686');

-- Insert default system settings
INSERT INTO public.system_settings (key, value, description, is_public) VALUES
    ('system_name', 'Sistema PQRS Municipal', 'Nombre del sistema', true),
    ('system_version', '1.0.0', 'Versión actual del sistema', true),
    ('max_file_size', '10485760', 'Tamaño máximo de archivo en bytes (10MB)', false),
    ('allowed_file_types', 'pdf,doc,docx,jpg,jpeg,png,gif,txt', 'Tipos de archivo permitidos', false),
    ('default_response_time_days', '15', 'Tiempo de respuesta por defecto en días', true),
    ('max_attachments_per_request', '5', 'Número máximo de archivos adjuntos por solicitud', true),
    ('enable_anonymous_requests', 'true', 'Permitir solicitudes anónimas', true),
    ('enable_email_notifications', 'true', 'Habilitar notificaciones por email', false),
    ('enable_sms_notifications', 'false', 'Habilitar notificaciones por SMS', false),
    ('contact_email', 'pqrs@alcaldia.gov.co', 'Email de contacto principal', true),
    ('contact_phone', '+57 1 234 5600', 'Teléfono de contacto principal', true),
    ('office_address', 'Calle 123 #45-67, Ciudad, Colombia', 'Dirección de la oficina principal', true),
    ('office_hours', 'Lunes a Viernes: 8:00 AM - 5:00 PM', 'Horarios de atención', true),
    ('privacy_policy_url', '/privacy-policy', 'URL de la política de privacidad', true),
    ('terms_of_service_url', '/terms-of-service', 'URL de los términos de servicio', true);

-- Create a function to insert a demo admin user (to be called after auth user is created)
CREATE OR REPLACE FUNCTION create_demo_admin(
    user_id UUID,
    email VARCHAR(255),
    full_name VARCHAR(255)
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.users (
        id, 
        email, 
        full_name, 
        document_type, 
        document_number, 
        role,
        city,
        department
    ) VALUES (
        user_id,
        email,
        full_name,
        'cedula',
        '12345678',
        'super_admin',
        'Bogotá',
        'Cundinamarca'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, document_type, document_number)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
        'cedula',
        COALESCE(NEW.raw_user_meta_data->>'document_number', 'pendiente')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create a function to generate sample requests (for testing)
CREATE OR REPLACE FUNCTION create_sample_requests()
RETURNS VOID AS $$
DECLARE
    sample_user_id UUID;
    category_servicios UUID;
    category_atencion UUID;
    dept_servicios UUID;
    dept_atencion UUID;
BEGIN
    -- Get IDs for sample data
    SELECT id INTO category_servicios FROM public.categories WHERE name = 'Servicios Públicos' LIMIT 1;
    SELECT id INTO category_atencion FROM public.categories WHERE name = 'Atención al Ciudadano' LIMIT 1;
    SELECT id INTO dept_servicios FROM public.departments WHERE name = 'Servicios Públicos' LIMIT 1;
    SELECT id INTO dept_atencion FROM public.departments WHERE name = 'Atención al Ciudadano' LIMIT 1;
    
    -- Note: This function should be called after creating a test user
    -- The actual user_id should be passed or retrieved from existing users
    
    RAISE NOTICE 'Sample data structure created. Use create_sample_requests_for_user(user_id) to create sample requests for a specific user.';
END;
$$ LANGUAGE plpgsql;

-- Create a function to generate sample requests for a specific user
CREATE OR REPLACE FUNCTION create_sample_requests_for_user(user_id UUID)
RETURNS VOID AS $$
DECLARE
    category_servicios UUID;
    category_atencion UUID;
    dept_servicios UUID;
    dept_atencion UUID;
    request_id UUID;
BEGIN
    -- Get IDs for sample data
    SELECT id INTO category_servicios FROM public.categories WHERE name = 'Servicios Públicos' LIMIT 1;
    SELECT id INTO category_atencion FROM public.categories WHERE name = 'Atención al Ciudadano' LIMIT 1;
    SELECT id INTO dept_servicios FROM public.departments WHERE name = 'Servicios Públicos' LIMIT 1;
    SELECT id INTO dept_atencion FROM public.departments WHERE name = 'Atención al Ciudadano' LIMIT 1;
    
    -- Create sample petición
    INSERT INTO public.requests (
        user_id, category_id, department_id, type, subject, description, priority, status
    ) VALUES (
        user_id, category_servicios, dept_servicios, 'peticion',
        'Solicitud de mejora en el servicio de agua potable',
        'Solicito se mejore la presión del agua en el sector de la Calle 45 con Carrera 20, ya que en horas de la mañana el servicio es muy deficiente.',
        'media', 'pendiente'
    ) RETURNING id INTO request_id;
    
    -- Add a response to the sample request
    INSERT INTO public.request_responses (request_id, user_id, message, is_internal) VALUES (
        request_id, user_id, 'Adjunto evidencias fotográficas del problema.', false
    );
    
    -- Create sample queja
    INSERT INTO public.requests (
        user_id, category_id, department_id, type, subject, description, priority, status
    ) VALUES (
        user_id, category_atencion, dept_atencion, 'queja',
        'Mala atención en oficina de atención al ciudadano',
        'El día de ayer fui a realizar un trámite y la atención fue muy deficiente. El funcionario fue grosero y no me brindó la información solicitada.',
        'alta', 'en_proceso'
    );
    
    -- Create sample sugerencia
    INSERT INTO public.requests (
        user_id, category_id, department_id, type, subject, description, priority, status
    ) VALUES (
        user_id, category_servicios, dept_servicios, 'sugerencia',
        'Implementar sistema de citas en línea',
        'Sugiero implementar un sistema de citas en línea para evitar las largas filas en las oficinas de atención al ciudadano.',
        'baja', 'pendiente'
    );
    
    RAISE NOTICE 'Sample requests created successfully for user %', user_id;
END;
$$ LANGUAGE plpgsql;

-- Create indexes for better performance on frequently queried columns
CREATE INDEX IF NOT EXISTS idx_categories_name ON public.categories(name);
CREATE INDEX IF NOT EXISTS idx_departments_name ON public.departments(name);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON public.system_settings(key);
CREATE INDEX IF NOT EXISTS idx_users_document_number ON public.users(document_number);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
