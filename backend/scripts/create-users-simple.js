// Direct Supabase user creation script
// Usage: node create-users-simple.js
// Make sure to set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in your environment

const { createClient } = require('@supabase/supabase-js');

// Read from .env file if it exists
try {
  require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
} catch (e) {
  // dotenv not available
}

const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('\n❌ ERROR: Missing environment variables!');
  console.error('Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY');
  console.error('\nYou can either:');
  console.error('1. Create a .env file in the backend directory with:');
  console.error('   SUPABASE_URL=your_url');
  console.error('   SUPABASE_SERVICE_ROLE_KEY=your_key');
  console.error('\n2. Or set them as environment variables before running:');
  console.error('   set SUPABASE_URL=your_url && set SUPABASE_SERVICE_ROLE_KEY=your_key && node create-users-simple.js');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

const users = [
  { email: 'customer1@test.com', password: 'password123', name: 'John Customer', role: 'customer' },
  { email: 'customer2@test.com', password: 'password123', name: 'Sarah Customer', role: 'customer' },
  { email: 'owner1@test.com', password: 'password123', name: 'Mike Owner', role: 'owner' },
  { email: 'owner2@test.com', password: 'password123', name: 'Lisa Owner', role: 'owner' },
  { email: 'admin@test.com', password: 'password123', name: 'Admin User', role: 'admin' },
];

async function createUsers() {
  console.log('🌱 Creating test users in Supabase Auth...\n');
  console.log(`Supabase URL: ${supabaseUrl.substring(0, 30)}...\n`);

  for (const userData of users) {
    try {
      // Check if user exists
      const { data: allUsers } = await supabase.auth.admin.listUsers();
      const existing = allUsers?.users?.find(u => u.email === userData.email);

      if (existing) {
        console.log(`⚠️  ${userData.email} already exists, updating...`);
        
        // Update existing user
        await supabase.auth.admin.updateUserById(existing.id, {
          email_confirm: true,
          user_metadata: { name: userData.name },
        });

        // Update users table
        const { error: updateError } = await supabase
          .from('users')
          .update({
            name: userData.name,
            role: userData.role,
            phone: userData.email,
          })
          .eq('id', existing.id);

        if (updateError) {
          console.log(`   ❌ Failed to update users table: ${updateError.message}`);
        } else {
          console.log(`   ✅ Updated successfully`);
        }
      } else {
        // Create new user
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          email: userData.email,
          password: userData.password,
          email_confirm: true,
          user_metadata: { name: userData.name },
        });

        if (authError) {
          console.log(`❌ Failed to create ${userData.email}: ${authError.message}`);
          continue;
        }

        if (!authData.user) {
          console.log(`❌ No user data returned for ${userData.email}`);
          continue;
        }

        // Create in users table
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
          // Try to delete auth user
          await supabase.auth.admin.deleteUser(authData.user.id);
        } else {
          console.log(`✅ Created: ${userData.email} (${userData.role})`);
        }
      }
    } catch (error) {
      console.log(`❌ Error with ${userData.email}: ${error.message}`);
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
  console.log('✅ Check Supabase Dashboard > Authentication > Users to verify!');
}

createUsers()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  });

