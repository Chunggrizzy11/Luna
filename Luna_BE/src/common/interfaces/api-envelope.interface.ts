export interface ApiSuccessEnvelope<T> {
  data: T;
  timestamp: string;
}

export interface ApiErrorEnvelope {
  code: string;
  message: string;
  details: unknown | null;
  timestamp: string;
  path: string;
}
