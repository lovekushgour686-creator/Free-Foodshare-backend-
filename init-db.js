/**
 * Database Initialization Script for MySQL
 * Reads and applies schema.sql to the configured MySQL database.
 * Run with: npm run db:init
 */

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function initDB() {
  console.log('🔄 Initializing FoodShare MySQL Database...');

  // Locate schema.sql in parent directory or current directory
  const possiblePaths = [
    path.join(__dirname, '..', 'schema.sql'),
    path.join(__dirname, 'schema.sql'),
  ];

  const schemaPath = possiblePaths.find((p) => fs.existsSync(p));

  if (!schemaPath) {
    console.error('❌ Could not find schema.sql. Please ensure schema.sql exists in the project root.');
    process.exit(1);
  }

  console.log(`📄 Reading schema from: ${schemaPath}`);
  const sql = fs.readFileSync(schemaPath, 'utf-8');

  // Connect initially without database specified to create database if not exists
  let connection;
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      port: parseInt(process.env.DB_PORT || '3306', 10),
      multipleStatements: true,
    });

    console.log('🚀 Executing schema.sql statements...');
    await connection.query(sql);
    console.log('✅ FoodShare MySQL database schema successfully initialized!');
  } catch (err) {
    console.error('❌ Error executing schema.sql:', err.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

initDB();
