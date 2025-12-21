// Simple script to seed users - reads env vars from process.env
// Make sure SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set

const { createClient } = require('@supabase/supabase-js');

// Try to load .env if dotenv is available, otherwise use process.env
try {
  require('dotenv').config();
} catch (e) {
  // dotenv not available, use process.env directly
}

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceRoleKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  console.error('Please set these in your .env file or environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

const testUsers = [
  { email: 'customer1@test.com', password: 'password123', name: 'John Customer', role: 'customer' },
  { email: 'customer2@test.com', password: 'password123', name: 'Sarah Customer', role: 'customer' },
  { email: 'owner1@test.com', password: 'password123', name: 'Mike Owner', role: 'owner' },
  { email: 'owner2@test.com', password: 'password123', name: 'Lisa Owner', role: 'owner' },
  { email: 'admin@test.com', password: 'password123', name: 'Admin User', role: 'admin' },
];

async function seedUsers() {
  console.log('🌱 Seeding test users...\n');

  for (const userData of testUsers) {
    try {
      const { data: existingUsers } = await supabase.auth.admin.listUsers();
      const existingUser = existingUsers?.users?.find((u) => u.email === userData.email);

      if (existingUser) {
        console.log(`⚠️  User ${userData.email} already exists, updating...`);
        await supabase.auth.admin.updateUserById(existingUser.id, {
          email_confirm: true,
          user_metadata: { name: userData.name },
        });
        const { error: updateError } = await supabase
          .from('users')
          .update({ name: userData.name, role: userData.role, phone: userData.email })
          .eq('id', existingUser.id);
        if (updateError) {
          console.log(`❌ Failed to update: ${updateError.message}`);
        } else {
          console.log(`✅ Updated: ${userData.email} (${userData.role})`);
        }
      } else {
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          email: userData.email,
          password: userData.password,
          email_confirm: true,
          user_metadata: { name: userData.name },
        });

        if (authError || !authData.user) {
          console.log(`❌ Failed to create auth: ${authError?.message}`);
          continue;
        }

        const { error: userError } = await supabase
          .from('users')
          .insert({
            id: authData.user.id,
            phone: userData.email,
            name: userData.name,
            role: userData.role,
          });

        if (userError) {
          console.log(`❌ Failed to create user record: ${userError.message}`);
          await supabase.auth.admin.deleteUser(authData.user.id);
        } else {
          console.log(`✅ Created: ${userData.email} (${userData.role})`);
        }
      }
    } catch (error) {
      console.log(`❌ Error: ${error.message}`);
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

seedUsers().then(() => process.exit(0)).catch((error) => {
  console.error('❌ Error:', error);
  process.exit(1);
});

