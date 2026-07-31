import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigType } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import databaseConfig from '../config/database.config';
import { DatabaseService } from './database.service';
import { mongoProviders } from './mongo.providers';

@Global()
@Module({
  imports: [
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [databaseConfig.KEY],
      useFactory: (database: ConfigType<typeof databaseConfig>) => ({
        uri: database.uri,
      }),
    }),
  ],
  providers: [...mongoProviders, DatabaseService],
  exports: [DatabaseService, MongooseModule],
})
export class DatabaseModule {}
