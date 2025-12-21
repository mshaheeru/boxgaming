// Simple HTTP-based user creation using backend API
const http = require('http');

const API_URL = 'http://localhost:3001/api/v1/auth/signup';

const users = [
  { email: 'customer1@test.com', password: 'password123', name: 'John Customer' },
  { email: 'customer2@test.com', password: 'password123', name: 'Sarah Customer' },
  { email: 'owner1@test.com', password: 'password123', name: 'Mike Owner' },
  { email: 'owner2@test.com', password: 'password123', name: 'Lisa Owner' },
  { email: 'admin@test.com', password: 'password123', name: 'Admin User' },
];

function signup(email, password, name) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ email, password, name });
    const url = new URL(API_URL);

    const options = {
      hostname: url.hostname,
      port: url.port || 3001,
      path: url.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Timeout'));
    });
    req.write(data);
    req.end();
  });
}

async function createUsers() {
  console.log('🌱 Creating users via backend API...\n');
  console.log('Make sure your backend server is running on port 3001!\n');

  for (const user of users) {
    try {
      process.stdout.write(`Creating ${user.email}... `);
      const result = await signup(user.email, user.password, user.name);
      
      if (result.status === 201) {
        console.log('✅ Created');
      } else {
        const msg = result.data?.message || 'Error';
        if (msg.includes('already') || msg.includes('exists')) {
          console.log('⚠️  Already exists');
        } else {
          console.log(`❌ ${msg}`);
        }
      }
    } catch (error) {
      if (error.message === 'Timeout' || error.code === 'ECONNREFUSED') {
        console.log('❌ Backend server not running!');
        console.log('   Please start: cd backend && npm run start:dev');
        break;
      } else {
        console.log(`❌ ${error.message}`);
      }
    }
  }

  console.log('\n📋 Next step: Update roles in Supabase Dashboard');
  console.log('   Go to: Table Editor > users table');
  console.log('   Update role column: customer, owner, or admin\n');
  
  console.log('📋 Login Credentials:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  users.forEach(u => {
    console.log(`  ${u.email} / password123`);
  });
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

createUsers().then(() => process.exit(0)).catch(e => {
  console.error('Fatal:', e.message);
  process.exit(1);
});

