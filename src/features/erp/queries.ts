import { queryOptions } from '@tanstack/react-query';
import { getERP } from './erp.functions';
export const erpQuery = queryOptions({queryKey:['municipality-erp'],queryFn:() => getERP(),staleTime:10000});
