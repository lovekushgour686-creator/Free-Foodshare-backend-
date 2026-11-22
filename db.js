const mysql = require('mysql2/promise');
require('dotenv').config();

// Create MySQL connection pool using mysql2/promise
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'foodshare',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  multipleStatements: true,
  dateStrings: true,
});

module.exports = {
  /**
   * Helper method to run parameterized queries
   * Returns [rows, fields]
   * @param {string} sql - SQL query string with ? placeholders
   * @param {Array} params - Array of parameters
   */
  query: (sql, params) => pool.query(sql, params),

  /**
   * Acquire a dedicated connection for transactions
   * @returns {Promise<import('mysql2/promise').PoolConnection>}
   */
  getConnection: () => pool.getConnection(),

  /**
   * Direct pool access
   */
  pool,
};
