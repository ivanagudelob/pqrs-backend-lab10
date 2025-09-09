# PQRS System Database

A comprehensive PostgreSQL/Supabase database schema for managing PQRS (Peticiones, Quejas, Reclamos y Sugerencias) - a citizen request management system for municipal and governmental organizations.

## 🚀 Quick Start

### Prerequisites
- Supabase account
- PostgreSQL 12+ (if self-hosting)
- Basic knowledge of SQL and database management

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pqrs-backend-lab10
   ```

2. **Set up Supabase project**
   - Create a new project at [supabase.com](https://supabase.com)
   - Note your project URL and API keys

3. **Run migrations**
   Execute the SQL files in order in your Supabase SQL Editor:
   ```sql
   -- 1. Run supabase/migrations/001_initial_schema.sql
   -- 2. Run supabase/migrations/002_rls_policies.sql
   -- 3. Run supabase/migrations/003_seed_data.sql
   ```

4. **Configure storage**
   - Create a `request-attachments` bucket in Supabase Storage
   - Set appropriate RLS policies (see deployment guide)

## 📋 Features

### Core Functionality
- ✅ **Multi-type requests**: Peticiones, Quejas, Reclamos, Sugerencias
- ✅ **User management**: Role-based access (citizen, staff, admin)
- ✅ **Request categorization**: 10 default categories
- ✅ **Department routing**: Automatic assignment to government departments
- ✅ **File attachments**: Secure file upload and management
- ✅ **Communication system**: Two-way messaging between citizens and staff
- ✅ **Status tracking**: Complete audit trail
- ✅ **Notifications**: System-wide notification management

### Automated Features
- 🔄 **Request numbering**: Auto-generated PQRS-YYYY-XXXXXX format
- ⏰ **Due date calculation**: Automatic based on request type
- 📊 **Status logging**: Complete audit trail
- 🔐 **User registration**: Automatic profile creation
- 📧 **Notification triggers**: Automated system notifications

### Security
- 🛡️ **Row Level Security**: Comprehensive RLS policies
- 👥 **Role-based access**: Granular permissions system
- 🔒 **Data isolation**: Users only see their own data
- 📁 **Secure file handling**: Integrated with Supabase Storage
- 🔍 **Audit trail**: Complete change history

## 📊 Database Schema

### Main Tables
| Table | Purpose |
|-------|---------|
| `users` | Extended user profiles with government-specific fields |
| `categories` | Request categorization system |
| `departments` | Government departments for routing |
| `requests` | Main PQRS requests with metadata |
| `request_attachments` | File attachment management |
| `request_responses` | Communication threads |
| `request_status_history` | Complete audit trail |
| `notifications` | User notifications |
| `system_settings` | Configurable parameters |

### Request Types
- **Petición**: Formal request for information or action
- **Queja**: Complaint about service quality
- **Reclamo**: Claim about rights violation
- **Sugerencia**: Suggestion for improvement

### Status Flow
```
pendiente → en_proceso → resuelto → cerrado
    ↓
rechazado
```

## 🔧 Configuration

### Default Categories
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

### System Settings
Key configurations available through `system_settings` table:
- File upload limits and types
- Response time defaults
- Contact information
- Feature toggles
- Notification preferences

## 📚 Documentation

Comprehensive documentation is available in the `/docs` folder:

- **[Database Schema](docs/database.md)**: Detailed table descriptions and relationships
- **[Deployment Guide](docs/deployment.md)**: Step-by-step setup instructions
- **[System Summary](docs/summary.md)**: Project overview and features
- **[Changelog](docs/changelog.md)**: Version history and updates

## 🚀 Deployment

### Supabase (Recommended)
1. Create Supabase project
2. Run migration files
3. Configure storage and authentication
4. Set up RLS policies

### Self-Hosted
1. Set up PostgreSQL 12+
2. Install required extensions
3. Run migrations
4. Configure application connections

See the [Deployment Guide](docs/deployment.md) for detailed instructions.

## 🔒 Security Model

### User Roles
- **Ciudadano**: Regular citizens who submit requests
- **Funcionario**: Government staff who handle requests
- **Administrador**: System administrators
- **Super Admin**: Full system access

### Access Control
- Citizens can only access their own requests
- Staff can access assigned requests
- Admins have full system access
- All access controlled through RLS policies

## 📈 Performance

### Optimizations
- Strategic indexing on frequently queried columns
- Efficient relationship design
- Optimized data types
- Query performance considerations

### Monitoring
- Built-in Supabase monitoring
- Custom query performance tracking
- Automated backup strategies
- Scalability considerations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Guidelines
- Follow SQL best practices
- Maintain backward compatibility
- Update documentation
- Include migration scripts
- Test RLS policies

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help
- Check the [documentation](docs/)
- Search existing issues
- Create a new issue with details
- Join community discussions

### Common Issues
- **RLS Policy Errors**: Check authentication and policy conditions
- **File Upload Issues**: Verify storage configuration
- **Performance Issues**: Review query execution plans
- **Migration Problems**: Ensure proper order and prerequisites

## 🗺️ Roadmap

### Version 1.1.0
- Multi-language support
- Advanced reporting
- Workflow automation
- Integration APIs

### Version 1.2.0
- Analytics dashboard
- Bulk operations
- Advanced search
- Document templates

## 📊 Stats

- **9 Core Tables**: Comprehensive data model
- **4 Custom Types**: Tailored for government use
- **25+ Indexes**: Optimized performance
- **50+ RLS Policies**: Granular security
- **3 Migration Files**: Organized deployment

---

**Built with ❤️ for better citizen services**

For detailed technical information, please refer to the [Database Documentation](docs/database.md).
