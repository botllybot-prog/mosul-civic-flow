import { describe, it, expect } from 'vitest';
import { dwellMinutes, DEMO } from '@/features/erp/model';
describe('municipal workflow',()=>{
 it('measures exactly one hour spent in the incoming administrative department',()=>{expect(dwellMinutes('2026-11-26T04:00:00Z','2026-11-26T05:00:00Z')).toBe(60);});
 it('keeps counting the current department until it is forwarded',()=>{expect(dwellMinutes('2026-11-26T07:00:00Z',null,new Date('2026-11-26T09:00:00Z').getTime())).toBe(120);});
 it('contains the three requested sectors',()=>{expect(DEMO.records.filter(r=>r.kind==='sector').map(r=>r.name)).toEqual(['قطاع الزهور','المنطقة القديمة','باب نركال']);});
 it('routes the example book from incoming administration through the director to the sector',()=>{expect(DEMO.movements.map(m=>m.department)).toEqual(['الإدارية • الوارد','المدير','قطاع الزهور']);});
});
