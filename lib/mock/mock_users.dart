import '../core/enums/user_role.dart';
import '../shared/models/user_model.dart';

class MockUsers {
  static const UserModel standardUser = UserModel(
    id: 'u1',
    name: 'Standard User',
    email: 'user@example.com',
    role: UserRole.user,
  );

  static const UserModel adminUser = UserModel(
    id: 'a1',
    name: 'Admin User',
    email: 'admin@example.com',
    role: UserRole.admin,
  );

  static const UserModel superAdminUser = UserModel(
    id: 'sa1',
    name: 'Super Admin',
    email: 'super@example.com',
    role: UserRole.superAdmin,
  );
  
  // Toggle this to test different roles
  static const UserModel currentUser = standardUser; 
}
