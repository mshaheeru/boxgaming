// Working user creation script
// This script will create users and show detailed output

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Try to load .env
const envPath = path.join(__dirname, '../.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const [key, ...valueParts] = line.split('=');
    if (key && valueParts.length > 0) {
      const value = valueParts.join('=').trim().replace(/^["']|["']$/g, '');
      process.env[key.trim()] = value;
    }
  });
  console.log('✅ Loaded .env file\n');
} else {
  console.log('⚠️  .env file not found, using process.env\n');
}

const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('❌ ERROR: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  console.error('\nPlease create a .env file in the backend directory with:');
  console.error('SUPABASE_URL=https://your-project.supabase.co');
  console.error('SUPABASE_SERVICE_ROLE_KEY=your_service_role_key');
  console.error('\nOr set them as environment variables.');
  process.exit(1);
}

console.log(`Using Supabase URL: ${supabaseUrl.substring(0, 40)}...`);
console.log(`Service Role Key: ${serviceRoleKey.substring(0, 20)}...\n`);

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
  console.log('🌱 Creating test users...\n');

  for (const userData of users) {
    try {
      console.log(`Processing: ${userData.email}...`);
      
      // Check if user exists
      const { data: allUsers, error: listError } = await supabase.auth.admin.listUsers();
      
      if (listError) {
        console.log(`   ❌ Error listing users: ${listError.message}`);
        continue;
      }

      const existing = allUsers?.users?.find(u => u.email === userData.email);

      if (existing) {
        console.log(`   ⚠️  User exists, updating...`);
        
        const { error: updateError } = await supabase.auth.admin.updateUserById(existing.id, {
          email_confirm: true,
          user_metadata: { name: userData.name },
        });

        if (updateError) {
          console.log(`   ❌ Auth update failed: ${updateError.message}`);
        }

        const { error: tableError } = await supabase
          .from('users')
          .update({
            name: userData.name,
            role: userData.role,
            phone: userData.email,
          })
          .eq('id', existing.id);

        if (tableError) {
          console.log(`   ❌ Table update failed: ${tableError.message}`);
        } else {
          console.log(`   ✅ Updated successfully`);
        }
      } else {
        console.log(`   Creating new user...`);
        
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          email: userData.email,
          password: userData.password,
          email_confirm: true,
          user_metadata: { name: userData.name },
        });

        if (authError) {
          console.log(`   ❌ Auth creation failed: ${authError.message}`);
          continue;
        }

        if (!authData?.user) {
          console.log(`   ❌ No user data returned`);
          continue;
        }

        console.log(`   ✅ Auth user created: ${authData.user.id}`);

        const { error: userError } = await supabase
          .from('users')
          .insert({
            id: authData.user.id,
            phone: userData.email,
            name: userData.name,
            role: userData.role,
          });

        if (userError) {
          console.log(`   ❌ Table insert failed: ${userError.message}`);
          await supabase.auth.admin.deleteUser(authData.user.id);
        } else {
          console.log(`   ✅ User record created`);
          console.log(`   ✅ Successfully created: ${userData.email} (${userData.role})\n`);
        }
      }
    } catch (error) {
      console.log(`   ❌ Exception: ${error.message}\n`);
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
  console.log('✅ Check Supabase Dashboard > Authentication > Users to verify!\n');
}

createUsers()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  });

