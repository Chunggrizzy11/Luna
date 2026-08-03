#!/usr/bin/env node

const mongoose = require('mongoose');

const optionNames = {
  '--mongo-admin-uri': 'mongoAdminUri',
  '--app-password': 'appPassword',
  '--compass-password': 'compassPassword',
};

function readArguments(argumentsList) {
  const values = {};

  for (let index = 0; index < argumentsList.length; index += 1) {
    const argument = argumentsList[index];
    const [option, inlineValue] = argument.split('=', 2);
    const property = optionNames[option];
    if (!property) {
      throw new Error('Unsupported command-line option');
    }

    const value = inlineValue ?? argumentsList[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error('A required command-line value is missing');
    }
    values[property] = value;
    if (inlineValue === undefined) {
      index += 1;
    }
  }

  return values;
}

function requiredValue(value, name) {
  if (typeof value !== 'string' || value.length === 0) {
    throw new Error(`${name} is required`);
  }

  return value;
}

async function upsertUser(adminDatabase, username, password, roles) {
  const existingUsers = await adminDatabase.command({
    usersInfo: { user: username, db: 'admin' },
  });
  const command = existingUsers.users.length > 0 ? 'updateUser' : 'createUser';

  await adminDatabase.command({
    [command]: username,
    pwd: password,
    roles,
  });
}

async function main() {
  const argumentsList = readArguments(process.argv.slice(2));
  const mongoAdminUri = requiredValue(
    argumentsList.mongoAdminUri ?? process.env.MONGO_ADMIN_URI,
    'MONGO_ADMIN_URI',
  );
  const appPassword = requiredValue(
    argumentsList.appPassword ?? process.env.MONGO_APP_PASSWORD,
    'MONGO_APP_PASSWORD',
  );
  const compassPassword = requiredValue(
    argumentsList.compassPassword ?? process.env.MONGO_COMPASS_PASSWORD,
    'MONGO_COMPASS_PASSWORD',
  );
  const connection = await mongoose.createConnection(mongoAdminUri).asPromise();

  try {
    const adminDatabase = connection.getClient().db('admin');
    await upsertUser(adminDatabase, 'luna_app', appPassword, [
      { role: 'readWrite', db: 'luna_uat' },
    ]);
    await upsertUser(adminDatabase, 'luna_compass', compassPassword, [
      { role: 'read', db: 'luna_uat' },
    ]);
    process.stdout.write('UAT MongoDB users configured.\n');
  } finally {
    await connection.close();
  }
}

main().catch(() => {
  process.stderr.write(
    'Unable to configure UAT MongoDB users. Check credentials and connection settings.\n',
  );
  process.exitCode = 1;
});
