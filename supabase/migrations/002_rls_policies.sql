-- Row Level Security (RLS) Policies for PQRS System
-- Migration: 002_rls_policies.sql

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.request_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.request_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.request_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = user_id 
        AND role IN ('administrador', 'super_admin')
        AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is funcionario or admin
CREATE OR REPLACE FUNCTION is_staff(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = user_id 
        AND role IN ('funcionario', 'administrador', 'super_admin')
        AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- USERS TABLE POLICIES
-- Users can view their own profile and staff can view all users
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id OR is_staff(auth.uid()));

-- Users can update their own profile, staff can update any user
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id OR is_staff(auth.uid()));

-- Only admins can insert new users (registration handled by auth)
CREATE POLICY "Admins can insert users" ON public.users
    FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Only super admins can delete users
CREATE POLICY "Super admins can delete users" ON public.users
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'super_admin'
        )
    );

-- CATEGORIES TABLE POLICIES
-- Everyone can view active categories
CREATE POLICY "Everyone can view active categories" ON public.categories
    FOR SELECT USING (is_active = true OR is_staff(auth.uid()));

-- Only staff can manage categories
CREATE POLICY "Staff can manage categories" ON public.categories
    FOR ALL USING (is_staff(auth.uid()));

-- DEPARTMENTS TABLE POLICIES
-- Everyone can view active departments
CREATE POLICY "Everyone can view active departments" ON public.departments
    FOR SELECT USING (is_active = true OR is_staff(auth.uid()));

-- Only staff can manage departments
CREATE POLICY "Staff can manage departments" ON public.departments
    FOR ALL USING (is_staff(auth.uid()));

-- REQUESTS TABLE POLICIES
-- Users can view their own requests, staff can view all requests
CREATE POLICY "Users can view own requests" ON public.requests
    FOR SELECT USING (
        auth.uid() = user_id OR 
        is_staff(auth.uid()) OR
        auth.uid() = assigned_to
    );

-- Authenticated users can create requests
CREATE POLICY "Authenticated users can create requests" ON public.requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own requests (limited fields), staff can update any request
CREATE POLICY "Users can update own requests" ON public.requests
    FOR UPDATE USING (
        (auth.uid() = user_id AND status = 'pendiente') OR 
        is_staff(auth.uid()) OR
        auth.uid() = assigned_to
    );

-- Only admins can delete requests
CREATE POLICY "Admins can delete requests" ON public.requests
    FOR DELETE USING (is_admin(auth.uid()));

-- REQUEST ATTACHMENTS POLICIES
-- Users can view attachments of their requests, staff can view all
CREATE POLICY "Users can view own request attachments" ON public.request_attachments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.requests r 
            WHERE r.id = request_id 
            AND (r.user_id = auth.uid() OR is_staff(auth.uid()) OR r.assigned_to = auth.uid())
        )
    );

-- Users can upload attachments to their requests, staff can upload to any
CREATE POLICY "Users can upload to own requests" ON public.request_attachments
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.requests r 
            WHERE r.id = request_id 
            AND (r.user_id = auth.uid() OR is_staff(auth.uid()) OR r.assigned_to = auth.uid())
        )
    );

-- Users can delete their own attachments, staff can delete any
CREATE POLICY "Users can delete own attachments" ON public.request_attachments
    FOR DELETE USING (
        uploaded_by = auth.uid() OR 
        is_staff(auth.uid()) OR
        EXISTS (
            SELECT 1 FROM public.requests r 
            WHERE r.id = request_id AND r.user_id = auth.uid()
        )
    );

-- REQUEST RESPONSES POLICIES
-- Users can view responses to their requests, staff can view all
CREATE POLICY "Users can view responses to own requests" ON public.request_responses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.requests r 
            WHERE r.id = request_id 
            AND (r.user_id = auth.uid() OR is_staff(auth.uid()) OR r.assigned_to = auth.uid())
        ) AND (is_internal = false OR is_staff(auth.uid()))
    );

-- Users can respond to their requests, staff can respond to any
CREATE POLICY "Users can respond to own requests" ON public.request_responses
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.requests r 
            WHERE r.id = request_id 
            AND (r.user_id = auth.uid() OR is_staff(auth.uid()) OR r.assigned_to = auth.uid())
        )
    );

-- Users can update their own responses, staff can update any
CREATE POLICY "Users can update own responses" ON public.request_responses
    FOR UPDATE USING (
        auth.uid() = user_id OR 
        is_staff(auth.uid())
    );

-- Users can delete their own responses, staff can delete any
CREATE POLICY "Users can delete own responses" ON public.request_responses
    FOR DELETE USING (
        auth.uid() = user_id OR 
        is_staff(auth.uid())
    );

-- REQUEST STATUS HISTORY POLICIES
-- Users can view status history of their requests, staff can view all
CREATE POLICY "Users can view status history of own requests" ON public.request_status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.requests r 
            WHERE r.id = request_id 
            AND (r.user_id = auth.uid() OR is_staff(auth.uid()) OR r.assigned_to = auth.uid())
        )
    );

-- Only system can insert status history (via triggers)
-- Staff can manually insert if needed
CREATE POLICY "Staff can insert status history" ON public.request_status_history
    FOR INSERT WITH CHECK (is_staff(auth.uid()));

-- NOTIFICATIONS POLICIES
-- Users can only view their own notifications
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Staff can create notifications for any user
CREATE POLICY "Staff can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (is_staff(auth.uid()));

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications" ON public.notifications
    FOR DELETE USING (auth.uid() = user_id);

-- SYSTEM SETTINGS POLICIES
-- Everyone can view public settings, staff can view all
CREATE POLICY "View system settings" ON public.system_settings
    FOR SELECT USING (is_public = true OR is_staff(auth.uid()));

-- Only admins can manage system settings
CREATE POLICY "Admins can manage system settings" ON public.system_settings
    FOR ALL USING (is_admin(auth.uid()));

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to service role for server-side operations
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
