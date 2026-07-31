import { registerAs } from '@nestjs/config';

export default registerAs('notification', () => ({
  fcmServiceAccountJson: process.env.FCM_SERVICE_ACCOUNT_JSON,
  isFcmConfigured: Boolean(process.env.FCM_SERVICE_ACCOUNT_JSON),
}));
