// Seed users by calling the backend API signup endpoint
const http = require('http');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3001/api/v1';

const testUsers = [
  { email: 'customer1@test.com', password: 'password123', name: 'John Customer', role: 'customer' },
  { email: 'customer2@test.com', password: 'password123', name: 'Sarah Customer', role: 'customer' },
  { email: 'owner1@test.com', password: 'password123', name: 'Mike Owner', role: 'owner' },
  { email: 'owner2@test.com', password: 'password123', name: 'Lisa Owner', role: 'owner' },
  { email: 'admin@test.com', password: 'password123', name: 'Admin User', role: 'admin' },
];

function makeRequest(url, data) {
  return new Promise((resolve, reject) => {
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
    req.write(postData);
    req.end();
  });
}

async function seedUsers() {
  console.log('🌱 Seeding test users via API...\n');
  console.log(`Using API: ${API_BASE_URL}\n`);

  for (const userData of testUsers) {
    try {
      const response = await makeRequest(`${API_BASE_URL}/auth/signup`, {
        email: userData.email,
        password: userData.password,
        name: userData.name,
      });

      if (response.status === 201 || response.status === 200) {
        console.log(`✅ Created: ${userData.email} (${userData.role})`);
      } else {
        console.log(`⚠️  ${userData.email}: ${response.data.message || 'Already exists or error'}`);
      }
    } catch (error) {
      console.log(`❌ Error creating ${userData.email}: ${error.message}`);
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
  console.log('⚠️  Note: After signup, you need to update user roles manually in Supabase');
  console.log('   Or use the direct seed script: npm run seed:users\n');
}

seedUsers().then(() => process.exit(0)).catch((error) => {
  console.error('❌ Error:', error);
  process.exit(1);
});

