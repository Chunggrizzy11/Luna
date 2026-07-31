import { Inject, Injectable } from '@nestjs/common';
import type { Connection } from 'mongoose';
import { MONGO_CONNECTION } from './mongo.providers';

@Injectable()
export class DatabaseService {
  constructor(
    @Inject(MONGO_CONNECTION) private readonly connection: Connection,
  ) {}

  isConnected(): boolean {
    return this.connection.readyState === 1;
  }
}
