import { createServerFn } from '@tanstack/react-start';
import { requireSupabaseAuth } from '@/integrations/supabase/auth-middleware';
export const getERP = createServerFn({method:'GET'}).middleware([requireSupabaseAuth]).handler(async ({context}) => {
 const [records,movements,signatures,locations,roles] = await Promise.all([
 context.supabase.from('erp_records').select('*').order('created_at'),context.supabase.from('book_movements').select('*').order('entered_at'),context.supabase.from('book_signatures').select('*').order('created_at'),context.supabase.from('gps_locations').select('*'),context.supabase.from('user_roles').select('*')]);
 for(const result of [records,movements,signatures,locations,roles]) if(result.error) throw new Error(result.error.message);
 return {records:records.data ?? [],movements:movements.data ?? [],signatures:signatures.data ?? [],locations:locations.data ?? [],roles:roles.data ?? [],userId:context.userId};
});
