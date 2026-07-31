import { getConnectionToken } from '@nestjs/mongoose';
import type { Connection } from 'mongoose';

export const MONGO_CONNECTION = Symbol('MONGO_CONNECTION');

export const mongoProviders = [
  {
    provide: MONGO_CONNECTION,
    inject: [getConnectionToken()],
    useFactory: (connection: Connection): Connection => connection,
  },
];
