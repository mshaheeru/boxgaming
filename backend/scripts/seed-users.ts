import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { SupabaseService } from '../src/supabase/supabase.service';

async function seedUsers() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const supabaseService = app.get(SupabaseService);
  const adminAuth = supabaseService.getAdminClient().auth.admin;
  const supabase = supabaseService.getAdminClient();

  const testUsers = [
    // Customer users
    {
      email: 'customer1@test.com',
      password: 'password123',
      name: 'John Customer',
      role: 'customer' as const,
    },
    {
      email: 'customer2@test.com',
      password: 'password123',
      name: 'Sarah Customer',
      role: 'customer' as const,
    },
    // Owner users
    {
      email: 'owner1@test.com',
      password: 'password123',
      name: 'Mike Owner',
      role: 'owner' as const,
    },
    {
      email: 'owner2@test.com',
      password: 'password123',
      name: 'Lisa Owner',
      role: 'owner' as const,
    },
    // Admin user
    {
      email: 'admin@test.com',
      password: 'password123',
      name: 'Admin User',
      role: 'admin' as const,
    },
  ];

  console.log('🌱 Seeding test users...\n');

  for (const userData of testUsers) {
    try {
      // Check if user already exists in auth
      const { data: existingUsers } = await adminAuth.listUsers();
      const existingUser = existingUsers?.users?.find((u: any) => u.email === userData.email);

      if (existingUser) {
        console.log(`⚠️  User ${userData.email} already exists, updating...`);
        
        // Update user in auth
        await adminAuth.updateUserById(existingUser.id, {
          email_confirm: true,
          user_metadata: { name: userData.name },
        });

        // Update user in users table
        const { error: updateError } = await supabase
          .from('users')
          .update({
            name: userData.name,
            role: userData.role,
            phone: userData.email, // Using email as phone
          })
          .eq('id', existingUser.id);

        if (updateError) {
          console.log(`❌ Failed to update user ${userData.email}: ${updateError.message}`);
        } else {
          console.log(`✅ Updated user: ${userData.email} (${userData.role})`);
        }
      } else {
        // Create new user in Supabase Auth
        const { data: authData, error: authError } = await adminAuth.createUser({
          email: userData.email,
          password: userData.password,
          email_confirm: true,
          user_metadata: {
            name: userData.name,
          },
        });

        if (authError || !authData.user) {
          console.log(`❌ Failed to create auth user ${userData.email}: ${authError?.message}`);
          continue;
        }

        // Create user in users table
        const { error: userError } = await supabase
          .from('users')
          .insert({
            id: authData.user.id,
            phone: userData.email, // Using email as phone
            name: userData.name,
            role: userData.role,
          });

        if (userError) {
          console.log(`❌ Failed to create user record ${userData.email}: ${userError.message}`);
          // Try to delete auth user if user creation fails
          await adminAuth.deleteUser(authData.user.id);
        } else {
          console.log(`✅ Created user: ${userData.email} (${userData.role})`);
        }
      }
    } catch (error: any) {
      console.log(`❌ Error creating user ${userData.email}: ${error.message}`);
    }
  }

  console.log('\n📋 Test User Credentials:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('CUSTOMERS:');
  console.log('  Email: customer1@test.com | Password: password123');
  console.log('  Email: customer2@test.com | Password: password123');
  console.log('\nOWNERS:');
  console.log('  Email: owner1@test.com | Password: password123');
  console.log('  Email: owner2@test.com | Password: password123');
  console.log('\nADMIN:');
  console.log('  Email: admin@test.com | Password: password123');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  await app.close();
}

seedUsers()
  .then(() => {
    console.log('✅ User seeding completed!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error seeding users:', error);
    process.exit(1);
  });

