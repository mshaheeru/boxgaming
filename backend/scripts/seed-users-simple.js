const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceRoleKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

const testUsers = [
  // Customer users
  {
    email: 'customer1@test.com',
    password: 'password123',
    name: 'John Customer',
    role: 'customer',
  },
  {
    email: 'customer2@test.com',
    password: 'password123',
    name: 'Sarah Customer',
    role: 'customer',
  },
  // Owner users
  {
    email: 'owner1@test.com',
    password: 'password123',
    name: 'Mike Owner',
    role: 'owner',
  },
  {
    email: 'owner2@test.com',
    password: 'password123',
    name: 'Lisa Owner',
    role: 'owner',
  },
  // Admin user
  {
    email: 'admin@test.com',
    password: 'password123',
    name: 'Admin User',
    role: 'admin',
  },
];

async function seedUsers() {
  console.log('🌱 Seeding test users...\n');

  for (const userData of testUsers) {
    try {
      // Check if user already exists in auth
      const { data: existingUsers } = await supabase.auth.admin.listUsers();
      const existingUser = existingUsers?.users?.find((u) => u.email === userData.email);

      if (existingUser) {
        console.log(`⚠️  User ${userData.email} already exists, updating...`);
        
        // Update user in auth
        await supabase.auth.admin.updateUserById(existingUser.id, {
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
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
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
          await supabase.auth.admin.deleteUser(authData.user.id);
        } else {
          console.log(`✅ Created user: ${userData.email} (${userData.role})`);
        }
      }
    } catch (error) {
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
  console.log('✅ User seeding completed!');
}

seedUsers()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error seeding users:', error);
    process.exit(1);
  });

