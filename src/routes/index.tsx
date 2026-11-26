import { createFileRoute } from "@tanstack/react-router";
import { Dashboard } from '@/features/erp/dashboard';
import { DEMO } from '@/features/erp/model';
export const Route = createFileRoute("/")({
  head: () => ({meta:[{title:'بلدية الموصل | نظام الإدارة المتكامل'},{name:'description',content:'لوحة إدارة بلدية الموصل للكتب الرسمية والقطاعات والموظفين والآليات والتوقيع الإلكتروني.'},{property:'og:title',content:'بلدية الموصل | نظام الإدارة المتكامل'},{property:'og:description',content:'متابعة العمل البلدي والكتب الرسمية والقطاعات من لوحة موحدة.'},{property:'og:type',content:'website'},{name:'twitter:card',content:'summary_large_image'}]}),
  component: () => <Dashboard data={DEMO} demo />,
});
