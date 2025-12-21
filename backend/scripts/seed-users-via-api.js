// Seed users by calling the backend API signup endpoint
const http = require('http');

// Get API URL from environment or use default
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3001/api/v1';

const testUsers = [
  { email: 'customer1@test.com', password: 'password123', name: 'John Customer' },
  { email: 'customer2@test.com', password: 'password123', name: 'Sarah Customer' },
  { email: 'owner1@test.com', password: 'password123', name: 'Mike Owner' },
  { email: 'owner2@test.com', password: 'password123', name: 'Lisa Owner' },
  { email: 'admin@test.com', password: 'password123', name: 'Admin User' },
];

function makeRequest(url, data) {
  return new Promise((resolve, reject) => {
    try {
      const urlObj = new URL(url);
      const postData = JSON.stringify(data);

      const options = {
        hostname: urlObj.hostname,
        port: urlObj.port || (urlObj.protocol === 'https:' ? 443 : 80),
        path: urlObj.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
        },
      };

      const req = http.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => { body += chunk; });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(body);
            resolve({ status: res.statusCode, data: parsed });
          } catch (e) {
            resolve({ status: res.statusCode, data: body });
          }
        });
      });

      req.on('error', reject);
      req.setTimeout(10000, () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });
      req.write(postData);
      req.end();
    } catch (error) {
      reject(error);
    }
  });
}

async function seedUsers() {
  console.log('🌱 Seeding test users via API...\n');
  console.log(`Using API: ${API_BASE_URL}\n`);

  for (const userData of testUsers) {
    try {
      console.log(`Creating user: ${userData.email}...`);
      const response = await makeRequest(`${API_BASE_URL}/auth/signup`, {
        email: userData.email,
        password: userData.password,
        name: userData.name,
      });

      if (response.status === 201 || response.status === 200) {
        console.log(`✅ Created: ${userData.email}`);
      } else {
        const errorMsg = response.data?.message || response.data?.error || 'Unknown error';
        if (errorMsg.includes('already') || errorMsg.includes('exists')) {
          console.log(`⚠️  ${userData.email}: Already exists`);
        } else {
          console.log(`❌ ${userData.email}: ${errorMsg}`);
        }
      }
    } catch (error) {
      console.log(`❌ Error creating ${userData.email}: ${error.message}`);
      if (error.message.includes('ECONNREFUSED')) {
        console.log('   Make sure your backend server is running on port 3001');
      }
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
  console.log('⚠️  Note: After signup, user roles need to be updated manually in Supabase');
  console.log('   Go to Supabase Dashboard > Table Editor > users table');
  console.log('   Update the role column for each user (customer/owner/admin)\n');
}

seedUsers().then(() => {
  console.log('✅ User seeding completed!');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});

