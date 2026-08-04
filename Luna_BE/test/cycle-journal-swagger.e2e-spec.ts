import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import {
  DocumentBuilder,
  SwaggerModule,
  type OpenAPIObject,
} from '@nestjs/swagger';
import { BusinessDateClock } from '../src/common/date/business-date';
import { CalendarController } from '../src/modules/calendar/calendar.controller';
import { CalendarService } from '../src/modules/calendar/calendar.service';
import { CycleController } from '../src/modules/cycle/cycle.controller';
import { CycleService } from '../src/modules/cycle/cycle.service';
import { HealthController } from '../src/modules/health/health.controller';
import { DashboardService } from '../src/modules/health/dashboard.service';
import { JournalService } from '../src/modules/health/journal.service';
import { MoodController } from '../src/modules/mood/mood.controller';
import { MoodService } from '../src/modules/mood/mood.service';
import { NoteController } from '../src/modules/note/note.controller';
import { NoteService } from '../src/modules/note/note.service';
import { CareSuggestionService } from '../src/modules/scheduler/care-suggestion.service';
import { SymptomController } from '../src/modules/symptom/symptom.controller';
import { SymptomService } from '../src/modules/symptom/symptom.service';

type HttpMethod = 'get' | 'post' | 'put' | 'delete';

describe('Cycle and journal Swagger contracts', () => {
  let app: INestApplication;
  let document: OpenAPIObject;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [
        CycleController,
        CalendarController,
        HealthController,
        MoodController,
        SymptomController,
        NoteController,
      ],
      providers: [
        { provide: BusinessDateClock, useValue: { today: () => '2026-08-03' } },
        { provide: CycleService, useValue: {} },
        { provide: CalendarService, useValue: {} },
        { provide: DashboardService, useValue: {} },
        { provide: CareSuggestionService, useValue: {} },
        { provide: JournalService, useValue: {} },
        { provide: MoodService, useValue: {} },
        { provide: SymptomService, useValue: {} },
        { provide: NoteService, useValue: {} },
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().setTitle('Luna API').setVersion('1.0').build(),
    );
  });

  afterAll(async () => app.close());

  it.each([
    ['/api/v1/cycles/start', 'post', '201', 'CycleEnvelopeDto'],
    ['/api/v1/cycles/end', 'post', '201', 'CycleEnvelopeDto'],
    ['/api/v1/cycles', 'get', '200', 'CycleListEnvelopeDto'],
    ['/api/v1/cycles/current', 'get', '200', 'NullableCycleEnvelopeDto'],
    ['/api/v1/cycles/prediction', 'get', '200', 'CycleSummaryEnvelopeDto'],
    ['/api/v1/calendar', 'get', '200', 'CalendarEnvelopeDto'],
    ['/api/v1/health/dashboard', 'get', '200', 'DashboardEnvelopeDto'],
    ['/api/v1/health/care/today', 'get', '200', 'CareEnvelopeDto'],
    ['/api/v1/health/journal', 'get', '200', 'JournalEnvelopeDto'],
    ['/api/v1/moods/{date}', 'get', '200', 'MoodEnvelopeDto'],
    ['/api/v1/moods/{date}', 'put', '200', 'MoodEnvelopeDto'],
    ['/api/v1/symptoms/{date}', 'get', '200', 'SymptomEnvelopeDto'],
    ['/api/v1/symptoms/{date}', 'put', '200', 'SymptomEnvelopeDto'],
    ['/api/v1/notes/{date}', 'get', '200', 'NoteEnvelopeDto'],
    ['/api/v1/notes/{date}', 'put', '200', 'NoteEnvelopeDto'],
    ['/api/v1/notes/{date}', 'delete', '200', 'NoteEnvelopeDto'],
  ] as const)(
    '%s %s documents %s with %s',
    (path, method, status, schemaName) => {
      expect(responseSchema(path, method, status)).toEqual({
        $ref: `#/components/schemas/${schemaName}`,
      });
    },
  );

  it('documents nullable current cycle and journal continuation metadata', () => {
    expect(schemaProperty('NullableCycleEnvelopeDto', 'data')).toMatchObject({
      nullable: true,
    });
    expect(schemaProperty('JournalDataDto', 'hasMore')).toMatchObject({
      type: 'boolean',
    });
  });

  function responseSchema(path: string, method: HttpMethod, status: string) {
    const operation = document.paths[path]?.[method];
    if (!operation || '$ref' in operation) {
      throw new Error(`Missing Swagger operation ${method} ${path}.`);
    }
    const response = operation.responses[status];
    if (!response || '$ref' in response) {
      throw new Error(
        `Missing Swagger response ${status} for ${method} ${path}.`,
      );
    }
    return response.content?.['application/json']?.schema;
  }

  function schemaProperty(schemaName: string, property: string) {
    const schema = document.components?.schemas?.[schemaName];
    if (!schema || '$ref' in schema) {
      throw new Error(`Missing concrete Swagger schema ${schemaName}.`);
    }
    return schema.properties?.[property];
  }
});
