import { createFileRoute } from '@tanstack/react-router';
import { useSuspenseQuery } from '@tanstack/react-query';
import { erpQuery } from '@/features/erp/queries';
import { Dashboard } from '@/features/erp/dashboard';
import { sections } from '@/features/erp/model';
export const Route=createFileRoute('/_authenticated/$section')({
 loader:({context})=>context.queryClient.ensureQueryData(erpQuery),
 head:({params})=>{const name=sections.find(s=>s.id===params.section)?.name ?? 'لوحة العمل';return {meta:[{title:`${name} | بلدية الموصل`},{name:'description',content:`${name} في نظام الإدارة المتكامل لبلدية الموصل`},{property:'og:title',content:`${name} | بلدية الموصل`},{property:'og:description',content:`إدارة ومتابعة ${name} في بلدية الموصل`},{property:'og:type',content:'website'},{name:'twitter:card',content:'summary_large_image'}]};},
 component:Page,
});
function Page(){const {section}=Route.useParams();const {data}=useSuspenseQuery(erpQuery);return <Dashboard data={data} section={sections.some(s=>s.id===section)?section:'overview'}/>;}
