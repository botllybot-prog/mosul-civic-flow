import { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Save, Loader2 } from 'lucide-react';
import { type RecordRow, value } from './model';
const fields: Record<string, [string,string][]> = {
 sector:[['manager','مسؤول القطاع']],department:[['manager','المسؤول'],['type','النوع (قسم / شعبة)'],['parent','القسم التابع له']],
 employee:[['role','دور الموظف'],['arrival','وقت الحضور'],['departure','وقت الانصراف'],['achievements','الإنجازات'],['status','الحالة']],
 book:[['number','رقم الكتاب'],['source','الجهة المرسلة'],['department','القسم الحالي'],['priority','الأولوية'],['status','الحالة'],['date','تاريخ الكتاب']],
 vehicle:[['plate','رقم اللوحة'],['driver','اسم السائق'],['status','الحالة'],['sector','القطاع']]
};
export function RecordEditor({kind,record,sectors,onSaved,allowedSector}:{kind:string;record:RecordRow | null;sectors:RecordRow[];onSaved:()=>void;allowedSector?:string}) {
 const [error,setError]=useState('');const [busy,setBusy]=useState(false);
 return <form className="space-y-4" onSubmit={async e=>{e.preventDefault();setBusy(true);setError('');const form=new FormData(e.currentTarget);const payload: Record<string,string | number>={};if(record?.payload && typeof record.payload==='object' && !Array.isArray(record.payload))for(const [k,v] of Object.entries(record.payload))if(typeof v==='string'||typeof v==='number')payload[k]=v;
 for(const [key] of fields[kind] ?? [])payload[key]=String(form.get(key) ?? '');const data={kind,name:String(form.get('name')),payload,sector_id:kind==='employee'||kind==='department' ? allowedSector ?? (String(form.get('sector_id'))||null):null};
 const result=record ? await supabase.from('erp_records').update(data).eq('id',record.id) : await supabase.from('erp_records').insert(data).select('id').single();
 if(result.error){setError('لم يُحفظ السجل. تحقق من الصلاحيات والحقول.');setBusy(false);return;}onSaved();setBusy(false);
 }}><label className="field">{kind==='book'?'موضوع الكتاب':'الاسم'}<input name="name" defaultValue={record?.name ?? ''} required/></label>
 {(kind==='department'||kind==='employee') && <label className="field">القطاع<select name="sector_id" defaultValue={allowedSector ?? record?.sector_id ?? sectors[0]?.id} disabled={Boolean(allowedSector)} required>{sectors.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select></label>}
 <div className="grid grid-cols-2 gap-4">{(fields[kind] ?? []).map(([key,label])=><label className={`field ${key==='achievements'?'col-span-2':''}`} key={key}>{label}<input name={key} required={key==='number'||key==='source'} type={key==='date'?'date':key==='arrival'||key==='departure'?'time':'text'} defaultValue={record?value(record,key):key==='date'?new Date().toISOString().slice(0,10):key==='status'?'قيد الإجراء':key==='type'?'قسم':key==='priority'?'عادي':''}/></label>)}</div>
 {error && <p className="text-destructive text-sm" role="alert">{error}</p>}<Button className="w-full" disabled={busy}>{busy?<Loader2 className="animate-spin"/>:<Save/>}حفظ التغييرات</Button></form>;
}
