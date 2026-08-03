export type CareAudience = 'owner' | 'partner';

export interface CareSuggestionSeed {
  id: string;
  audience: CareAudience;
  title: string;
  description: string;
}

const careActions = [
  {
    id: 'message',
    owner: [
      'Nhắn tin cho người thân',
      'Nhắn một câu hỏi thăm nhẹ nhàng khi bạn cần được lắng nghe.',
    ],
    partner: [
      'Nhắn tin cho người ấy',
      'Hãy nhắn một lời hỏi thăm dịu dàng và sẵn sàng lắng nghe.',
    ],
  },
  {
    id: 'drink',
    owner: [
      'Mua đồ uống ấm',
      'Tự thưởng một ly đồ uống ấm, ít đường và nghỉ ngơi vài phút.',
    ],
    partner: [
      'Mua đồ uống ấm',
      'Mua một ly đồ uống ấm, ít đường cho người ấy nếu họ muốn.',
    ],
  },
  {
    id: 'chocolate',
    owner: [
      'Mua một chút socola',
      'Ăn một miếng socola nhỏ nếu bạn thấy thèm ngọt, thật chậm rãi.',
    ],
    partner: [
      'Mua một chút socola',
      'Mang cho người ấy một chút socola nếu điều đó khiến họ vui hơn.',
    ],
  },
  {
    id: 'movie',
    owner: [
      'Xem một bộ phim nhẹ nhàng',
      'Dành thời gian xem một bộ phim khiến bạn thấy dễ chịu.',
    ],
    partner: [
      'Rủ xem một bộ phim nhẹ nhàng',
      'Chọn một bộ phim thư giãn để xem cùng người ấy.',
    ],
  },
  {
    id: 'walk',
    owner: [
      'Đi dạo thật chậm',
      'Ra ngoài đi dạo vài phút, hít thở sâu nếu cơ thể cho phép.',
    ],
    partner: [
      'Cùng đi dạo thật chậm',
      'Mời người ấy đi dạo nhẹ nhàng nếu họ thấy thoải mái.',
    ],
  },
  {
    id: 'hot-meal',
    owner: [
      'Ăn một món nóng',
      'Chuẩn bị một món nóng, dễ tiêu để chăm sóc cơ thể.',
    ],
    partner: [
      'Chuẩn bị một món nóng',
      'Gợi ý hoặc chuẩn bị một món nóng, dễ tiêu cho người ấy.',
    ],
  },
  {
    id: 'flowers',
    owner: [
      'Tặng mình một bó hoa',
      'Chọn một bông hoa nhỏ để làm không gian hôm nay tươi hơn.',
    ],
    partner: [
      'Tặng người ấy một bó hoa',
      'Tặng một bông hoa nhỏ để người ấy biết bạn đang quan tâm.',
    ],
  },
  {
    id: 'song',
    owner: [
      'Gửi mình một bài hát',
      'Mở một bài hát bạn yêu thích và cho phép mình thư giãn.',
    ],
    partner: [
      'Gửi người ấy một bài hát',
      'Gửi một bài hát dịu dàng để người ấy cảm thấy được vỗ về.',
    ],
  },
] as const;

export const CARE_SUGGESTION_SEEDS: readonly CareSuggestionSeed[] =
  careActions.flatMap(({ id, owner, partner }) => [
    {
      id: `owner-${id}`,
      audience: 'owner' as const,
      title: owner[0],
      description: owner[1],
    },
    {
      id: `partner-${id}`,
      audience: 'partner' as const,
      title: partner[0],
      description: partner[1],
    },
  ]);
