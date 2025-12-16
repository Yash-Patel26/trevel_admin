const { Pool } = require('pg');
require('dotenv').config();
const getSSLConfig = () => {
const sslMode = process.env.DB_SSL_MODE || (process.env.NODE_ENV === 'production' ? 'require' : 'disable');
if (sslMode === 'disable' || sslMode === 'false') {
return false;
}
if (sslMode === 'require') {
return {
rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false'
};
}
if (sslMode === 'verify-ca' || sslMode === 'verify-full') {
return {
rejectUnauthorized: true,
ca: process.env.DB_SSL_CA || undefined,
cert: process.env.DB_SSL_CERT || undefined,
key: process.env.DB_SSL_KEY || undefined
};
}
return false;
};
// Create pool with error handling - don't crash if connection fails initially
let pool;
try {
  pool = new Pool({
host: process.env.DB_HOST || 'localhost',
port: parseInt(process.env.DB_PORT) || 5432,
database: process.env.DB_NAME || 'trevel_app',
user: process.env.DB_USER || 'postgres',
password: process.env.DB_PASSWORD ? String(process.env.DB_PASSWORD) : '',
ssl: getSSLConfig(),
max: parseInt(process.env.DB_POOL_MAX) || 100,
min: parseInt(process.env.DB_POOL_MIN) || 10,
idleTimeoutMillis: parseInt(process.env.DB_POOL_IDLE_TIMEOUT) || 30000,
connectionTimeoutMillis: parseInt(process.env.DB_POOL_CONNECTION_TIMEOUT) || (process.env.NODE_ENV === 'production' ? 2000 : 10000),
allowExitOnIdle: true
});
  
pool.on('error', (err) => {
    });
  
  // Test connection on startup (non-blocking)
  pool.query('SELECT NOW()')
    .then(() => {
      })
    .catch((err) => {
      const dbHost = process.env.DB_HOST || 'localhost';
      const dbName = process.env.DB_NAME || 'trevel_app';
      if (err.code === 'ETIMEDOUT' || err.message.includes('timeout')) {
        } else if (err.code === 'ENOTFOUND') {
        } else if (err.code === 'ECONNREFUSED') {
        }
    });
} catch (error) {
  // Create a dummy pool that will fail gracefully
  pool = {
    query: () => Promise.reject(new Error('Database not configured')),
    connect: () => Promise.reject(new Error('Database not configured')),
    end: () => Promise.resolve()
  };
}
module.exports = {
query: (text, params, client) => {
if (client) {
return client.query(text, params);
}
return pool.query(text, params);
},
getClient: () => pool.connect(),
end: () => pool.end()
};
