import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { PairingService } from './pairing.service';
import { PairingCode } from './schemas/pairing-code.schema';
import { Device, DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import { ForbiddenException, BadRequestException, NotFoundException } from '@nestjs/common';

describe('PairingService', () => {
  let service: PairingService;
  let pairingCodeModel: any;
  let deviceModel: any;

  const mockOwner = {
    deviceId: 'owner-1',
    role: DeviceRole.OWNER,
    status: DeviceStatus.ACTIVE,
  };

  const mockPartner = {
    deviceId: 'partner-1',
    role: DeviceRole.PARTNER,
    status: DeviceStatus.ACTIVE,
  };

  beforeEach(async () => {
    pairingCodeModel = {
      create: jest.fn(),
      findOne: jest.fn(),
      updateMany: jest.fn(),
      findOneAndUpdate: jest.fn(),
      findByIdAndUpdate: jest.fn(),
    };

    deviceModel = {
      findOne: jest.fn(),
      findById: jest.fn(),
      findByIdAndUpdate: jest.fn(),
      updateMany: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PairingService,
        {
          provide: getModelToken(PairingCode.name),
          useValue: pairingCodeModel,
        },
        {
          provide: getModelToken(Device.name),
          useValue: deviceModel,
        },
      ],
    }).compile();

    service = module.get<PairingService>(PairingService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('generateCode', () => {
    it('should generate a code for owner', async () => {
      pairingCodeModel.create.mockResolvedValue({ code: 'ABCDEFGH', expiresAt: new Date() });

      const result = await service.generateCode(mockOwner as any);

      expect(result.code).toHaveLength(8);
      expect(pairingCodeModel.updateMany).toHaveBeenCalled();
      expect(pairingCodeModel.create).toHaveBeenCalled();
    });

    it('should throw if not owner', async () => {
      await expect(service.generateCode(mockPartner as any)).rejects.toThrow(ForbiddenException);
    });
  });

  describe('join', () => {
    it('should allow partner to join with valid code', async () => {
      const code = 'VALIDCD1';
      const expiresAt = new Date(Date.now() + 10000);
      pairingCodeModel.findOne.mockResolvedValue({
        _id: 'code-id',
        code,
        ownerDeviceId: 'owner-id',
        expiresAt,
        attempts: 0,
        used: false,
      });
      deviceModel.findOne.mockResolvedValue({ _id: 'owner-id', role: DeviceRole.OWNER, status: DeviceStatus.ACTIVE, pairId: 'pair-1' });
      pairingCodeModel.findOneAndUpdate.mockResolvedValue({ attempts: 1 });

      const result = await service.join(mockPartner as any, code);

      expect(result.paired).toBe(true);
      expect(deviceModel.findByIdAndUpdate).toHaveBeenCalled();
      expect(pairingCodeModel.findByIdAndUpdate).toHaveBeenCalledWith('code-id', { used: true });
    });

    it('should throw if code expired', async () => {
      pairingCodeModel.findOne.mockResolvedValue({
        expiresAt: new Date(Date.now() - 10000),
      });
      await expect(service.join(mockPartner as any, 'EXPIRED1')).rejects.toThrow(BadRequestException);
    });
  });
});
