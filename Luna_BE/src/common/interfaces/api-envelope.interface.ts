export interface ApiSuccessEnvelope<T> {
  data: T | null;
  timestamp: string;
}

export interface ApiErrorEnvelope {
  code: string;
  message: string;
  details: unknown;
  timestamp: string;
  path: string;
}
